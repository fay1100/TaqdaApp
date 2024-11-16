import SwiftUI
import CloudKit
import Combine
import AuthenticationServices
class CloudKitUserBootcampViewModel: ObservableObject {
     var userSession: UserSession
    @Published var permissionStatus: Bool = false
    @Published var isSignedInToiCloud: Bool = false
    @Published var error: String = ""
    @Published var userName: String = ""
    @Published var profileImage: UIImage? = nil
    @Published var isLoggedIn: Bool = true // Managing login state here
    
    let container = CKContainer.default()
    var cancellables = Set<AnyCancellable>()
//
//    init() {
//        getiCloudStatus()
//        requestPermission()
//        getCurrentUserName()
//    }
//
    
    init(userSession: UserSession) {
        self.userSession = userSession
        getiCloudStatus()
        requestPermission()
        
        // تحقق مما إذا كان المستخدم مسجل الدخول قبل استدعاء getCurrentUserName()
        if userSession.userID != nil {
            getCurrentUserName()
            fetchUserProfileImage()
        }
    }

    
    private func getiCloudStatus() {
        CloudKitUtility.getiCloudStatus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                self?.isSignedInToiCloud = success
            }
            .store(in: &cancellables)
    }
    
    func requestPermission() {
        CloudKitUtility.requestApplicationPermission()
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] success in
                self?.permissionStatus = success
            }
            .store(in: &cancellables)
    }
    
    func getCurrentUserName() {
        CloudKitUtility.discoverUserIdentity()
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] returnedName in
                self?.userName = returnedName
                print("name.. \(returnedName)")
            }
            .store(in: &cancellables)
    }
    
    func fetchUserProfileImage() {
               guard let userID = userSession.userID else {
                   print("User ID is not available.")
                   return
               }
               
               // Use the userID from userSession to create a predicate
               let predicate = NSPredicate(format: "user_id == %@", userID)
               let query = CKQuery(recordType: "User", predicate: predicate)
               let queryOperation = CKQueryOperation(query: query)
               
               queryOperation.recordFetchedBlock = { [weak self] record in
                   DispatchQueue.main.async {
                       if let imageAsset = record["profileImage"] as? CKAsset, let fileURL = imageAsset.fileURL {
                           if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                               self?.profileImage = image
                           } else {
                               print("Failed to load image data")
                           }
                       } else {
                           print("No profile image found")
                       }
                   }
               }
               
               queryOperation.queryCompletionBlock = { [weak self] _, error in
                   if let error = error {
                       print("Error fetching profile image: \(error.localizedDescription)")
                       DispatchQueue.main.async {
                           self?.error = error.localizedDescription
                       }
                   }
               }
               
               container.publicCloudDatabase.add(queryOperation)
           }
    
    func logoutUser() {
        print("Logging out...")
        userName = "" // مسح اسم المستخدم
        profileImage = nil
        isLoggedIn = false
        userSession.logout() // مسح بيانات جلسة المستخدم
    }


}

struct AccountView: View {
    @Environment(\.colorScheme) var colorScheme
        @State private var isDarkMode: Bool = false
        @StateObject private var vm: CloudKitUserBootcampViewModel
        @State private var selectedImage: UIImage?
        @State private var isPickerPresented = false
        @EnvironmentObject var userSession: UserSession
        init(userSession: UserSession) {
               _vm = StateObject(wrappedValue: CloudKitUserBootcampViewModel(userSession: userSession))
           }
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoggedIn {
                    ZStack {
                        Color("backgroundApp")
                            .ignoresSafeArea()                            .ignoresSafeArea()

//                        Image("Background")
//                            .resizable()
//                            .ignoresSafeArea()
                        
                        VStack {
                            VStack(spacing: 8) {
                                ZStack{
                                    Circle()
                                        .stroke(Color("CircleColor"), lineWidth: 8)
                                        .frame(width: 120, height: 120)
                                    
                                    if let profileImage = vm.profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .foregroundColor(Color("ColorPer"))
                                    }
                                }
        
                                TextField("Username", text: $vm.userName)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("NameColor"))
                                    .multilineTextAlignment(.center)
                                
//                                Text("@\(vm.userName)")
//                                    .foregroundColor(Color.gray)
//                                    .font(.subheadline)
                            }
                            .padding(.top, 70)
                            
                            Spacer().frame(height: 40)
                            
                            VStack(spacing: 0) {
                                SettingRow(icon: "globe", title: NSLocalizedString("Language", comment: ""), iconColor: Color("PrimaryColor"), textColor: Color("titleColor")) {
                                    openAppSettings()
                                }
                                Divider()
                                
                                SettingRow(icon: colorScheme == .dark ? "sun.max" : "moon",
                                           title: colorScheme == .dark ? NSLocalizedString("Light Mode", comment: "") : NSLocalizedString("Dark Mode", comment: ""),
                                           iconColor: Color("PrimaryColor"), textColor: Color("titleColor")) {
                                    isDarkMode.toggle()
                                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                                }
                                Divider()
                                
                                SettingRow(icon: "rectangle.portrait.and.arrow.right", title: NSLocalizedString("Log out", comment: ""), iconColor: Color("red22"), textColor: Color("red22")) {
                                    vm.logoutUser()
                                    vm.isLoggedIn = false // تعيين isLoggedIn إلى false لنقل المستخدم إلى loggedOutView
                                }

                            }.padding(.top,50)
                            
                            Spacer()
                        }
                    }
                    .onAppear {
                        vm.fetchUserProfileImage()
                    }
                } else {
                    loggedOutView
                }
            }
        }
    }
    
    var loggedOutView: some View {
        ZStack {
            Color("backgroundAppColor")
                .ignoresSafeArea()
            
            Image("Background")
                .resizable()
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color("GreenLight"), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.fill.questionmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(Color("buttonColor"))
                }
                .padding(.top, 40)
                
                Text("You do not have an account yet")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(Color("GreenDark"))
                    .padding(.top, 20)
                
                Text("Create new account now")
                    .foregroundColor(Color("buttonColor"))
                    .fontWeight(.bold)
                    .font(.subheadline)
                    .padding(.top, 20)
                
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            handleAuthorization(authorization)
                        case .failure(let error):
                            print("Sign in with Apple failed: \(error.localizedDescription)")
                        }
                    }
                )
                .frame(width: 342, height: 54)
                .cornerRadius(14)
                .padding(.top, 20)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .accessibilityLabel("Sign in with Apple")
                .accessibilityHint("Use your Apple ID to sign in")
            }
            .padding(.bottom,250)
        }
    }
    
    func handleAuthorization(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("User ID: \(userIdentifier)")
            if let name = fullName {
                print("User Name: \(name.givenName ?? "") \(name.familyName ?? "")")
            }
            if let email = email {
                print("User Email: \(email)")
            }
            
            vm.isLoggedIn = true
        }
    }

    func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
    }
}

struct SettingRow: View {
    var icon: String
    var title: String
    var iconColor: Color = .black
    var textColor: Color = .black
    var action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            Text(title)
                .foregroundColor(textColor)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .onTapGesture {
            action()
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(userSession: UserSession.shared) // Use the singleton instance
            .environmentObject(UserSession.shared) // Inject UserSession into the environment
    }
}

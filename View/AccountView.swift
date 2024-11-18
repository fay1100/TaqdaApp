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
    @Published var isLoggedIn: Bool = false // إدارة حالة تسجيل الدخول
    
    let container = CKContainer(identifier: "iCloud.FaizahApp")
    var cancellables = Set<AnyCancellable>()
    
    init(userSession: UserSession) {
        self.userSession = userSession
        getiCloudStatus()
        requestPermission()
        
        if let userID = userSession.userID {
            isLoggedIn = true // ضبط الحالة بناءً على الجلسة
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
            }
            .store(in: &cancellables)
    }
    
    func fetchUserProfileImage() {
        guard let userID = userSession.userID else {
            return
        }
        
        let predicate = NSPredicate(format: "user_id == %@", userID)
        let query = CKQuery(recordType: "User", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { [weak self] record in
            DispatchQueue.main.async {
                if let imageAsset = record["profileImage"] as? CKAsset, let fileURL = imageAsset.fileURL {
                    if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                        self?.profileImage = image
                    }
                }
            }
        }
        
        queryOperation.queryCompletionBlock = { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                }
            }
        }
        
        container.publicCloudDatabase.add(queryOperation)
    }
    
    func logoutUser() {
        userName = ""
        profileImage = nil
        isLoggedIn = false
        userSession.logout()
    }
}

struct AccountView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarkMode: Bool = false
    @State private var showSignInView: Bool = false // حالة للتحكم في عرض واجهة تسجيل الدخول
    @StateObject private var vm: CloudKitUserBootcampViewModel
    @EnvironmentObject var userSession: UserSession

    init(userSession: UserSession) {
        _vm = StateObject(wrappedValue: CloudKitUserBootcampViewModel(userSession: userSession))
    }

    var body: some View {
        NavigationStack {
            accountDetailsView
        }
        .onAppear {
            if vm.isLoggedIn {
                vm.fetchUserProfileImage()
            }
        }
        .fullScreenCover(isPresented: $showSignInView) {
            SignInView(userSession: userSession)
                .environmentObject(userSession)
        }
    }

    var accountDetailsView: some View {
        ZStack {
            Color("backgroundApp")
                .ignoresSafeArea()
            
            VStack {
                profileSection
                settingsSection
                Spacer()
            }
        }
    }

    var profileSection: some View {
        VStack(spacing: 8) {
            ZStack {
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
        }
        .padding(.top, 70)
    }

    var settingsSection: some View {
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

            SettingRow(
                icon: vm.isLoggedIn ? "rectangle.portrait.and.arrow.right" : "person",
                  title: vm.isLoggedIn ? NSLocalizedString("Log Out", comment: "Log out button text") : NSLocalizedString("Sign In", comment: "Sign in button text"),
                iconColor: vm.isLoggedIn ? Color.red22: Color.PrimaryColor , // لون الأيقونة
                 textColor: vm.isLoggedIn ? Color.red22 : Color.titleColor // لون النص
            ) {
                if vm.isLoggedIn {
                    vm.logoutUser()
                    print("User logged out")
                } else {
                    showSignInView.toggle() 
                }
            }
        }
        .padding(.top, 50)
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


extension Color {
    static let titleColor = Color("titleColor") // يجب أن تكون مضافة في Assets
    static let PrimaryColor = Color("PrimaryColor") // يجب أن تكون مضافة في Assets
}


struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(userSession: UserSession.shared)
            .environmentObject(UserSession.shared)
    }
}

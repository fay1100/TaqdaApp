import SwiftUI

struct FavouriteView: View {
    @State private var isBellTapped = false
    @StateObject private var vm: CloudKitUserBootcampViewModel
    @EnvironmentObject var userSession: UserSession
    @State private var showNotificationView = false // حالة التنقل

    init(userSession: UserSession) {
        _vm = StateObject(wrappedValue: CloudKitUserBootcampViewModel(userSession: userSession))
    }
    
    var body: some View {
        NavigationStack {

        ZStack {
            Color("backgroundApp")
                .ignoresSafeArea()
            VStack {
                
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color("buttonColor"), lineWidth: 2)
                            .frame(width: 50, height: 50)
                        
                     
                        if let profileImage = vm.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color("CircleColor")) // جعل الدائرة ممتلئة بلون
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                        }
                    }
                    .padding(.leading)
                    
                    VStack(alignment: .leading) {
                        Text("Welcome")
                            .font(.subheadline)
                            .foregroundColor(Color("Wcolor"))

                        Text("\(vm.userName)")
                            .font(.title2)
                            .foregroundColor(Color("PrimaryColor"))
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    NavigationLink(destination: NotificationView(), isActive: $showNotificationView) {
                        ZStack {
                            Circle()
                                .fill(isBellTapped ? Color("CircleColor") : Color("CircleColor"))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "bell")
                                .resizable()
                                .frame(width: 18, height: 22)
                                .foregroundColor(isBellTapped ? .white : Color("PrimaryColor"))
                        }
                    }
                    .onTapGesture {
                        showNotificationView = true // تفعيل التنقل
                    
                    }
                    .padding(.trailing)
                }
                .padding(.top)
                
                Spacer()
            }
            
        }
        
    }
}
}

struct FavouriteView_Previews: PreviewProvider {
    static var previews: some View {
        FavouriteView(userSession: UserSession.shared)
            .environmentObject(UserSession.shared) 
    }
}

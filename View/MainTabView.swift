import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var viewModel = CreateListViewModel(userSession: UserSession.shared)

    //@EnvironmentObject var userSession: UserSession
    var body: some View {
        NavigationStack {
            ZStack {
                if selectedTab == 0 {
                    ListsView()
                        .environmentObject(UserSession.shared)
                } else if selectedTab == 1 {
           FavouriteView()
                        .environmentObject(UserSession.shared)
                } else {
                    AccountView(userSession: UserSession.shared)
                        .environmentObject(UserSession.shared) 
                
                }
                
                VStack {
                    Spacer()
                    HStack(spacing: 108) {
                        
                        Button(action: {
                            selectedTab = 0
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedTab == 0 ? Color("PrimaryColor") : Color("tabBar"))
                                Text("Lists")
                                    .font(.system(size: 11))
                                    .foregroundColor(selectedTab == 0 ? Color("PrimaryColor") : Color("tabBar"))
                            }
                        }
                        .accessibilityLabel("Lists Tab")
                        .accessibilityHint("Double tap to view your lists")
                        .accessibilityAddTraits(selectedTab == 0 ? .isSelected : [])
                        
                        Button(action: {
                            selectedTab = 1
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: selectedTab == 1 ? "suit.heart.fill" : "suit.heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedTab == 1 ? Color("PrimaryColor") : Color("tabBar"))
                                Text("Favourite")
                                    .font(.system(size: 11))
                                    .foregroundColor(selectedTab == 1 ? Color("PrimaryColor") : Color("tabBar"))
                            }
                        }
                        .accessibilityLabel("Favourite Tab")
                        .accessibilityHint("Double tap to view your favourite items")
                        .accessibilityAddTraits(selectedTab == 1 ? .isSelected : [])
                        
                        Button(action: {
                            selectedTab = 2
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedTab == 2 ? Color("PrimaryColor") : Color("tabBar"))
                                Text("Account")
                                    .font(.system(size: 11))
                                    .foregroundColor(selectedTab == 2 ? Color("PrimaryColor") : Color("tabBar"))
                            }
                        }
                        .accessibilityLabel("Account Tab")
                        .accessibilityHint("Double tap to view your account details")
                        .accessibilityAddTraits(selectedTab == 2 ? .isSelected : [])
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color("bakgroundtap")
                                    .cornerRadius(20, corners: [.topLeft, .topRight]))
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarBackButtonHidden(true) 
            
        }
    }
}

#Preview {
    MainTabView()
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// شكل مخصص لتحديد الزوايا الدائرية
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

import SwiftUI

struct FavouriteView: View {
    @StateObject private var vm: CloudKitUserBootcampViewModel
    @StateObject private var viewModel: CreateListViewModel
    @EnvironmentObject var userSession: UserSession
    @State private var showNotificationView = false // حالة التنقل
    @State private var favoriteLists: [List] = [] // القوائم المفضلة
    @State private var selectedList: List? // القائمة المحددة للتنقل
    @State private var isNavigatingToList = false // التحكم في التنقل إلى التفاصيل

    init(userSession: UserSession) {
        _vm = StateObject(wrappedValue: CloudKitUserBootcampViewModel(userSession: userSession))
        _viewModel = StateObject(wrappedValue: CreateListViewModel(userSession: userSession))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundApp")
                    .ignoresSafeArea()
                
                VStack {
                    headerView
                    
                    Spacer()
                    if favoriteLists.isEmpty {
                        emptyStateView
                    } else {
                        listView
                    }
                }
            }
        }
        .onAppear {
            fetchFavoriteLists()
        }
    }
    
    var headerView: some View {
        HStack {
            profileImageView
            userGreetingView
            Spacer()
            bellButton
        }
        .padding()
        .background(Color("headerBackground"))
    }
    
    var emptyStateView: some View {
        VStack {
            Spacer()
            Text("No Favorite Grocery.")
                .foregroundColor(Color("titleColor"))
                .fontWeight(.medium)
                .padding()
            Spacer()
        }
    }
    
    var listView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                ForEach(favoriteLists, id: \.listId) { list in
                    ZStack {
                        GroceryListView(
                            listName: list.listName,
                            isHeartSelected: .constant(list.isFavorite),
                            onHeartTapped: {
                                let newFavoriteStatus = false
                                updateFavoriteStatus(for: list, isFavorite: newFavoriteStatus) { success in
                                    if success {
                                        if let index = favoriteLists.firstIndex(where: { $0.listId == list.listId }) {
                                            favoriteLists.remove(at: index)
                                        }
                                    }
                                }
                            }
                        )
                        .onTapGesture {
                            navigateToList(list)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 30)
        }
        .background(
            NavigationLink(
                destination: ListView(
                    categories: viewModel.categorizedProducts,
                    listID: selectedList?.recordID,
                    listName: selectedList?.listName,
                    userSession: userSession
                ),
                isActive: $isNavigatingToList
            ) { EmptyView() }
        )
    }
    
    var profileImageView: some View {
        ZStack {
            Circle()
                .fill(Color("CircleColor"))
                .frame(width: 50, height: 50)
            
            if let profileImage = vm.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color("PrimaryColor"))
            }
        }
    }
    
    var userGreetingView: some View {
        VStack(alignment: .leading) {
            Text("Welcome")
                .font(.subheadline)
                .foregroundColor(Color("Wcolor"))
            Text("\(vm.userName)")
                .font(.title2)
                .foregroundColor(Color("PrimaryColor"))
                .fontWeight(.bold)
        }
    }
    
    var bellButton: some View {
        NavigationLink(destination: NotificationView(), isActive: $showNotificationView) {
            ZStack {
                Circle()
                    .fill(Color("CircleColor"))
                    .frame(width: 40, height: 40)

                Image(systemName: "bell")
                    .resizable()
                    .frame(width: 18, height: 22)
                    .foregroundColor(Color("PrimaryColor"))
            }
        }
        .onTapGesture {
            showNotificationView = true
        }
        .padding(.trailing)
    }

    private func fetchFavoriteLists() {
        viewModel.fetchLists { success in
            if success {
                DispatchQueue.main.async {
                    favoriteLists = viewModel.lists.filter { $0.isFavorite }
                }
            } else {
                print("Failed to fetch favorite lists.")
            }
        }
    }

    
    private func navigateToList(_ list: List) {
        selectedList = list
        isNavigatingToList = true
    }
}

struct FavouriteView_Previews: PreviewProvider {
    static var previews: some View {
        FavouriteView(userSession: UserSession.shared)
            .environmentObject(UserSession.shared) 
    }
}

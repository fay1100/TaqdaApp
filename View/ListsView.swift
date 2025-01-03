import SwiftUI
import Combine
import CloudKit

struct ListsView: View {
    @StateObject private var vm: CloudKitUserBootcampViewModel
    @StateObject private var viewModel: CreateListViewModel
    @State private var searchText = ""
    @State private var isBellTapped = false
    @State private var selectedList: List?
    @State private var isNavigatingToList = false
    @State private var showNotificationView = false
    @State private var isHeartSelected: [Bool] = []
    @State private var showSignInView = false // حالة التحكم بعرض SignInView
    @ObservedObject private var listViewModel: ListViewModel

    @Environment(\.layoutDirection) var layoutDirection
    @EnvironmentObject var userSession: UserSession

    init(
        categories: [GroceryCategory] = [],
        listID: CKRecord.ID? = nil,
        listName: String? = nil
    ) {
        let userSession = UserSession.shared
        _vm = StateObject(wrappedValue: CloudKitUserBootcampViewModel(userSession: userSession))
        _viewModel = StateObject(wrappedValue: CreateListViewModel(userSession: userSession))
        
        // Initialize listViewModel
        self.listViewModel = ListViewModel(
            categories: categories,
            listID: listID,
            listName: listName ?? "Unnamed List",
            createListViewModel: CreateListViewModel(userSession: userSession)
        )
    }

    
    var body: some View {
        NavigationStack {
            
            ZStack {
                Color("backgroundApp")
                               .ignoresSafeArea()
                               .onTapGesture {
                                   // إخفاء لوحة المفاتيح
                                   UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                               }

                VStack {
                    headerView
                    searchView
//                    addButtonView
                    Spacer()
                    if viewModel.lists.isEmpty {
                        emptyStateView
                    } else {
                        listView
                    }
                    Spacer()
                }
                .safeAreaInset(edge: .bottom) {
                    Spacer().frame(height: -90)
                }
            }
        }
        .onAppear {
            viewModel.fetchLists { success in
                if success {
                    print("Lists fetched successfully. Total lists: \(viewModel.lists.count)")
                    isHeartSelected = Array(repeating: false, count: viewModel.lists.count)
                } else {
                    print("Failed to fetch lists.")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    var headerView: some View {
        HStack {
            profileImageView
            userGreetingView
            Spacer()
            bellButton
        }
        .padding(.top)
    }
    
    var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("PrimaryColor"))
                .padding(.leading, 8)
            TextField("Search lists", text: $searchText)
                        .onSubmit {
                              UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                          }
                        .padding(.vertical, 12)
        }
        .background(Color("CircleColor"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.20), lineWidth: 0.1)
        )
        
        .padding(.horizontal)
        .padding(.vertical)
    }
    

    var emptyStateView: some View {
        VStack {
            Text("Start creating your groceries.")
                .foregroundColor(Color("titleColor"))
                .fontWeight(.medium)

            HStack {
                if userSession.checkIfUserIsSignedIn() {
                    NavigationLink(destination: ListView(
                        categories: viewModel.categorizedProducts,
                        listID: selectedList?.recordID,
                        listName: selectedList?.listName,
                        userSession: userSession
                    )) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("PrimaryColor"))
                                .frame(width: 207, height: 40)

                            Text("+ Tap to start")
                                .frame(width: 207, height: 40)
                                .foregroundColor(Color.white)
                        }
                    }
                } else {
                    Button(action: {
                        showSignInView.toggle() // عرض واجهة تسجيل الدخول
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("PrimaryColor"))
                                .frame(width: 207, height: 40)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)

                            Text("+ Tap to start")
                                .frame(width: 207, height: 40)
                                .foregroundColor(Color.white)
                        }
                    }
                    .fullScreenCover(isPresented: $showSignInView) {
                        SignInView(userSession: userSession)
                            .environmentObject(userSession)
                    }
                }
            }
        }
    }


    var listView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                
                // زر إضافة قائمة جديدة
                NavigationLink(destination: ListView(
                    categories: viewModel.categorizedProducts,
                    listID: selectedList?.recordID,
                    listName: selectedList?.listName,
                    userSession: userSession)) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("Color+"))
                            .frame(width: 150, height: 190)
                            .cornerRadius(20)
                        
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color.white)
                    }
                }
                .padding(.vertical)
                
                // عرض القوائم
                ForEach(filteredLists, id: \.listId) { list in
                                    ZStack {
                                        GroceryListView(
                                            listName: list.listName,
                                            isHeartSelected: bindingForHeartSelected(
                                                at: viewModel.lists.firstIndex(where: { $0.listId == list.listId }) ?? 0
                                            ),
                                            isShared: list.isShared, // Pass the `isShared` value from the list
                                            onHeartTapped: {
                                                toggleFavoriteStatus(for: list)
                                            }
                                        )

                                          
                                        .padding()
                                        .background(Color("bakgroundTap"))
                                        .cornerRadius(8)
                                    }
                                    .onTapGesture {
                                        navigateToList(list)
                                    }
                                }
            }
            .padding(.horizontal)
        }
        .background(
            NavigationLink(// for fetch
                destination: DisplayListView(
                    categories: listViewModel.categories,
                    listID: selectedList?.recordID,
                    listName: selectedList?.listName,
                    userSession: userSession
                ),
                isActive: $isNavigatingToList
            ) { EmptyView() }


        )
    }

    private func toggleFavoriteStatus(for list: List) {
        let newFavoriteStatus = !list.isFavorite
        updateFavoriteStatus(for: list, isFavorite: newFavoriteStatus) { success in
            DispatchQueue.main.async {
                if success {
                    if let index = viewModel.lists.firstIndex(where: { $0.listId == list.listId }) {
                        viewModel.lists[index].isFavorite = newFavoriteStatus
                        isHeartSelected[index] = newFavoriteStatus
                        
                        if newFavoriteStatus == false {
                            viewModel.fetchLists { _ in
                                print("Updated favorite lists.")
                            }
                        }
                    }
                } else {
                    print("Failed to update favorite status.")
                }
            }
        }
    }

    private func bindingForHeartSelected(at index: Int) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                guard index < isHeartSelected.count else { return false }
                return isHeartSelected[index]
            },
            set: { newValue in
                if index < isHeartSelected.count {
                    isHeartSelected[index] = newValue
                }
            }
        )
    }


    private func navigateToList(_ list: List) {
        selectedList = list

        guard let recordID = list.recordID else {
            print("Record ID is nil for the selected list.")
            return
        }

        listViewModel.fetchItems(for: recordID) { success in
            if success {
                print("Items fetched for list: \(list.listName)")
                DispatchQueue.main.async {
                    isNavigatingToList = true
                }
            } else {
                print("Failed to fetch items for list: \(list.listName)")
            }
        }
    }


    private var filteredLists: [List] {
        if searchText.isEmpty {
            return viewModel.lists
        } else {
            return viewModel.lists.filter { $0.listName.localizedCaseInsensitiveContains(searchText) }
        }
    }


    

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
                return
            }
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    var profileImageView: some View {
        ZStack {
            Circle()
                .fill(Color("CircleColor")) // جعل الدائرة ممتلئة بلون
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
                        .fill(Color("CircleColor")) 
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color("ColorPer"))
                }
            }
        }
        .padding(.leading)

    }
    
    var userGreetingView: some View {
        VStack(alignment: .leading) {
            Text("Welcome")
                .font(.subheadline)
                .foregroundColor(Color("Wcolor"))
            Text("\(vm.userName)")
                .font(.title2)
                .foregroundColor(Color("NameColor"))
                .fontWeight(.bold)
        }
    }
    
    var bellButton: some View {
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
            showNotificationView = true
        }
        .padding(.trailing)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
        ListsView() // 
            .environmentObject(UserSession.shared)
            .previewDisplayName("ListsView Preview")
    }
}

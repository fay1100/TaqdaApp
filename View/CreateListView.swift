import SwiftUI
import Combine
import CloudKit

struct CreateListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.layoutDirection) var layoutDirection
    @StateObject private var viewModel: CreateListViewModel
    @EnvironmentObject var userSession: UserSession

    init(userSession: UserSession) {
        _viewModel = StateObject(wrappedValue: CreateListViewModel(userSession: userSession))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundAppColor")
                    .ignoresSafeArea()
                Image("Background")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.isBellTapped ? Color("MainColor") : Color("GreenLight"))
                                    .frame(width: 40, height: 40)
                                Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                                    .resizable()
                                    .frame(width: 7, height: 12)
                                    .foregroundColor(viewModel.isBellTapped ? .white : Color("MainColor"))
                            }
                        }

                        Spacer()

                        TextField("Enter list name", text: $viewModel.listName)
                            .font(.system(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Spacer()

                        NavigationLink(
                            destination: ListView(
                                categories: viewModel.categorizedProducts,
                                listID: viewModel.currentListID,
                                listName: viewModel.listName,
                                createListViewModel: viewModel
                            ),
                            isActive: $viewModel.showResults
                        ) {
                            Button(action: {
                                viewModel.saveListToCloudKit(userSession: viewModel.userSession, listName: viewModel.listName) { listID in
                                    guard let listID = listID else { return }
                                    let listReference = CKRecord.Reference(recordID: listID, action: .deleteSelf)
                                    viewModel.classifyProducts()

                                    for category in viewModel.categorizedProducts {
                                        for item in category.items {
                                            viewModel.saveItem(
                                                name: item.name,
                                                quantity: Int64(item.quantity),
                                                listId: listReference,
                                                category: category.name
                                            ) { success in
                                                if success {
                                                    print("Item '\(item.name)' saved successfully in CreateListViewModel.")
                                                } else {
                                                    print("Failed to save item '\(item.name)'.")
                                                }
                                            }
                                        }
                                    }
                                    viewModel.showResults = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.isBellTapped ? Color("MainColor") : Color("GreenLight"))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .frame(width: 17, height: 18)
                                        .foregroundColor(viewModel.isBellTapped ? .white : Color("MainColor"))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)

                    HStack {
                        Text("Items 🛒")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("GreenC"))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    ScrollView {
                        CustomTextField(text: $viewModel.userInput, placeholder: NSLocalizedString("write_down_your_list", comment: "Prompt for the user to write their list"))
                            .frame(width: 350, height: 650)
                            .cornerRadius(11.5)
                    }
                    .ignoresSafeArea(.keyboard)
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct CreateListView_Previews: PreviewProvider {
    static var previews: some View {
        CreateListView(userSession: UserSession.shared)
            .environmentObject(UserSession.shared)
    }
}

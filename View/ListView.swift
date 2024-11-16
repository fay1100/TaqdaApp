import SwiftUI
import CloudKit

struct ListView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @State private var navigateToMainTab = false
    @ObservedObject private var viewModel: ListViewModel
    @State private var showShareSheet = false
    @State private var showAlert = false
    @ObservedObject var createListViewModel: CreateListViewModel
    var listName: String

    @State private var newItem: String = "" // لإدخال النص
    @State private var textFieldHeight: CGFloat = 40 // ارتفاع الحقل

    @EnvironmentObject var userSession: UserSession

    init(categories: [GroceryCategory], listID: CKRecord.ID?, listName: String?, createListViewModel: CreateListViewModel) {
        self.viewModel = ListViewModel(categories: categories, listID: listID, listName: listName, createListViewModel: createListViewModel)
        self.listName = listName ?? "Unnamed List"
        self.createListViewModel = createListViewModel
    }

    var body: some View {
        ZStack {
            Color("backgroundAppColor").ignoresSafeArea()
            Image("Background").resizable().ignoresSafeArea()

            VStack {
                // Header Section
                HStack {
                    Button(action: {
                        if viewModel.isListComplete {
                            navigateToMainTab = true
                        } else {
                            showAlert = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color("CircleColor"))
                                .frame(width: 40, height: 40)
                            Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                                .resizable()
                                .frame(width: 7, height: 12)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                    Spacer()
                    Text(listName)
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                    Spacer()
                    Menu {
                        Button(action: {
                            viewModel.saveToFavorites()
                        }) {
                            Label("Favorite", systemImage: "heart")
                        }
                        Button(action: {
                            viewModel.deleteListAndMoveToMain()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color("CircleColor"))
                                .frame(width: 40, height: 40)
                            Image(systemName: "ellipsis")
                                .resizable()
                                .frame(width: 20, height: 4)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                HStack {
                    Text("Items 🛒")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("NameColor"))
                        .padding(.leading)
                    Spacer()
                }
                .padding(.top, 15)

                ScrollView {
                    ForEach(viewModel.categories.indices, id: \.self) { categoryIndex in
                        let category = viewModel.categories[categoryIndex]

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                HStack {
                                    Button(action: {
                                        viewModel.toggleCategorySelection(for: categoryIndex)
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(category.items.allSatisfy { $0.isSelected } ? Color("PrimaryColor") : Color.clear)
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Circle().stroke(Color("PrimaryColor"), lineWidth: 2)
                                                        
                                                )
                                            if category.items.allSatisfy({ $0.isSelected }) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                            }
                                        }.padding(.leading)
                                    }

                                    Text(viewModel.formattedCategoryName(category.name))
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(Color("NameColor"))
                                }
                                Spacer()
                            }
                            .padding(layoutDirection == .leftToRight ? .leading : .trailing)

                            VStack(spacing: 0) {
                                ForEach(category.items.indices, id: \.self) { itemIndex in
                                    let item = category.items[itemIndex]

                                    HStack {
                                        Text(item.name)
                                            .font(.system(size: 18))
                                            .fontWeight(.medium)
                                            .strikethrough(item.isSelected, color: Color("Textlist"))
                                            .foregroundColor(Color("Textlist"))

                                        Spacer()

                                        HStack(spacing: 10) {
                                            Button(action: {
                                                viewModel.decreaseQuantity(for: categoryIndex, itemIndex: itemIndex)
                                            }) {
                                                Image(systemName: "minus")
                                                    .foregroundColor(Color("gray1"))
                                                    .font(.system(size: 20))
                                            }

                                            Text("\(category.items[itemIndex].quantity)")
                                                .font(.title3)
                                                .frame(width: 18)

                                            Button(action: {
                                                viewModel.increaseQuantity(for: categoryIndex, itemIndex: itemIndex)
                                            }) {
                                                Image(systemName: "plus")
                                                    .foregroundColor(Color("NameColor"))
                                                    .font(.system(size: 20))
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color("bakgroundTap"))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 75)
                                    .padding(.horizontal)

                                    if itemIndex != category.items.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .background(Color("bakgroundtap"))
                            .cornerRadius(11)
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                }

                Spacer()

                VStack {
                    HStack(alignment: .center, spacing: 10) {
                        ExpandingTextField(text: $newItem, dynamicHeight: $textFieldHeight, placeholder: "Enter Your Grocery ")
                            .frame(height: textFieldHeight)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white) 
                            .cornerRadius(27)
                            .overlay(
                            RoundedRectangle(cornerRadius: 27) // حدود مستديرة
                                .stroke(Color.gray, lineWidth: 0.1) // لون الحدود وعرضها
                                   )
                        Button(action: {
                            // الزر بدون أي وظيفة حالياً
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 45, height: 45)

                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("PrimaryColor"))
                                    .font(.system(size: 20))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color("bakgroundtap"))
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .padding(.horizontal)
                }

            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock data for testing
        let groceryItems: [GroceryCategory] = [
            GroceryCategory(name: "Bakery", items: [
                GroceryItem(name: "Bread", quantity: 2),
                GroceryItem(name: "Croissant", quantity: 5)
            ]),
            GroceryCategory(name: "Fruits & Vegetables", items: [
                GroceryItem(name: "Apple", quantity: 4),
                GroceryItem(name: "Banana", quantity: 3)
            ])
        ]
        
        let mockListID = CKRecord.ID(recordName: "mockRecordID")
        let mockListName = "Sample List"
        
        let createListViewModel = CreateListViewModel(userSession: UserSession.shared)
        
        ListView(categories: groceryItems, listID: mockListID, listName: mockListName, createListViewModel: createListViewModel)
            .environmentObject(UserSession.shared)
            .environment(\.layoutDirection, .rightToLeft)
            .previewLayout(.sizeThatFits)
    }
}

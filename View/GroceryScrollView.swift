import SwiftUI
import CloudKit

struct GroceryScrollView: View {
    @ObservedObject var viewModel: ListViewModel
    @Environment(\.layoutDirection) var layoutDirection
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.categories.indices, id: \.self) { categoryIndex in
                let category = viewModel.categories[categoryIndex]
                
                VStack(alignment: .leading, spacing: 16) {
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteItem(at: categoryIndex, itemIndex: itemIndex) { success in
                                        if success {
                                            print("Item successfully deleted.")
                                        } else {
                                            print("Failed to delete item.")
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
.enableScrollViewSwipeActions()
                            
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
    }
}

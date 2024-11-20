import SwiftUI

struct GroceryListView: View {
    var listName: String
    @Binding var isHeartSelected: Bool
    var isShared: Bool // خاصية تحدد إذا كانت القائمة مشتركة
    var onHeartTapped: () -> Void // وظيفة ممررة لتحديث الحالة

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(listName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                
                HStack {
                    Button(action: {
                        onHeartTapped()
                    }) {
                        ZStack {
                            if isHeartSelected {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 17))
                                
                            } else {
                                Image(systemName: "heart.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 30))
                            }
                        }
                        .padding(.trailing, 20)
                    }
                    
                    Image(systemName: isShared ? "person.2.circle" : "person.circle.fill") // تغيير الأيقونة بناءً على حالة المشاركة
                        .foregroundColor(isShared ? Color("ShareColor") :  Color.white) // تغيير اللون بناءً على حالة المشاركة
                        .font(.system(size: 30))
                        .padding(.leading, -20)
                }
            }
            .frame(width: 160, height: 190)
            .background(Color("PrimaryColor"))
            .cornerRadius(20)
        }
    }
}

#Preview {
    @State var isHeartSelectedPreview = false

    return VStack {
        GroceryListView(
            listName: "Shared List",
            isHeartSelected: $isHeartSelectedPreview,
            isShared: true, // قائمة مشتركة
            onHeartTapped: {
                isHeartSelectedPreview.toggle()
                print("Tapped on Shared List. New state: \(isHeartSelectedPreview)")
            }
        )
        
        GroceryListView(
            listName: "Personal List",
            isHeartSelected: $isHeartSelectedPreview,
            isShared: false, // قائمة غير مشتركة
            onHeartTapped: {
                isHeartSelectedPreview.toggle()
                print("Tapped on Personal List. New state: \(isHeartSelectedPreview)")
            }
        )
    }
}

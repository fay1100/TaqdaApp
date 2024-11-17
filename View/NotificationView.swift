import SwiftUI

struct NotificationView: View {
    @State private var isBellTapped = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundAppColor")
                    .ignoresSafeArea()

                VStack {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
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

                        Text("Notification")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color("GreenDark"))

                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)

                    Spacer()

                    Rectangle()
                        .fill(Color("bakgroundtap"))
                        .cornerRadius(11, corners: [.topLeft, .topRight])
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(Color("strokeColor"), lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(
                            ScrollView {
                                VStack(spacing: 15) {
                                    let notifications = [
                                        "Remember to buy the weekly grocery!",
                                        "Don't forget to pick up fresh fruits!",
                                        "Special discount on bakery items this weekend!"
                                    ]

                                    // Display Notifications
                                    ForEach(notifications.indices, id: \.self) { index in
                                        HStack(spacing: 12) {
                                            Image(systemName: "bell.badge.circle")
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                                .foregroundColor(Color("PrimaryColor"))

                                            Text(notifications[index])
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color("titleColor"))
                                                .multilineTextAlignment(.leading)

                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)

                                        if index < notifications.count - 1 {
                                            Divider()
                                                .background(Color("strokeColor"))
                                        }
                                    }
                                }
                                .padding()
                            }
                        )
                }
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NotificationView()
}

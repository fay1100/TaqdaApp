//
//  OnboardingView.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0 // الصفحة الحالية من الأونبوردنق
    @Binding var isOnboardingComplete: Bool // يربط هذه الحالة بمتغير في TurboListApp
    @Environment(\.colorScheme) var colorScheme
    
    let onboardingData = [
        OnboardingData(gifName: "On11", darkGifName: "on2_dark", title: NSLocalizedString("Sort", comment: ""), description: NSLocalizedString("Organize your grocery items using AI-powered categorization sorting them by category.", comment: "")),
        OnboardingData(gifName: "On22", darkGifName: "On11", title: NSLocalizedString("Collaborative", comment: ""), description: NSLocalizedString("Multiple users to collaborate with instant updates to shared grocery lists.", comment: ""))
    ]
    
    var body: some View {
        ZStack {
            if isOnboardingComplete {
                // هنا يمكن إضافة الكود في حال اكتمال الأونبوردنق
            } else {
//                Color("backgroundAppColor")
//                    .ignoresSafeArea()
//
//                Image("Background")
//                    .resizable()
//                    .ignoresSafeArea()
//                
//                Image("Back1")
//                    .ignoresSafeArea()
//                    .offset(y: -140)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            print(" ")
                        }) {
                            Text("")
                                .foregroundColor(Color("buttonColor"))
                                .padding()
                        }
                    }
                    Spacer()

                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingData.count) { index in
                            VStack(spacing: 5) {
                                // تحديد الـGIF بناءً على الصفحة الحالية و الوضع الداكن أو الفاتح
                                AnimatedImage(name: (colorScheme == .dark ? onboardingData[index].darkGifName : onboardingData[index].gifName) + ".gif")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 500, height: 500)
                                    .offset(y: index == 0 ? 40 : 80)
                                    .scaleEffect(1.5)
                                    .accessibilityLabel(onboardingData[index].title)
                                    .accessibilityHint(onboardingData[index].description)

                                VStack(spacing: 0) {
                                    Text(onboardingData[index].title)
                                        .font(.system(size: 28, weight: .bold, design: .default))
                                        .foregroundColor(Color.black)
                                        .accessibilityAddTraits(.isHeader)
                                    
                                    Text(onboardingData[index].description)
                                        .font(.system(size: 13, weight: .bold, design: .default))
                                        .foregroundColor(Color.black)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 300, height: 80)
                                        .accessibilityLabel(onboardingData[index].description)
                                }
                                .offset(y: -130)

                                HStack(spacing: 4) {
                                    ForEach(0..<onboardingData.count) { dotIndex in
                                        Circle()
                                            .frame(width: 8, height: 8)
                                            .foregroundColor(currentPage == dotIndex ? Color("AdditionalColor") : Color("gray1"))
                                            .accessibilityHidden(true)
                                    }
                                }.offset(y: -110)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .onAppear {
                        UIPageControl.appearance().isHidden = true
                    }
                }
                
                VStack {
                    Button(action: {
                        if currentPage == onboardingData.count - 1 {
                            print("Onboarding Completed")
                            isOnboardingComplete = true
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }) {
                        Text(currentPage == onboardingData.count - 1 ? "Get Started" : "Next")
                            .frame(width: 207, height: 40)
                            .background(Color("PrimaryColor"))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .accessibilityLabel(currentPage == onboardingData.count - 1 ? "Get Started" : "Next Step")
                    .accessibilityHint(currentPage == onboardingData.count - 1 ? "Finish onboarding and go to main app" : "Move to the next onboarding screen")
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 190)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct OnboardingData {
    let gifName: String
    let darkGifName: String
    let title: String
    let description: String
}

struct OnboardingView_Previews: PreviewProvider {
    @State static var isOnboardingComplete = false // إنشاء متغير State للمعاينة
    
    static var previews: some View {
        OnboardingView(isOnboardingComplete: $isOnboardingComplete) // تمرير المتغير كـ Binding
    }
}

//
//  TaqdaAppApp.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 12/05/1446 AH.
//
//
//import SwiftUI
//struct DynamicTypeModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .dynamicTypeSize(.xSmall ... .accessibility5) // Apply dynamic type scaling
//    }
//}
//
//extension View {
//    func applyDynamicType() -> some View {
//        self.modifier(DynamicTypeModifier()) // Use the custom modifier
//    }
//}
//@main
//struct TaqdaAppApp: App {
//    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
//    @AppStorage("isUserSignedIn") private var isUserSignedIn = false // Check if the user is signed in
//    @State private var isSplashScreenActive = true
//    //    @StateObject var userSession = UserSession()
//    @StateObject private var viewModel = CreateListViewModel(userSession: UserSession.shared) // Use the
//    var body: some Scene {
//        WindowGroup {
//            if isSplashScreenActive {
//                SplashScreenView()
//                    .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                            withAnimation {
//                                isSplashScreenActive = false
//                            }
//                        }
//                    }
//                    .applyDynamicType()
//            } else {
//                if isOnboardingComplete {
//                    // عرض الـ MainTabView مباشرة بعد الانتهاء من Onboarding
//                    MainTabView()
//                        .applyDynamicType()
//                        .environmentObject(UserSession.shared) // الحفاظ على UserSession
//                } else {
//                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
//                        .applyDynamicType()
//                }
//            }
//        }
//    }
//}
//
//  TaqdaAppApp.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 12/05/1446 AH.
//

import SwiftUI
import TipKit
struct DynamicTypeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(.xSmall ... .accessibility5) // Apply dynamic type scaling
    }
}

extension View {
    func applyDynamicType() -> some View {
        self.modifier(DynamicTypeModifier()) // Use the custom modifier
    }
}
@main
struct TaqdaAppApp: App {
    
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    @AppStorage("isUserSignedIn") private var isUserSignedIn = false // Check if the user is signed in
    @State private var isSplashScreenActive = true
    @StateObject private var userSession = UserSession.shared // Shared UserSession instance
    @StateObject private var viewModel = CreateListViewModel(userSession: UserSession.shared) // Use the shared session
    
       init() {
           // Configure TipKit on app initialization
           try? Tips.configure([
               .displayFrequency(.immediate),
               .datastoreLocation(.applicationDefault)
           ])
       }
    var body: some Scene {
        WindowGroup {

            if isSplashScreenActive {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isSplashScreenActive = false
                            }
                        }
                    }
                    .applyDynamicType()
            } else {
                if isOnboardingComplete {
                    // Show MainTabView after onboarding
                    MainTabView()
                        .environmentObject(userSession) // Inject UserSession into the environment
                        .applyDynamicType()
                } else {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                        .environmentObject(userSession) // Inject UserSession into the environment
                        .applyDynamicType()
                }
            }
        }
    }
}

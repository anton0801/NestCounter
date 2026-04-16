import SwiftUI

@main
struct NestCounterApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

// MARK: - Root View (Splash → Onboarding → Auth → Main)

struct RootView: View {
    
    @StateObject private var appState = AppState()
    @StateObject private var dataViewModel = DataViewModel()
    @StateObject private var notificationsManager = NotificationsManager.shared
    
    var body: some View {
        ZStack {
            if appState.isAuthenticated {
                if !appState.hasCompletedOnboarding {
                    OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                } else {
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                }
            } else {
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .environmentObject(appState)
        .environmentObject(dataViewModel)
        .environmentObject(notificationsManager)
        .preferredColorScheme(appState.colorScheme == .system ? .none : (appState.colorScheme == .dark ? .dark : .light))
        .onAppear {
            notificationsManager.requestPermission()
        }
    }
}

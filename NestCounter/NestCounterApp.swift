import SwiftUI

@main
struct NestCounterApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataViewModel = DataViewModel()
    @StateObject private var notificationsManager = NotificationsManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(dataViewModel)
                .environmentObject(notificationsManager)
                .preferredColorScheme(appState.colorScheme == .system ? .none : (appState.colorScheme == .dark ? .dark : .light))
                .onAppear {
                    notificationsManager.requestPermission()
                }
        }
    }
}

// MARK: - Root View (Splash → Onboarding → Auth → Main)

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            } else {
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
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
    }
}

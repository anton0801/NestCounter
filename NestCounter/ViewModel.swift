import Foundation
import Combine

@MainActor
final class NestCounterViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let appService: NestCounterAppService
    private var timeoutTask: Task<Void, Never>?
    
    init(appService: NestCounterAppService) {
        self.appService = appService
    }
    
    func initialize() {
        Task {
            _ = await appService.initialize()
            scheduleTimeout()
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            _ = appService.handleTracking(data)
            
            // ✅ Auto-trigger validation
            await performValidation()
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            appService.handleNavigation(data)
        }
    }
    
    func requestPermission() {
        Task {
            _ = await appService.requestPermission()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func deferPermission() {
        Task {
            appService.deferPermission()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        Task {
            showOfflineView = !isConnected
        }
    }
    
    private var passedAll = false
    
    func timeout() {
        Task {
            if !passedAll {
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private func performValidation() async {
        if !passedAll {
            do {
                let isValid = try await appService.validate()
                passedAll = true
                timeoutTask?.cancel()
                if isValid {
                    await executeBusinessLogic()
                } else {
                    timeoutTask?.cancel()
                    navigateToMain = true
                }
            } catch {
                print("🥚 [NestCounter] Validation error: \(error)")
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private func executeBusinessLogic() async {
        do {
            let url = try await appService.executeBusinessLogic()
            appService.finalizeWithEndpoint(url)
            
            if appService.canAskPermission() {
                showPermissionPrompt = true
            } else {
                navigateToWeb = true
            }
        } catch {
            print("🥚 [NestCounter] Business logic error: \(error)")
            navigateToMain = true
        }
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await timeout()
        }
    }
}

import Foundation
import AppsFlyerLib

final class NestCounterAppService {
    private let storage: StorageService
    private let validation: ValidationService
    private let network: NetworkService
    private let notification: NotificationService
    
    private var data: AppData = .initial
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
    }
    
    func initialize() async -> AppData {
        let stored = storage.loadState()
        data.tracking = stored.tracking
        data.navigation = stored.navigation
        data.mode = stored.mode
        data.isFirstLaunch = stored.isFirstLaunch
        data.permission = AppData.PermissionData(
            isGranted: stored.permission.isGranted,
            isDenied: stored.permission.isDenied,
            lastAsked: stored.permission.lastAsked
        )
        
        return data
    }
    
    // MARK: - Tracking
    
    func handleTracking(_ trackingData: [String: Any]) -> AppData {
        let converted = trackingData.mapValues { "\($0)" }
        data.tracking = converted
        storage.saveTracking(converted)
        return data
    }
    
    func handleNavigation(_ navigationData: [String: Any]) {
        let converted = navigationData.mapValues { "\($0)" }
        data.navigation = converted
        storage.saveNavigation(converted)
    }
    
    // MARK: - Validation
    
    func validate() async throws -> Bool {
        guard data.hasTracking() else {
            return false
        }
        
        do {
            return try await validation.validate()
        } catch {
            print("🥚 [NestCounter] Validation error: \(error)")
            throw error
        }
    }
    
    // MARK: - Business Logic
    
    func executeBusinessLogic() async throws -> String {
        guard !data.isLocked, data.hasTracking() else {
            throw ServiceError.notFound
        }
        
        // Check temp_url
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            return temp
        }
        
        // Check organic + first launch
        let attributionProcessed = data.metadata["attribution_processed"] == "true"
        if data.isOrganic() && data.isFirstLaunch && !attributionProcessed {
            data.metadata["attribution_processed"] = "true"
            try await executeOrganicFlow()
        }
        
        // Fetch endpoint
        return try await fetchEndpoint()
    }
    
    private func executeOrganicFlow() async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !data.isLocked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        var fetched = try await network.fetchAttribution(deviceID: deviceID)
        
        for (key, value) in data.navigation {
            if fetched[key] == nil {
                fetched[key] = value
            }
        }
        
        let converted = fetched.mapValues { "\($0)" }
        data.tracking = converted
        storage.saveTracking(converted)
    }
    
    private func fetchEndpoint() async throws -> String {
        guard !data.isLocked else {
            throw ServiceError.notFound
        }
        
        let trackingDict = data.tracking.mapValues { $0 as Any }
        return try await network.fetchEndpoint(tracking: trackingDict)
    }
    
    func finalizeWithEndpoint(_ url: String) {
        data.endpoint = url
        data.mode = "Active"
        data.isFirstLaunch = false
        data.isLocked = true
        
        storage.saveEndpoint(url)
        storage.saveMode("Active")
        storage.markLaunched()
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> AppData.PermissionData {
        // ✅ Локальная копия для избежания inout capture
        var localPermission = data.permission
        
        let updatedPermission = await withCheckedContinuation {
            (continuation: CheckedContinuation<AppData.PermissionData, Never>) in
            
            notification.requestPermission { granted in
                var permission = localPermission
                
                if granted {
                    permission.isGranted = true
                    permission.isDenied = false
                    permission.lastAsked = Date()
                    self.notification.registerForPush()
                } else {
                    permission.isGranted = false
                    permission.isDenied = true
                    permission.lastAsked = Date()
                }
                
                continuation.resume(returning: permission)
            }
        }
        
        data.permission = updatedPermission
        storage.savePermissions(updatedPermission)
        return updatedPermission
    }
    
    func deferPermission() {
        data.permission.lastAsked = Date()
        storage.savePermissions(data.permission)
    }
    
    func canAskPermission() -> Bool {
        data.permission.canAsk
    }
}

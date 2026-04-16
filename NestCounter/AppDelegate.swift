import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private let attributionBridge = AttributionBridge()
    private let pushBridge = PushBridge()
    private var sdkBridge: SDKBridge?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        attributionBridge.onTracking = { [weak self] in self?.relay(tracking: $0) }
        attributionBridge.onNavigation = { [weak self] in self?.relay(navigation: $0) }
        sdkBridge = SDKBridge(bridge: attributionBridge)
        setupFirebase()
        setupPush()
        setupSDK()
        if let push = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushBridge.process(push)
        }
        observeLifecycle()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func observeLifecycle() { NotificationCenter.default.addObserver(self, selector: #selector(activate), name: UIApplication.didBecomeActiveNotification, object: nil) }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        pushBridge.process(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        pushBridge.process(userInfo)
        completionHandler(.newData)
    }
    private func setupFirebase() { FirebaseApp.configure() }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.nestcounter.core")?.set(token, forKey: "shared_fcm")
        }
    }
    private func setupPush() { Messaging.messaging().delegate = self; UNUserNotificationCenter.current().delegate = self; UIApplication.shared.registerForRemoteNotifications() }
    private func setupSDK() { sdkBridge?.configure() }
    
    private func relay(tracking data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
    }
    @objc private func activate() { sdkBridge?.start() }
    
    private func relay(navigation data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        pushBridge.process(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
}

final class PushBridge: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(from: payload) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: .init("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from p: [AnyHashable: Any]) -> String? {
        if let u = p["url"] as? String { return u }
        if let d = p["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let a = p["aps"] as? [String: Any], let d = a["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let c = p["custom"] as? [String: Any], let u = c["target_url"] as? String { return u }
        return nil
    }
}


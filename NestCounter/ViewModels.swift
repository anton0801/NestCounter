import SwiftUI
import Combine
import UserNotifications

// MARK: - App State (EnvironmentObject)
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: NestUser? = nil
    @Published var hasCompletedOnboarding: Bool = false
    @Published var colorScheme: ColorSchemePreference = .system

    @AppStorage("isAuthenticated") private var storedAuth: Bool = false
    @AppStorage("hasCompletedOnboarding") private var storedOnboarding: Bool = false
    @AppStorage("colorSchemePref") private var storedScheme: String = "system"
    @AppStorage("currentUserJSON") private var storedUserJSON: String = ""

    enum ColorSchemePreference: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"

        var scheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }

    init() {
        isAuthenticated = storedAuth
        hasCompletedOnboarding = storedOnboarding
        colorScheme = ColorSchemePreference(rawValue: storedScheme) ?? .system
        if !storedUserJSON.isEmpty,
           let data = storedUserJSON.data(using: .utf8),
           let user = try? JSONDecoder().decode(NestUser.self, from: data) {
            currentUser = user
        }
    }

    func login(user: NestUser) {
        currentUser = user
        isAuthenticated = true
        storedAuth = true
        if let data = try? JSONEncoder().encode(user),
           let json = String(data: data, encoding: .utf8) {
            storedUserJSON = json
        }
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        storedAuth = false
        storedUserJSON = ""
    }

    func deleteAccount() {
        logout()
        storedOnboarding = false
        hasCompletedOnboarding = false
        // Clear all app data
        UserDefaults.standard.removeObject(forKey: "eggRecords")
        UserDefaults.standard.removeObject(forKey: "birdGroups")
        UserDefaults.standard.removeObject(forKey: "feedRecords")
        UserDefaults.standard.removeObject(forKey: "healthRecords")
        UserDefaults.standard.removeObject(forKey: "farmTasks")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        storedOnboarding = true
    }

    func setColorScheme(_ pref: ColorSchemePreference) {
        colorScheme = pref
        storedScheme = pref.rawValue
    }
}

// MARK: - Data ViewModel
class DataViewModel: ObservableObject {
    @Published var birdGroups: [BirdGroup] = []
    @Published var eggRecords: [EggRecord] = []
    @Published var feedRecords: [FeedRecord] = []
    @Published var healthRecords: [HealthRecord] = []
    @Published var tasks: [FarmTask] = []
    @Published var alerts: [FarmAlert] = []
    @Published var isLoading: Bool = false

    init() {
        loadAll()
    }

    // MARK: - Persistence
    private func loadAll() {
        birdGroups = load([BirdGroup].self, key: "birdGroups") ?? Self.demoGroups
        eggRecords = load([EggRecord].self, key: "eggRecords") ?? Self.demoEggRecords
        feedRecords = load([FeedRecord].self, key: "feedRecords") ?? Self.demoFeedRecords
        healthRecords = load([HealthRecord].self, key: "healthRecords") ?? Self.demoHealthRecords
        tasks = load([FarmTask].self, key: "farmTasks") ?? Self.demoTasks
        generateAlerts()
    }

    private func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        return decoded
    }

    private func save<T: Codable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Bird Groups CRUD
    func addBirdGroup(_ group: BirdGroup) {
        birdGroups.append(group)
        save(birdGroups, key: "birdGroups")
        generateAlerts()
    }

    func updateBirdGroup(_ group: BirdGroup) {
        if let idx = birdGroups.firstIndex(where: { $0.id == group.id }) {
            birdGroups[idx] = group
            save(birdGroups, key: "birdGroups")
        }
    }

    func deleteBirdGroup(_ group: BirdGroup) {
        birdGroups.removeAll { $0.id == group.id }
        save(birdGroups, key: "birdGroups")
    }

    // MARK: - Egg Records CRUD
    func addEggRecord(_ record: EggRecord) {
        eggRecords.insert(record, at: 0)
        save(eggRecords, key: "eggRecords")
        generateAlerts()
    }

    func deleteEggRecord(_ record: EggRecord) {
        eggRecords.removeAll { $0.id == record.id }
        save(eggRecords, key: "eggRecords")
    }

    func updateEggRecord(_ record: EggRecord) {
        if let idx = eggRecords.firstIndex(where: { $0.id == record.id }) {
            eggRecords[idx] = record
            save(eggRecords, key: "eggRecords")
        }
    }

    // MARK: - Feed Records CRUD
    func addFeedRecord(_ record: FeedRecord) {
        feedRecords.insert(record, at: 0)
        save(feedRecords, key: "feedRecords")
    }

    func deleteFeedRecord(_ record: FeedRecord) {
        feedRecords.removeAll { $0.id == record.id }
        save(feedRecords, key: "feedRecords")
    }

    // MARK: - Health Records CRUD
    func addHealthRecord(_ record: HealthRecord) {
        healthRecords.insert(record, at: 0)
        save(healthRecords, key: "healthRecords")
        generateAlerts()
    }

    func deleteHealthRecord(_ record: HealthRecord) {
        healthRecords.removeAll { $0.id == record.id }
        save(healthRecords, key: "healthRecords")
    }

    func toggleHealthResolved(_ record: HealthRecord) {
        if let idx = healthRecords.firstIndex(where: { $0.id == record.id }) {
            healthRecords[idx].resolved.toggle()
            save(healthRecords, key: "healthRecords")
        }
    }

    // MARK: - Tasks CRUD
    func addTask(_ task: FarmTask) {
        tasks.insert(task, at: 0)
        save(tasks, key: "farmTasks")
    }

    func deleteTask(_ task: FarmTask) {
        tasks.removeAll { $0.id == task.id }
        save(tasks, key: "farmTasks")
    }

    func toggleTask(_ task: FarmTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            save(tasks, key: "farmTasks")
        }
    }

    // MARK: - Stats Computation
    var productionStats: ProductionStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayRecords = eggRecords.filter { calendar.isDate($0.date, inSameDayAs: today) }
        let todayTotal = todayRecords.reduce(0) { $0 + $1.count }

        // Week data
        var weeklyData: [ProductionStats.DayData] = []
        let weekdays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -(6-i), to: today)!
            let count = eggRecords.filter { calendar.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.count }
            weeklyData.append(ProductionStats.DayData(label: weekdays[calendar.component(.weekday, from: day) == 1 ? 6 : calendar.component(.weekday, from: day) - 2], count: count, date: day))
        }
        let weekTotal = weeklyData.reduce(0) { $0 + $1.count }

        // Monthly data
        var monthlyData: [ProductionStats.WeekData] = []
        for i in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -(3-i), to: today)!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let count = eggRecords.filter { $0.date >= weekStart && $0.date <= weekEnd }.reduce(0) { $0 + $1.count }
            monthlyData.append(ProductionStats.WeekData(label: "W\(i+1)", count: count))
        }
        let monthTotal = monthlyData.reduce(0) { $0 + $1.count }

        let avgPerDay = weekTotal > 0 ? Double(weekTotal) / 7.0 : 0
        let bestDay = weeklyData.map { $0.count }.max() ?? 0

        // Productivity score: compare actual vs expected
        let expectedPerDay = birdGroups.reduce(0) { $0 + $1.expectedDailyEggs }
        let score: Int
        if expectedPerDay > 0 {
            let ratio = Double(todayTotal > 0 ? todayTotal : Int(avgPerDay)) / Double(expectedPerDay)
            score = min(100, Int(ratio * 100))
        } else {
            score = 75
        }

        return ProductionStats(
            todayTotal: todayTotal,
            weekTotal: weekTotal,
            monthTotal: monthTotal,
            avgPerDay: avgPerDay,
            bestDay: bestDay,
            productivityScore: score,
            weeklyData: weeklyData,
            monthlyData: monthlyData
        )
    }

    // MARK: - Alerts Generator
    func generateAlerts() {
        var newAlerts: [FarmAlert] = []
        let stats = productionStats

        if stats.productivityScore < 60 {
            newAlerts.append(FarmAlert(
                id: "low_prod",
                type: .lowProduction,
                title: "Low Production Alert",
                message: "Today's production is below 60% of expected output.",
                date: Date(),
                isRead: false
            ))
        }

        let activeHealth = healthRecords.filter { !$0.resolved }
        if !activeHealth.isEmpty {
            newAlerts.append(FarmAlert(
                id: "health_risk",
                type: .healthRisk,
                title: "Health Issues Active",
                message: "\(activeHealth.count) unresolved health issue(s) in your flock.",
                date: Date(),
                isRead: false
            ))
        }

        let overdueTasks = tasks.filter { !$0.isCompleted && $0.dueDate < Date() }
        if !overdueTasks.isEmpty {
            newAlerts.append(FarmAlert(
                id: "tasks_due",
                type: .taskDue,
                title: "Overdue Tasks",
                message: "\(overdueTasks.count) task(s) are overdue.",
                date: Date(),
                isRead: false
            ))
        }

        alerts = newAlerts
    }

    func dismissAlert(_ alert: FarmAlert) {
        alerts.removeAll { $0.id == alert.id }
    }

    // MARK: - Feed Impact Analysis
    func feedImpactForGroup(_ groupId: String) -> [(date: Date, feedKg: Double, eggs: Int)] {
        let calendar = Calendar.current
        var result: [(date: Date, feedKg: Double, eggs: Int)] = []
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -i, to: Date())!
            let dayFeed = feedRecords.filter {
                $0.birdGroupId == groupId && calendar.isDate($0.date, inSameDayAs: day)
            }.reduce(0.0) { $0 + $1.amountKg }
            let dayEggs = eggRecords.filter {
                $0.birdGroupId == groupId && calendar.isDate($0.date, inSameDayAs: day)
            }.reduce(0) { $0 + $1.count }
            result.append((date: day, feedKg: dayFeed, eggs: dayEggs))
        }
        return result.reversed()
    }

    // MARK: - Calendar Data
    func eggsForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return eggRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.count }
    }

    // MARK: - Demo Data
    static let demoGroups: [BirdGroup] = [
        BirdGroup(id: "g1", name: "Layers A", birdType: .chicken, count: 24, color: "#E8A020", addedAt: Date().addingTimeInterval(-86400*30)),
        BirdGroup(id: "g2", name: "Young Hens", birdType: .chicken, count: 12, color: "#5C8A3C", addedAt: Date().addingTimeInterval(-86400*15)),
        BirdGroup(id: "g3", name: "Duck Pond", birdType: .duck, count: 8, color: "#4A7FA5", addedAt: Date().addingTimeInterval(-86400*7))
    ]

    static var demoEggRecords: [EggRecord] {
        var records: [EggRecord] = []
        let groups = demoGroups
        for i in 0..<21 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            for group in groups {
                let base = group.expectedDailyEggs
                let variation = Int.random(in: -3...3)
                let count = max(0, base + variation)
                if count > 0 {
                    records.append(EggRecord(
                        id: UUID().uuidString,
                        birdGroupId: group.id,
                        birdGroupName: group.name,
                        count: count,
                        date: date,
                        notes: "",
                        photoCount: i % 3 == 0,
                        confidence: i % 3 == 0 ? Double.random(in: 0.85...0.98) : nil
                    ))
                }
            }
        }
        return records
    }

    static var demoFeedRecords: [FeedRecord] {
        var records: [FeedRecord] = []
        let groups = demoGroups
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            for group in groups {
                records.append(FeedRecord(
                    id: UUID().uuidString,
                    birdGroupId: group.id,
                    birdGroupName: group.name,
                    feedType: .layer,
                    amountKg: Double.random(in: 1.5...3.5),
                    date: date,
                    notes: ""
                ))
            }
        }
        return records
    }

    static var demoHealthRecords: [HealthRecord] {
        [
            HealthRecord(id: UUID().uuidString, birdGroupId: "g2", birdGroupName: "Young Hens", issue: .moulting, treatment: "Extra protein feed", date: Date().addingTimeInterval(-86400*3), resolved: false, notes: "3 birds showing feather loss"),
            HealthRecord(id: UUID().uuidString, birdGroupId: "g1", birdGroupName: "Layers A", issue: .stress, treatment: "Improved lighting schedule", date: Date().addingTimeInterval(-86400*10), resolved: true, notes: "Resolved after schedule fix")
        ]
    }

    static var demoTasks: [FarmTask] {
        let cal = Calendar.current
        return [
            FarmTask(id: UUID().uuidString, title: "Collect eggs from Layers A", dueDate: cal.date(byAdding: .hour, value: 2, to: Date())!, isCompleted: false, priority: .high, category: .collect),
            FarmTask(id: UUID().uuidString, title: "Feed Duck Pond", dueDate: cal.date(byAdding: .hour, value: 4, to: Date())!, isCompleted: false, priority: .medium, category: .feed),
            FarmTask(id: UUID().uuidString, title: "Health check Young Hens", dueDate: cal.date(byAdding: .day, value: 1, to: Date())!, isCompleted: false, priority: .high, category: .health),
            FarmTask(id: UUID().uuidString, title: "Clean coop", dueDate: cal.date(byAdding: .day, value: 2, to: Date())!, isCompleted: true, priority: .low, category: .cleaning)
        ]
    }
}

// MARK: - Auth ViewModel
class AuthViewModel: ObservableObject {
    @Published var nameField: String = ""
    @Published var emailField: String = ""
    @Published var passwordField: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    // Simple in-memory user store (keyed by email)
    private static var registeredUsers: [String: (user: NestUser, password: String)] = {
        let demo = NestUser.demo
        return [demo.email: (user: demo, password: "demo123")]
    }()

    func login(appState: AppState, email: String, password: String) {
        isLoading = true
        errorMessage = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isLoading = false
            let key = email.lowercased()
            if let stored = Self.registeredUsers[key], stored.password == password {
                appState.login(user: stored.user)
            } else {
                self.errorMessage = "Invalid email or password."
            }
        }
    }

    func loginDemo(appState: AppState) {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isLoading = false
            appState.login(user: .demo)
        }
    }

    func register(appState: AppState) {
        isLoading = true
        errorMessage = ""
        guard !nameField.isEmpty, !emailField.isEmpty, passwordField.count >= 6 else {
            isLoading = false
            errorMessage = passwordField.count < 6 ? "Password must be at least 6 characters." : "Please fill all fields."
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isLoading = false
            let key = self.emailField.lowercased()
            if Self.registeredUsers[key] != nil {
                self.errorMessage = "Email already registered."
                return
            }
            let newUser = NestUser(
                id: UUID().uuidString,
                name: self.nameField,
                email: self.emailField,
                farmName: "\(self.nameField)'s Farm",
                farmSize: .small,
                createdAt: Date()
            )
            Self.registeredUsers[key] = (user: newUser, password: self.passwordField)
            appState.login(user: newUser)
        }
    }
}

// MARK: - Notifications Manager
class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    @Published var isEnabled: Bool = false
    @AppStorage("notificationsEnabled") private var storedEnabled: Bool = false

    init() {
        isEnabled = storedEnabled
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isEnabled = granted
                self.storedEnabled = granted
            }
        }
    }

    func scheduleEggCollectionReminder(hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["egg_reminder"])
        guard isEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "🥚 Time to collect eggs!"
        content.body = "Don't forget to collect and record today's eggs."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "egg_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        isEnabled = false
        storedEnabled = false
    }
}

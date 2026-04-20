import Foundation
import SwiftUI

struct NestCounterConfig {
    static let appID = "6762210545"
    static let devKey = "MFAes2uiJTKFtreEaBErF8"
}

// MARK: - User Model
struct NestUser: Codable, Identifiable {
    var id: String
    var name: String
    var email: String
    var farmName: String
    var farmSize: FarmSize
    var createdAt: Date

    enum FarmSize: String, Codable, CaseIterable {
        case small = "Small (1-50 birds)"
        case medium = "Medium (51-200 birds)"
        case large = "Large (200+ birds)"
    }

    static let demo = NestUser(
        id: "demo",
        name: "Demo Farmer",
        email: "demo@nestcounter.app",
        farmName: "Happy Nest Farm",
        farmSize: .medium,
        createdAt: Date()
    )
}

// MARK: - Bird Group Model
struct BirdGroup: Codable, Identifiable {
    var id: String
    var name: String
    var birdType: BirdType
    var count: Int
    var color: String
    var addedAt: Date

    enum BirdType: String, Codable, CaseIterable {
        case chicken = "Chicken"
        case duck = "Duck"
        case quail = "Quail"
        case goose = "Goose"
        case turkey = "Turkey"

        var icon: String {
            switch self {
            case .chicken: return "🐔"
            case .duck: return "🦆"
            case .quail: return "🐦"
            case .goose: return "🪿"
            case .turkey: return "🦃"
            }
        }
        var avgEggsPerDay: Double {
            switch self {
            case .chicken: return 0.8
            case .duck: return 0.7
            case .quail: return 0.9
            case .goose: return 0.4
            case .turkey: return 0.3
            }
        }
    }

    var expectedDailyEggs: Int {
        Int(Double(count) * birdType.avgEggsPerDay)
    }
}

// MARK: - Egg Record Model
struct EggRecord: Codable, Identifiable {
    var id: String
    var birdGroupId: String
    var birdGroupName: String
    var count: Int
    var date: Date
    var notes: String
    var photoCount: Bool // was it counted by photo?
    var confidence: Double? // AI confidence if photo-counted

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Feed Record Model
struct FeedRecord: Codable, Identifiable {
    var id: String
    var birdGroupId: String
    var birdGroupName: String
    var feedType: FeedType
    var amountKg: Double
    var date: Date
    var notes: String

    enum FeedType: String, Codable, CaseIterable {
        case layer = "Layer Feed"
        case grower = "Grower Feed"
        case scratch = "Scratch Grain"
        case organic = "Organic Mix"
        case supplement = "Supplement"
        case oysterShell = "Oyster Shell"
    }
}

struct StoredData {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionState
    
    struct PermissionState {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
    }
}

// MARK: - Health Record Model
struct HealthRecord: Codable, Identifiable {
    var id: String
    var birdGroupId: String
    var birdGroupName: String
    var issue: HealthIssue
    var treatment: String
    var date: Date
    var resolved: Bool
    var notes: String

    enum HealthIssue: String, Codable, CaseIterable {
        case moulting = "Moulting"
        case disease = "Disease"
        case injury = "Injury"
        case stress = "Stress"
        case parasites = "Parasites"
        case nutritionDeficiency = "Nutrition Deficiency"
        case other = "Other"

        var icon: String {
            switch self {
            case .moulting: return "feather"
            case .disease: return "cross.circle"
            case .injury: return "bandage"
            case .stress: return "exclamationmark.triangle"
            case .parasites: return "ant"
            case .nutritionDeficiency: return "leaf"
            case .other: return "questionmark.circle"
            }
        }
    }
}

// MARK: - Task Model
struct FarmTask: Codable, Identifiable {
    var id: String
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: Priority
    var category: TaskCategory

    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: String {
            switch self {
            case .low: return "#5C8A3C"
            case .medium: return "#E8A020"
            case .high: return "#C0392B"
            }
        }
    }

    enum TaskCategory: String, Codable, CaseIterable {
        case collect = "Collect Eggs"
        case feed = "Feeding"
        case health = "Health Check"
        case cleaning = "Cleaning"
        case other = "Other"

        var icon: String {
            switch self {
            case .collect: return "basket"
            case .feed: return "fork.knife"
            case .health: return "heart"
            case .cleaning: return "sparkles"
            case .other: return "checkmark.circle"
            }
        }
    }
}

struct AppData {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionData
    var metadata: [String: String]
    var isLocked: Bool
    
    struct PermissionData {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
        
        var canAsk: Bool {
            guard !isGranted && !isDenied else { return false }
            if let date = lastAsked {
                return Date().timeIntervalSince(date) / 86400 >= 3
            }
            return true
        }
        
        static var initial: PermissionData {
            PermissionData(isGranted: false, isDenied: false, lastAsked: nil)
        }
    }
    
    func isOrganic() -> Bool {
        tracking["af_status"] == "Organic"
    }
    
    func hasTracking() -> Bool {
        !tracking.isEmpty
    }
    
    static var initial: AppData {
        AppData(
            tracking: [:],
            navigation: [:],
            endpoint: nil,
            mode: nil,
            isFirstLaunch: true,
            permission: .initial,
            metadata: [:],
            isLocked: false
        )
    }
}


struct PhotoCountResult: Identifiable {
    var id = UUID()
    var detectedCount: Int
    var confidence: Double
    var imageData: Data?
    var date: Date = Date()
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
    case noDataAvailable
}


// MARK: - Alert Model
struct FarmAlert: Identifiable {
    var id: String
    var type: AlertType
    var title: String
    var message: String
    var date: Date
    var isRead: Bool

    enum AlertType {
        case lowProduction
        case healthRisk
        case feedReminder
        case taskDue
        case productivityDrop

        var icon: String {
            switch self {
            case .lowProduction: return "arrow.down.circle.fill"
            case .healthRisk: return "cross.circle.fill"
            case .feedReminder: return "clock.fill"
            case .taskDue: return "checkmark.circle.fill"
            case .productivityDrop: return "chart.line.downtrend.xyaxis"
            }
        }
        var color: Color {
            switch self {
            case .lowProduction: return .nestAmber
            case .healthRisk: return .nestRed
            case .feedReminder: return .nestBlue
            case .taskDue: return .nestGreen
            case .productivityDrop: return .nestSoftRed
            }
        }
    }
}

// MARK: - Production Stats
struct ProductionStats {
    var todayTotal: Int
    var weekTotal: Int
    var monthTotal: Int
    var avgPerDay: Double
    var bestDay: Int
    var productivityScore: Int
    var weeklyData: [DayData]
    var monthlyData: [WeekData]

    struct DayData: Identifiable {
        var id = UUID()
        var label: String
        var count: Int
        var date: Date
    }

    struct WeekData: Identifiable {
        var id = UUID()
        var label: String
        var count: Int
    }
}


enum ServiceError: Error {
    case validationFailed
    case networkError
    case timeout
    case notFound
}

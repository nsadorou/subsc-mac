import Foundation

enum NotificationTiming: String, CaseIterable {
    case oneDayBefore = "oneDayBefore"
    case threeDaysBefore = "threeDaysBefore"
    case oneWeekBefore = "oneWeekBefore"
    case twoWeeksBefore = "twoWeeksBefore"
    
    var displayName: String {
        switch self {
        case .oneDayBefore:
            return "1日前"
        case .threeDaysBefore:
            return "3日前"
        case .oneWeekBefore:
            return "1週間前"
        case .twoWeeksBefore:
            return "2週間前"
        }
    }
    
    var daysBeforeRenewal: Int {
        switch self {
        case .oneDayBefore:
            return 1
        case .threeDaysBefore:
            return 3
        case .oneWeekBefore:
            return 7
        case .twoWeeksBefore:
            return 14
        }
    }
}
import Foundation

enum SubscriptionCycle: Int16, CaseIterable {
    case monthly = 0
    case yearly = 1
    
    var displayName: String {
        switch self {
        case .monthly:
            return "月額"
        case .yearly:
            return "年額"
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .monthly:
            return .month
        case .yearly:
            return .year
        }
    }
    
    var calendarValue: Int {
        switch self {
        case .monthly:
            return 1
        case .yearly:
            return 1
        }
    }
}
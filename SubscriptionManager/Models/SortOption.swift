//
//  SortOption.swift
//  SubscriptionManager
//
//  Created on 2025/01/10.
//

import Foundation

enum SortOption: String, CaseIterable {
    case nextRenewal = "次回更新日"
    case amount = "金額"
    case serviceName = "サービス名"
    case recentlyAdded = "追加日"
    
    var icon: String {
        switch self {
        case .nextRenewal: return "calendar"
        case .amount: return "yensign.circle"
        case .serviceName: return "textformat.abc"
        case .recentlyAdded: return "clock"
        }
    }
    
    var defaultAscending: Bool {
        switch self {
        case .nextRenewal: return true  // 近い順
        case .amount: return false      // 高い順
        case .serviceName: return true  // A-Z
        case .recentlyAdded: return false // 新しい順
        }
    }
}
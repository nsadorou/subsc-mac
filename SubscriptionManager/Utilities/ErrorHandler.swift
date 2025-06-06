//
//  ErrorHandler.swift
//  SubscriptionManager
//
//  Created on 2025/01/05.
//

import Foundation
import SwiftUI

// MARK: - Custom Error Types
enum SubscriptionError: LocalizedError {
    case invalidAmount
    case missingServiceName
    case invalidDate
    case saveFailure(String)
    case deleteFailure(String)
    case importFailure(String)
    case exportFailure(String)
    case networkError(String)
    case coreDataError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "金額が無効です。正しい数値を入力してください。"
        case .missingServiceName:
            return "サービス名を入力してください。"
        case .invalidDate:
            return "無効な日付です。"
        case .saveFailure(let message):
            return "保存に失敗しました: \(message)"
        case .deleteFailure(let message):
            return "削除に失敗しました: \(message)"
        case .importFailure(let message):
            return "インポートに失敗しました: \(message)"
        case .exportFailure(let message):
            return "エクスポートに失敗しました: \(message)"
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .coreDataError(let message):
            return "データエラー: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAmount:
            return "0以上の数値を入力してください。"
        case .missingServiceName:
            return "サービス名は必須項目です。"
        case .invalidDate:
            return "有効な日付を選択してください。"
        case .saveFailure:
            return "アプリを再起動して再試行してください。"
        case .deleteFailure:
            return "他のアプリを閉じて再試行してください。"
        case .importFailure:
            return "ファイル形式を確認してください。"
        case .exportFailure:
            return "ディスク容量を確認してください。"
        case .networkError:
            return "インターネット接続を確認してください。"
        case .coreDataError:
            return "アプリを再起動してください。"
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: IdentifiableError?
    @Published var showingError = false
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        let identifiableError = IdentifiableError(
            error: error,
            context: context,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.currentError = identifiableError
            self.showingError = true
        }
        
        // ログに記録
        AppLogger.shared.error("Error in \(context): \(error.localizedDescription)")
    }
    
    func handle(_ subscriptionError: SubscriptionError, context: String = "") {
        handle(subscriptionError as Error, context: context)
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showingError = false
        }
    }
}

// MARK: - Identifiable Error
struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: Error
    let context: String
    let timestamp: Date
    
    var title: String {
        if let subscriptionError = error as? SubscriptionError {
            return "エラー"
        } else {
            return "予期しないエラー"
        }
    }
    
    var message: String {
        return error.localizedDescription
    }
    
    var suggestion: String? {
        if let subscriptionError = error as? SubscriptionError {
            return subscriptionError.recoverySuggestion
        }
        return "アプリを再起動して再試行してください。"
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlert: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "エラー",
                isPresented: $errorHandler.showingError,
                presenting: errorHandler.currentError
            ) { error in
                Button("OK") {
                    errorHandler.clearError()
                }
                
                if error.suggestion != nil {
                    Button("詳細") {
                        // 詳細画面を表示（実装省略）
                    }
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.message)
                    
                    if let suggestion = error.suggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

// MARK: - Performance Monitoring
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var startTimes: [String: CFTimeInterval] = [:]
    
    private init() {}
    
    func startMeasuring(_ operation: String) {
        startTimes[operation] = CACurrentMediaTime()
    }
    
    func endMeasuring(_ operation: String) {
        guard let startTime = startTimes[operation] else { return }
        let duration = CACurrentMediaTime() - startTime
        startTimes.removeValue(forKey: operation)
        
        AppLogger.shared.info("Performance: \(operation) took \(String(format: "%.3f", duration))s")
        
        // 遅い操作を警告
        if duration > 1.0 {
            AppLogger.shared.warning("Slow operation detected: \(operation) took \(String(format: "%.3f", duration))s")
        }
    }
    
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation) }
        return try block()
    }
}

// MARK: - View Extensions
extension View {
    func errorHandling() -> some View {
        self.modifier(ErrorAlert())
    }
    
    func performanceMeasured(_ operation: String) -> some View {
        self.onAppear {
            PerformanceMonitor.shared.startMeasuring(operation)
        }
        .onDisappear {
            PerformanceMonitor.shared.endMeasuring(operation)
        }
    }
}

// MARK: - Result Extensions
extension Result {
    func handleError(context: String = "") {
        if case .failure(let error) = self {
            ErrorHandler.shared.handle(error, context: context)
        }
    }
}
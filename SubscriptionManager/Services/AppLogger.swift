import Foundation
import os.log

class AppLogger {
    static let shared = AppLogger()
    
    private let logger: Logger
    private let maxLogEntries = 1000
    private let logFileURL: URL
    
    private init() {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SubscriptionManager", category: "AppLogger")
        
        // ログファイルのパスを設定
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.logFileURL = documentsPath.appendingPathComponent("subscription_manager.log")
        
        // 起動時にログファイルをクリーンアップ
        cleanupOldLogs()
    }
    
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
    
    func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line) \(function)] \(message)"
        
        // システムログに出力
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
        
        // ファイルに書き込み
        writeToFile(logMessage)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, file: file, function: function, line: line)
    }
    
    private func writeToFile(_ message: String) {
        DispatchQueue.global(qos: .utility).async {
            let logEntry = message + "\n"
            
            if let data = logEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                    // ファイルが存在する場合は追記
                    if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    // ファイルが存在しない場合は新規作成
                    try? data.write(to: self.logFileURL)
                }
            }
        }
    }
    
    func getLogEntries(limit: Int = 100) -> [String] {
        guard let content = try? String(contentsOf: logFileURL) else { return [] }
        let lines = content.components(separatedBy: .newlines)
        return Array(lines.suffix(limit).filter { !$0.isEmpty })
    }
    
    func clearLogs() {
        try? FileManager.default.removeItem(at: logFileURL)
        info("Logs cleared by user")
    }
    
    func exportLogs() -> URL? {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else { return nil }
        return logFileURL
    }
    
    private func cleanupOldLogs() {
        // 7日より古いログエントリを削除
        guard let content = try? String(contentsOf: logFileURL) else { return }
        let lines = content.components(separatedBy: .newlines)
        
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let filteredLines = lines.filter { line in
            // タイムスタンプを抽出して7日以内かチェック
            if let timestampRange = line.range(of: #"\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]"#, options: .regularExpression),
               let timestamp = DateFormatter.logFormatter.date(from: String(line[timestampRange].dropFirst().dropLast())) {
                return timestamp > sevenDaysAgo
            }
            return true // パースできない場合は保持
        }
        
        // フィルタされたログを書き戻し
        let cleanedContent = filteredLines.joined(separator: "\n")
        try? cleanedContent.write(to: logFileURL, atomically: true, encoding: .utf8)
    }
}

// MARK: - Background Task Manager
class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    @Published var isBackgroundRefreshEnabled = false
    private let logger = AppLogger.shared
    private var timer: Timer?
    
    private init() {
        checkBackgroundAppRefreshStatus()
        setupPeriodicNotificationRefresh()
    }
    
    private func checkBackgroundAppRefreshStatus() {
        // macOS では Background App Refresh の状態確認は制限されている
        // ここではユーザーの設定に基づいて動作させる
        isBackgroundRefreshEnabled = UserDefaults.standard.bool(forKey: "backgroundRefreshEnabled")
        logger.info("Background refresh status: \(isBackgroundRefreshEnabled)")
    }
    
    func enableBackgroundRefresh(_ enabled: Bool) {
        isBackgroundRefreshEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "backgroundRefreshEnabled")
        
        if enabled {
            setupPeriodicNotificationRefresh()
            logger.info("Background refresh enabled")
        } else {
            stopPeriodicRefresh()
            logger.info("Background refresh disabled")
        }
    }
    
    private func setupPeriodicNotificationRefresh() {
        guard isBackgroundRefreshEnabled else { return }
        
        // 1時間ごとに通知を更新
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.performBackgroundNotificationRefresh()
        }
        
        logger.info("Periodic notification refresh scheduled")
    }
    
    private func stopPeriodicRefresh() {
        timer?.invalidate()
        timer = nil
        logger.info("Periodic notification refresh stopped")
    }
    
    private func performBackgroundNotificationRefresh() {
        logger.info("Starting background notification refresh")
        
        DispatchQueue.global(qos: .background).async {
            // 通知の更新処理
            NotificationManager.shared.refreshAllNotifications()
            
            DispatchQueue.main.async {
                self.logger.info("Background notification refresh completed")
            }
        }
    }
    
    func performManualRefresh() {
        logger.info("Manual notification refresh requested")
        performBackgroundNotificationRefresh()
    }
}

// MARK: - DateFormatter Extension
private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
import SwiftUI
import UniformTypeIdentifiers

struct DebugLogView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backgroundTaskManager = BackgroundTaskManager.shared
    @State private var logEntries: [String] = []
    @State private var selectedLogLevel: AppLogger.LogLevel = .info
    @State private var autoRefresh = true
    @State private var showingExportDialog = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            headerSection
            
            Divider()
            
            // コントロール
            controlSection
            
            Divider()
            
            // ログ表示
            logDisplaySection
        }
        .navigationTitle("デバッグログ")
        .onAppear {
            loadLogs()
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .fileExporter(
            isPresented: $showingExportDialog,
            document: LogFileDocument(url: AppLogger.shared.exportLogs()),
            contentType: .plainText,
            defaultFilename: "subscription_manager_logs"
        ) { result in
            switch result {
            case .success(let url):
                AppLogger.shared.info("Logs exported to \(url)")
            case .failure(let error):
                AppLogger.shared.error("Failed to export logs: \(error)")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("システムログとデバッグ情報")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("アプリの動作状況と通知システムのデバッグ情報を表示します")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var controlSection: some View {
        HStack {
            // ログレベルフィルター
            Picker("ログレベル", selection: $selectedLogLevel) {
                ForEach(AppLogger.LogLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            
            Spacer()
            
            // 自動更新
            Toggle("自動更新", isOn: $autoRefresh)
                .onChange(of: autoRefresh) { enabled in
                    if enabled {
                        startAutoRefresh()
                    } else {
                        stopAutoRefresh()
                    }
                }
            
            // 手動更新
            Button("更新") {
                loadLogs()
            }
            .buttonStyle(.bordered)
            
            // エクスポート
            Button("エクスポート") {
                showingExportDialog = true
            }
            .buttonStyle(.bordered)
            
            // クリア
            Button("クリア") {
                AppLogger.shared.clearLogs()
                loadLogs()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            
            // 閉じる
            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.escape)
        }
        .padding()
    }
    
    private var logDisplaySection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredLogEntries.indices, id: \.self) { index in
                        LogEntryView(entry: filteredLogEntries[index])
                            .id(index)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: logEntries) { _ in
                if autoRefresh && !filteredLogEntries.isEmpty {
                    proxy.scrollTo(filteredLogEntries.count - 1, anchor: .bottom)
                }
            }
        }
    }
    
    private var filteredLogEntries: [String] {
        logEntries.filter { entry in
            entry.contains("[\(selectedLogLevel.rawValue)]") || selectedLogLevel == .debug
        }
    }
    
    private func loadLogs() {
        logEntries = AppLogger.shared.getLogEntries(limit: 500)
    }
    
    private func startAutoRefresh() {
        guard autoRefresh else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            loadLogs()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

struct LogEntryView: View {
    let entry: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // ログレベルインジケーター
            Circle()
                .fill(logLevelColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            // ログ内容
            Text(entry)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(logLevelColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
    
    private var logLevelColor: Color {
        if entry.contains("[ERROR]") || entry.contains("[CRITICAL]") {
            return .red
        } else if entry.contains("[WARNING]") {
            return .orange
        } else if entry.contains("[INFO]") {
            return .blue
        } else if entry.contains("[DEBUG]") {
            return .gray
        } else {
            return .primary
        }
    }
}

struct BackgroundTaskStatusView: View {
    @ObservedObject var backgroundTaskManager: BackgroundTaskManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("バックグラウンド処理")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("バックグラウンド更新")
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { backgroundTaskManager.isBackgroundRefreshEnabled },
                        set: { backgroundTaskManager.enableBackgroundRefresh($0) }
                    ))
                    .labelsHidden()
                }
                
                if backgroundTaskManager.isBackgroundRefreshEnabled {
                    Text("通知は1時間ごとに自動更新されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("今すぐ更新") {
                        backgroundTaskManager.performManualRefresh()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Log File Document
struct LogFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    let url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url,
              let data = try? Data(contentsOf: url) else {
            return FileWrapper(regularFileWithContents: Data())
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

struct DebugLogView_Previews: PreviewProvider {
    static var previews: some View {
        DebugLogView()
    }
}
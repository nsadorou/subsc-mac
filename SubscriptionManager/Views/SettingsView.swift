import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("defaultNotificationTime") private var defaultNotificationTime = Date()
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingExchangeRateHistory = false
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var exportMessage = ""
    @State private var showingExportResult = false
    @State private var showingIconGenerator = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("設定")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Form {
                Section("通知設定") {
                    if notificationManager.notificationPermissionStatus == .authorized {
                        Toggle("通知を有効にする", isOn: $notificationEnabled)
                        
                        if notificationEnabled {
                            DatePicker("デフォルト通知時間", selection: $defaultNotificationTime, displayedComponents: .hourAndMinute)
                        }
                        
                        NavigationLink("詳細な通知設定") {
                            NotificationSettingsView()
                        }
                    } else {
                        NotificationPermissionView()
                            .frame(height: 200)
                    }
                }
                
                Section("為替レート") {
                    Button("為替レート履歴を表示") {
                        showingExchangeRateHistory = true
                    }
                    
                    Button("為替レートキャッシュをクリア") {
                        ExchangeRateService.shared.clearCache()
                    }
                    .foregroundColor(.orange)
                }
                
                Section("データ管理") {
                    Button("データをエクスポート") {
                        showingExportOptions = true
                    }
                    
                    Button("データをインポート") {
                        showingImportPicker = true
                    }
                    
                    Button("すべてのデータを削除") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("システム") {
                    NavigationLink("デバッグログ") {
                        DebugLogView()
                    }
                    
                    Button("アプリアイコン生成") {
                        showingIconGenerator = true
                    }
                    
                    BackgroundTaskStatusView(backgroundTaskManager: BackgroundTaskManager.shared)
                }
                
                Section("アプリについて") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .sheet(isPresented: $showingExchangeRateHistory) {
            ExchangeRateHistoryView()
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                exportMessage: $exportMessage,
                showingExportResult: $showingExportResult
            )
        }
        .sheet(isPresented: $showingIconGenerator) {
            AppIconExporter()
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert("データ削除の確認", isPresented: $showingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                deleteAllData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("すべてのサブスクリプションデータが削除されます。この操作は元に戻せません。")
        }
        .alert("エクスポート結果", isPresented: $showingExportResult) {
            Button("OK") { }
        } message: {
            Text(exportMessage)
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let (successCount, errors) = DataExportService.shared.importFromJSON(
                url: url,
                context: viewContext
            )
            
            if errors.isEmpty {
                exportMessage = "\(successCount)件のサブスクリプションをインポートしました。"
            } else {
                exportMessage = "\(successCount)件をインポート。エラー: \(errors.joined(separator: ", "))"
            }
            showingExportResult = true
            
        case .failure(let error):
            exportMessage = "インポートに失敗しました: \(error.localizedDescription)"
            showingExportResult = true
        }
    }
    
    private func deleteAllData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Subscription.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
            AppLogger.shared.info("All subscription data deleted")
        } catch {
            AppLogger.shared.error("Failed to delete all data: \(error.localizedDescription)")
        }
    }
}

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var exportMessage: String
    @Binding var showingExportResult: Bool
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.serviceName, ascending: true)],
        animation: .default)
    private var subscriptions: FetchedResults<Subscription>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー
            HStack {
                Text("データエクスポート")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("キャンセル") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            
            Text("エクスポートしたいファイル形式を選択してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // エクスポートオプション
            VStack(spacing: 16) {
                ExportOptionCard(
                    title: "CSV形式",
                    description: "Excel等で開けるスプレッドシート形式",
                    icon: "doc.text",
                    action: { exportCSV() }
                )
                
                ExportOptionCard(
                    title: "JSON形式",
                    description: "アプリ間でのデータ移行に適した形式",
                    icon: "doc.plaintext",
                    action: { exportJSON() }
                )
            }
            
            Divider()
            
            // データ情報
            HStack {
                Text("エクスポート対象:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(subscriptions.count)件のサブスクリプション")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func exportCSV() {
        let subscriptionsArray = Array(subscriptions)
        if let fileURL = DataExportService.shared.exportToCSV(subscriptions: subscriptionsArray) {
            NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
            exportMessage = "CSVファイルをエクスポートしました。\nファイル: \(fileURL.lastPathComponent)"
        } else {
            exportMessage = "CSVエクスポートに失敗しました。"
        }
        showingExportResult = true
        dismiss()
    }
    
    private func exportJSON() {
        let subscriptionsArray = Array(subscriptions)
        if let fileURL = DataExportService.shared.exportToJSON(subscriptions: subscriptionsArray) {
            NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
            exportMessage = "JSONファイルをエクスポートしました。\nファイル: \(fileURL.lastPathComponent)"
        } else {
            exportMessage = "JSONエクスポートに失敗しました。"
        }
        showingExportResult = true
        dismiss()
    }
}

struct ExportOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
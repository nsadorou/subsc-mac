import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("defaultNotificationTime") private var defaultNotificationTime = Date()
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingExchangeRateHistory = false
    
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
                        
                    }
                    
                    Button("すべてのデータを削除") {
                        
                    }
                    .foregroundColor(.red)
                }
                
                Section("システム") {
                    NavigationLink("デバッグログ") {
                        DebugLogView()
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
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
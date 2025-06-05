import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("globalNotificationEnabled") private var globalNotificationEnabled = true
    @AppStorage("defaultNotificationTime") private var defaultNotificationTime = Date()
    @AppStorage("defaultNotificationTimings") private var defaultNotificationTimingsData = Data()
    
    @State private var defaultNotificationTimings: Set<Int> = [0] // デフォルトは1日前
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var showingTestAlert = false
    
    let notificationTimingOptions = [
        (0, "1日前"),
        (1, "3日前"),
        (2, "1週間前"),
        (3, "2週間前")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 通知権限状態
                notificationPermissionSection
                
                if notificationManager.notificationPermissionStatus == .authorized {
                    // グローバル設定
                    globalSettingsSection
                    
                    // デフォルト設定
                    defaultSettingsSection
                    
                    // 現在の通知一覧
                    pendingNotificationsSection
                    
                    // テスト機能
                    testSection
                }
            }
            .padding()
        }
        .navigationTitle("通知設定")
        .onAppear {
            loadDefaultSettings()
            loadPendingNotifications()
        }
        .alert("テスト通知を送信しました", isPresented: $showingTestAlert) {
            Button("OK") {}
        } message: {
            Text("2秒後にテスト通知が表示されます。")
        }
    }
    
    private var notificationPermissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知権限")
                .font(.headline)
            
            HStack {
                Image(systemName: notificationManager.notificationPermissionStatus == .authorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(notificationManager.notificationPermissionStatus == .authorized ? .green : .red)
                
                Text(notificationStatusText)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if notificationManager.notificationPermissionStatus != .authorized {
                    Button("許可を要求") {
                        notificationManager.requestNotificationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var globalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("グローバル設定")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("通知を有効にする", isOn: $globalNotificationEnabled)
                    .onChange(of: globalNotificationEnabled) { enabled in
                        if enabled {
                            notificationManager.refreshAllNotifications()
                        } else {
                            // すべての通知を削除
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        }
                    }
                
                if globalNotificationEnabled {
                    HStack {
                        Text("すべての通知を更新")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("今すぐ更新") {
                            notificationManager.refreshAllNotifications()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var defaultSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("新規サブスクリプションのデフォルト設定")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("デフォルト通知タイミング")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(notificationTimingOptions, id: \.0) { timing in
                        Toggle(timing.1, isOn: Binding(
                            get: { defaultNotificationTimings.contains(timing.0) },
                            set: { isSelected in
                                if isSelected {
                                    defaultNotificationTimings.insert(timing.0)
                                } else {
                                    defaultNotificationTimings.remove(timing.0)
                                }
                                saveDefaultSettings()
                            }
                        ))
                    }
                }
                
                HStack {
                    Text("デフォルト通知時刻")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $defaultNotificationTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.field)
                        .labelsHidden()
                        .frame(width: 100)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var pendingNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("予定されている通知")
                    .font(.headline)
                
                Spacer()
                
                Button("更新") {
                    loadPendingNotifications()
                }
                .buttonStyle(.bordered)
            }
            
            if pendingNotifications.isEmpty {
                Text("予定されている通知はありません")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(pendingNotifications.prefix(10), id: \.identifier) { notification in
                        NotificationRowView(notification: notification)
                    }
                    
                    if pendingNotifications.count > 10 {
                        Text("他 \(pendingNotifications.count - 10) 件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
    
    private var testSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("テスト機能")
                .font(.headline)
            
            HStack {
                Text("通知が正常に動作するかテストできます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("テスト通知を送信") {
                    sendTestNotification()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var notificationStatusText: String {
        switch notificationManager.notificationPermissionStatus {
        case .authorized:
            return "通知が許可されています"
        case .denied:
            return "通知が拒否されています"
        case .notDetermined:
            return "通知の許可が要求されていません"
        case .provisional:
            return "仮の通知許可が与えられています"
        case .ephemeral:
            return "一時的な通知許可が与えられています"
        @unknown default:
            return "不明な状態"
        }
    }
    
    private func loadDefaultSettings() {
        if let data = UserDefaults.standard.data(forKey: "defaultNotificationTimings"),
           let timings = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            defaultNotificationTimings = timings
        }
    }
    
    private func saveDefaultSettings() {
        if let data = try? JSONEncoder().encode(defaultNotificationTimings) {
            UserDefaults.standard.set(data, forKey: "defaultNotificationTimings")
        }
    }
    
    private func loadPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests.sorted { first, second in
                    guard let firstTrigger = first.trigger as? UNCalendarNotificationTrigger,
                          let secondTrigger = second.trigger as? UNCalendarNotificationTrigger,
                          let firstDate = Calendar.current.nextDate(after: Date(), matching: firstTrigger.dateComponents, matchingPolicy: .nextTime),
                          let secondDate = Calendar.current.nextDate(after: Date(), matching: secondTrigger.dateComponents, matchingPolicy: .nextTime) else {
                        return false
                    }
                    return firstDate < secondDate
                }
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "テスト通知"
        content.body = "サブスクリプション管理アプリの通知機能は正常に動作しています。"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.showingTestAlert = true
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: UNNotificationRequest
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.content.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(notification.content.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
               let date = Calendar.current.nextDate(after: Date(), matching: trigger.dateComponents, matchingPolicy: .nextTime) {
                Text(formatNotificationDate(date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatNotificationDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
            .environmentObject(NotificationManager.shared)
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("通知を有効にする")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("サブスクリプションの更新前に通知を受け取るには、通知の許可が必要です。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)
            
            VStack(spacing: 12) {
                switch notificationManager.notificationPermissionStatus {
                case .notDetermined:
                    Button(action: {
                        notificationManager.requestNotificationPermission()
                    }) {
                        Label("通知を許可", systemImage: "bell")
                            .frame(maxWidth: 200)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    
                case .denied:
                    Text("通知が拒否されています")
                        .foregroundColor(.red)
                    
                    Button(action: {
                        showingAlert = true
                    }) {
                        Label("システム環境設定を開く", systemImage: "gear")
                            .frame(maxWidth: 250)
                    }
                    .controlSize(.regular)
                    
                case .authorized:
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("通知が有効になっています")
                            .foregroundColor(.green)
                    }
                    
                case .provisional, .ephemeral:
                    Text("通知が部分的に許可されています")
                        .foregroundColor(.orange)
                    
                @unknown default:
                    EmptyView()
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("システム環境設定で通知を有効にしてください", isPresented: $showingAlert) {
            Button("システム環境設定を開く") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("「システム環境設定」>「通知」でこのアプリの通知を有効にしてください。")
        }
    }
}
import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("defaultNotificationTime") private var defaultNotificationTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("設定")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Form {
                Section("通知設定") {
                    Toggle("通知を有効にする", isOn: $notificationEnabled)
                    
                    if notificationEnabled {
                        DatePicker("デフォルト通知時間", selection: $defaultNotificationTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("データ管理") {
                    Button("データをエクスポート") {
                        
                    }
                    
                    Button("すべてのデータを削除") {
                        
                    }
                    .foregroundColor(.red)
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
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
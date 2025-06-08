import SwiftUI
import UserNotifications

struct AddEditSubscriptionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @ObservedObject private var exchangeRateService = ExchangeRateService.shared
    
    @State private var serviceName = ""
    @State private var amount = ""
    @State private var currency = "JPY"
    @State private var paymentMethod = "クレジットカード"
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var cycle = 0
    @State private var selectedNotificationTimings: Set<Int> = []
    @State private var notificationTime = Date()
    @State private var exchangeRate: Double?
    @State private var convertedAmount: Double?
    @State private var showingExchangeError = false
    @State private var exchangeErrorMessage = ""
    
    let subscription: Subscription?
    let isEditMode: Bool
    
    let currencies = ["JPY", "USD"]
    // let paymentMethods = ["クレジットカード", "デビットカード", "銀行振替", "PayPal", "その他"] // 削除予定
    let cycles = ["月額", "年額"]
    let notificationTimingOptions = [
        (0, "1日前"),
        (1, "3日前"),
        (2, "1週間前"),
        (3, "2週間前")
    ]
    
    init(subscription: Subscription? = nil) {
        self.subscription = subscription
        self.isEditMode = subscription != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // タイトルバー
            HStack {
                Text(isEditMode ? "サブスクリプション編集" : "サブスクリプション追加")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            .padding()
            
            // フォーム本体
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // サービス名
                    VStack(alignment: .leading, spacing: 8) {
                        Text("サービス名")
                            .font(.headline)
                        TextField("", text: $serviceName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // 金額と通貨
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("金額")
                                    .font(.headline)
                                TextField("", text: $amount)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: amount) { _, newValue in
                                        updateExchangeRate()
                                    }
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("通貨")
                                    .font(.headline)
                                Picker("", selection: $currency) {
                                    ForEach(currencies, id: \.self) { currency in
                                        Text(currency)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .onChange(of: currency) { _, newValue in
                                    updateExchangeRate()
                                }
                            }
                        }
                        
                        // 換算表示
                        if currency == "USD", let rate = exchangeRate, let converted = convertedAmount {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("日本円換算: ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                + Text(CurrencyFormatter.shared.format(amount: converted, currency: "JPY"))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text("(@¥\(CurrencyFormatter.shared.formatExchangeRate(rate)))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if exchangeRateService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // エラー表示
                        if showingExchangeError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                
                                Text(exchangeErrorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("再試行") {
                                    updateExchangeRate()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // 支払い方法
                    VStack(alignment: .leading, spacing: 8) {
                        Text("支払い方法")
                            .font(.headline)
                        SmartPaymentMethodField(paymentMethod: $paymentMethod)
                    }
                    
                    // 契約開始日
                    VStack(alignment: .leading, spacing: 8) {
                        Text("契約開始日")
                            .font(.headline)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.field)
                            .labelsHidden()
                    }
                    
                    // 更新サイクル
                    VStack(alignment: .leading, spacing: 8) {
                        Text("更新サイクル")
                            .font(.headline)
                        Picker("", selection: $cycle) {
                            ForEach(0..<cycles.count, id: \.self) { index in
                                Text(cycles[index]).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    
                    // 通知設定
                    VStack(alignment: .leading, spacing: 8) {
                        Text("通知設定")
                            .font(.headline)
                        
                        if notificationManager.notificationPermissionStatus == .authorized {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("通知タイミング（複数選択可）")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(notificationTimingOptions, id: \.0) { timing in
                                    Toggle(timing.1, isOn: Binding(
                                        get: { selectedNotificationTimings.contains(timing.0) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedNotificationTimings.insert(timing.0)
                                            } else {
                                                selectedNotificationTimings.remove(timing.0)
                                            }
                                        }
                                    ))
                                }
                                
                                if !selectedNotificationTimings.isEmpty {
                                    HStack {
                                        Text("通知時刻")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.field)
                                            .labelsHidden()
                                            .frame(width: 100)
                                        
                                        Spacer()
                                        
                                        Button("プレビュー") {
                                            previewNotification()
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(serviceName.isEmpty || amount.isEmpty)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        } else {
                            HStack {
                                Image(systemName: "bell.slash")
                                    .foregroundColor(.orange)
                                Text("通知を有効にすると、更新前に通知を受け取れます")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                    
                    // 備考
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備考")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .font(.body)
                            .frame(minHeight: 100)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                            )
                    }
                }
                .padding()
            }
            
            Divider()
            
            // ボタンエリア
            HStack {
                Spacer()
                Button("キャンセル") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("保存") {
                    saveSubscription()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(serviceName.isEmpty || amount.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if let subscription = subscription {
                serviceName = subscription.serviceName ?? ""
                amount = subscription.amount?.stringValue ?? ""
                currency = subscription.currency ?? "JPY"
                paymentMethod = subscription.paymentMethod ?? "クレジットカード"
                notes = subscription.notes ?? ""
                startDate = subscription.startDate ?? Date()
                cycle = Int(subscription.cycle)
                
                if let timings = subscription.notificationTimings {
                    selectedNotificationTimings = Set(timings)
                }
                if let time = subscription.notificationTime {
                    notificationTime = time
                }
                
                // 既存の為替レートを読み込み
                if let rate = subscription.exchangeRate {
                    exchangeRate = rate.doubleValue
                    updateConvertedAmount()
                }
            }
            
            // 初回読み込み時に為替レートを取得
            if currency == "USD" && !amount.isEmpty {
                updateExchangeRate()
            }
        }
    }
    
    private func saveSubscription() {
        let subscriptionToSave: Subscription
        
        if let existingSubscription = subscription {
            subscriptionToSave = existingSubscription
        } else {
            subscriptionToSave = Subscription(context: viewContext)
            subscriptionToSave.id = UUID()
            subscriptionToSave.createdAt = Date()
            subscriptionToSave.isActive = true
        }
        
        subscriptionToSave.serviceName = serviceName
        subscriptionToSave.amount = NSDecimalNumber(string: amount)
        subscriptionToSave.currency = currency
        subscriptionToSave.paymentMethod = paymentMethod
        subscriptionToSave.notes = notes
        subscriptionToSave.startDate = startDate
        subscriptionToSave.cycle = Int16(cycle)
        subscriptionToSave.updatedAt = Date()
        subscriptionToSave.notificationTimings = Array(selectedNotificationTimings)
        subscriptionToSave.notificationTime = notificationTime
        
        // 為替レートを保存（USD入力時のみ）
        if currency == "USD", let rate = exchangeRate {
            subscriptionToSave.exchangeRate = NSDecimalNumber(value: rate)
        } else {
            subscriptionToSave.exchangeRate = nil
        }
        
        do {
            try viewContext.save()
            
            // 通知をスケジュール
            if !selectedNotificationTimings.isEmpty {
                notificationManager.scheduleNotification(for: subscriptionToSave)
            } else {
                notificationManager.removeAllNotifications(for: subscriptionToSave)
            }
            
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func previewNotification() {
        guard notificationManager.notificationPermissionStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "サブスクリプション更新のお知らせ（プレビュー）"
        content.body = "\(serviceName)が明日に更新されます。金額: \(formatPreviewAmount())"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "preview_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling preview notification: \(error)")
            }
        }
    }
    
    private func formatPreviewAmount() -> String {
        if let amountValue = Double(amount) {
            return CurrencyFormatter.shared.formatWithRate(
                amount: amountValue,
                currency: currency,
                rate: currency == "USD" ? exchangeRate : nil
            )
        }
        return "\(amount) \(currency)"
    }
    
    private func updateExchangeRate() {
        // リセット
        showingExchangeError = false
        convertedAmount = nil
        
        // USD以外または金額が空の場合はスキップ
        guard currency == "USD", let amountValue = Double(amount), amountValue > 0 else {
            exchangeRate = nil
            return
        }
        
        // 為替レートを取得
        exchangeRateService.getExchangeRate(from: "USD", to: "JPY") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let rate):
                    exchangeRate = rate
                    updateConvertedAmount()
                    showingExchangeError = false
                case .failure(let error):
                    showingExchangeError = true
                    exchangeErrorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateConvertedAmount() {
        guard let rate = exchangeRate, let amountValue = Double(amount) else {
            convertedAmount = nil
            return
        }
        convertedAmount = amountValue * rate
    }
}

struct AddEditSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditSubscriptionView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
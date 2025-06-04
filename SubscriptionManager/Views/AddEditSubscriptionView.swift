import SwiftUI

struct AddEditSubscriptionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var serviceName = ""
    @State private var amount = ""
    @State private var currency = "JPY"
    @State private var paymentMethod = "クレジットカード"
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var cycle = 0
    
    let subscription: Subscription?
    let isEditMode: Bool
    
    let currencies = ["JPY", "USD"]
    let paymentMethods = ["クレジットカード", "デビットカード", "銀行振替", "PayPal", "その他"]
    let cycles = ["月額", "年額"]
    
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
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("金額")
                                .font(.headline)
                            TextField("", text: $amount)
                                .textFieldStyle(.roundedBorder)
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
                        }
                    }
                    
                    // 支払い方法
                    VStack(alignment: .leading, spacing: 8) {
                        Text("支払い方法")
                            .font(.headline)
                        Picker("", selection: $paymentMethod) {
                            ForEach(paymentMethods, id: \.self) { method in
                                Text(method)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
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
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct AddEditSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditSubscriptionView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
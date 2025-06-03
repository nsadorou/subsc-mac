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
    
    let currencies = ["JPY", "USD"]
    let paymentMethods = ["クレジットカード", "デビットカード", "銀行振替", "PayPal", "その他"]
    let cycles = ["月額", "年額"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("サービス名", text: $serviceName)
                    
                    HStack {
                        TextField("金額", text: $amount)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("通貨", selection: $currency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    
                    Picker("支払い方法", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.self) { method in
                            Text(method)
                        }
                    }
                    
                    DatePicker("契約開始日", selection: $startDate, displayedComponents: .date)
                    
                    Picker("更新サイクル", selection: $cycle) {
                        ForEach(0..<cycles.count, id: \.self) { index in
                            Text(cycles[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("備考") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .padding()
            .navigationTitle("サブスクリプション追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSubscription()
                    }
                    .disabled(serviceName.isEmpty || amount.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    private func saveSubscription() {
        let newSubscription = Subscription(context: viewContext)
        newSubscription.id = UUID()
        newSubscription.serviceName = serviceName
        newSubscription.amount = NSDecimalNumber(string: amount)
        newSubscription.currency = currency
        newSubscription.paymentMethod = paymentMethod
        newSubscription.notes = notes
        newSubscription.startDate = startDate
        newSubscription.cycle = Int16(cycle)
        newSubscription.isActive = true
        newSubscription.createdAt = Date()
        newSubscription.updatedAt = Date()
        
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
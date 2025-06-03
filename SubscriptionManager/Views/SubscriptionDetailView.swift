import SwiftUI

struct SubscriptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let subscription: Subscription
    
    @State private var showingDeleteAlert = false
    
    var nextRenewalDate: Date {
        guard let startDate = subscription.startDate else { return Date() }
        let calendar = Calendar.current
        
        if subscription.cycle == 0 {
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        } else {
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(subscription.serviceName ?? "Unknown")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(subscription.paymentMethod ?? "Unknown")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("¥\(subscription.amount?.intValue ?? 0)")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        
                        Text(subscription.cycle == 0 ? "月額" : "年額")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "契約開始日", value: dateFormatter.string(from: subscription.startDate ?? Date()))
                    DetailRow(label: "次回更新日", value: dateFormatter.string(from: nextRenewalDate))
                    DetailRow(label: "通貨", value: subscription.currency ?? "JPY")
                    
                    if let notes = subscription.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("備考")
                                .font(.headline)
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("詳細")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("サブスクリプションを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteSubscription()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("\(subscription.serviceName ?? "このサービス")を削除してもよろしいですか？この操作は取り消せません。")
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private func deleteSubscription() {
        viewContext.delete(subscription)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SubscriptionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.shared.viewContext
        let subscription = Subscription(context: context)
        subscription.serviceName = "Netflix"
        subscription.amount = NSDecimalNumber(value: 1980)
        subscription.currency = "JPY"
        subscription.paymentMethod = "クレジットカード"
        subscription.startDate = Date()
        subscription.cycle = 0
        
        return SubscriptionDetailView(subscription: subscription)
    }
}
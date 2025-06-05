import SwiftUI
import CoreData

struct SubscriptionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.serviceName, ascending: true)],
        animation: .default)
    private var subscriptions: FetchedResults<Subscription>
    
    @State private var showingAddSheet = false
    @State private var selection: Set<UUID> = []
    @State private var editingSubscription: Subscription?
    
    // 合計金額の計算（為替レート考慮）
    var monthlyTotal: Int {
        subscriptions
            .filter { $0.cycle == 0 && $0.isActive }
            .reduce(0) { total, subscription in
                let amount = subscription.amount?.doubleValue ?? 0
                if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
                    return total + Int(amount * rate)
                } else {
                    return total + Int(amount)
                }
            }
    }
    
    var yearlyTotal: Int {
        subscriptions
            .filter { $0.cycle == 1 && $0.isActive }
            .reduce(0) { total, subscription in
                let amount = subscription.amount?.doubleValue ?? 0
                if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
                    return total + Int(amount * rate)
                } else {
                    return total + Int(amount)
                }
            }
    }
    
    var totalPerMonth: Int {
        monthlyTotal + (yearlyTotal / 12)
    }
    
    var totalPerYear: Int {
        (monthlyTotal * 12) + yearlyTotal
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("サブスクリプション一覧")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if !selection.isEmpty {
                    Text("\(selection.count)件選択中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                
                Spacer()
                
                if selection.count == 1 {
                    Button(action: {
                        if let id = selection.first,
                           let subscription = subscriptions.first(where: { $0.id == id }) {
                            editingSubscription = subscription
                        }
                    }) {
                        Label("編集", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.return, modifiers: [])
                }
                
                if !selection.isEmpty {
                    Button(action: {
                        for id in selection {
                            if let subscription = subscriptions.first(where: { $0.id == id }) {
                                deleteSubscription(subscription)
                            }
                        }
                        selection.removeAll()
                    }) {
                        Label("選択項目を削除", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                Button(action: { showingAddSheet = true }) {
                    Label("追加", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            if subscriptions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "creditcard.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("サブスクリプションがありません")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingAddSheet = true }) {
                        Label("最初のサブスクリプションを追加", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 合計金額表示
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("月額合計")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("¥\(monthlyTotal.formatted(.number))")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("年額合計")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("¥\(yearlyTotal.formatted(.number))")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("月あたり総額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("¥\(totalPerMonth.formatted(.number))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("年あたり総額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("¥\(totalPerYear.formatted(.number))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                List(selection: $selection) {
                    ForEach(subscriptions) { subscription in
                        SubscriptionRow(subscription: subscription, editingSubscription: $editingSubscription)
                            .tag(subscription.id)
                            .contextMenu {
                                Button(action: {
                                    editingSubscription = subscription
                                }) {
                                    Label("編集", systemImage: "pencil")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    deleteSubscription(subscription)
                                }) {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: deleteSubscriptions)
                }
                .listStyle(InsetListStyle())
                .onDeleteCommand {
                    // Deleteキーが押された時の処理
                    for id in selection {
                        if let subscription = subscriptions.first(where: { $0.id == id }) {
                            deleteSubscription(subscription)
                        }
                    }
                    selection.removeAll()
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditSubscriptionView()
        }
        .sheet(item: $editingSubscription) { subscription in
            AddEditSubscriptionView(subscription: subscription)
        }
    }
    
    private func deleteSubscriptions(offsets: IndexSet) {
        withAnimation {
            offsets.map { subscriptions[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteSubscription(_ subscription: Subscription) {
        withAnimation {
            viewContext.delete(subscription)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription
    @Binding var editingSubscription: Subscription?
    @State private var isExpanded = false
    
    var nextRenewalDate: Date? {
        guard let startDate = subscription.startDate else { return nil }
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        if subscription.cycle == 0 { // monthly
            dateComponents.month = 1
        } else { // yearly
            dateComponents.year = 1
        }
        
        var nextDate = startDate
        while nextDate <= Date() {
            nextDate = calendar.date(byAdding: dateComponents, to: nextDate) ?? nextDate
        }
        
        return nextDate
    }
    
    var daysUntilRenewal: Int? {
        guard let nextDate = nextRenewalDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextDate)
        return components.day
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // サービス情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.serviceName ?? "Unknown")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Label(subscription.paymentMethod ?? "Unknown", systemImage: "creditcard")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let timings = subscription.notificationTimings, !timings.isEmpty {
                            Label("\(timings.count)件の通知", systemImage: "bell.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // 次回更新日
                if let days = daysUntilRenewal {
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(days)日後")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(days <= 7 ? .orange : .secondary)
                        
                        if let date = nextRenewalDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 金額情報
                VStack(alignment: .trailing, spacing: 4) {
                    if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
                        let usdAmount = subscription.amount?.doubleValue ?? 0
                        let jpyAmount = usdAmount * rate
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(CurrencyFormatter.shared.format(amount: usdAmount, currency: "USD"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.shared.format(amount: jpyAmount, currency: "JPY"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("@¥\(CurrencyFormatter.shared.formatExchangeRate(rate))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        let amount = subscription.amount?.doubleValue ?? 0
                        Text(CurrencyFormatter.shared.format(amount: amount, currency: subscription.currency ?? "JPY"))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(subscription.cycle == 0 ? "月額" : "年額")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 展開/折りたたみボタン
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            
            // 展開時の詳細情報
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    HStack(spacing: 20) {
                        // 契約開始日
                        VStack(alignment: .leading, spacing: 2) {
                            Text("契約開始日")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(subscription.startDate ?? Date(), style: .date)
                                .font(.caption)
                        }
                        
                        // 通知設定
                        if let timings = subscription.notificationTimings, !timings.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("通知タイミング")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    ForEach(timings.sorted(), id: \.self) { timing in
                                        Text(notificationTimingText(timing))
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // アクションボタン
                        HStack(spacing: 8) {
                            Button(action: {
                                editingSubscription = subscription
                            }) {
                                Label("編集", systemImage: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // 備考
                    if let notes = subscription.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("備考")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
        .contentShape(Rectangle())
    }
    
    private func notificationTimingText(_ timing: Int) -> String {
        switch timing {
        case 0: return "1日前"
        case 1: return "3日前"
        case 2: return "1週間前"
        case 3: return "2週間前"
        default: return ""
        }
    }
}

struct SubscriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionListView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
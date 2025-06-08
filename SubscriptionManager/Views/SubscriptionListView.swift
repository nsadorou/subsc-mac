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
    @State private var searchText = ""
    @State private var selectedPaymentMethod: String = "すべて"
    @State private var selectedCurrency: String = "すべて"
    @State private var selectedCycle: String = "すべて"
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var showingFilterSheet = false
    
    // フィルタリングされたサブスクリプション
    var filteredSubscriptions: [Subscription] {
        let filtered = subscriptions.filter { subscription in
            // 検索テキストフィルタ
            let matchesSearch = searchText.isEmpty || 
                (subscription.serviceName?.localizedCaseInsensitiveContains(searchText) == true) ||
                (subscription.notes?.localizedCaseInsensitiveContains(searchText) == true)
            
            // 支払い方法フィルタ
            let matchesPaymentMethod = selectedPaymentMethod == "すべて" || 
                subscription.paymentMethod == selectedPaymentMethod
            
            // 通貨フィルタ
            let matchesCurrency = selectedCurrency == "すべて" || 
                subscription.currency == selectedCurrency
            
            // サイクルフィルタ
            let matchesCycle = selectedCycle == "すべて" || 
                (selectedCycle == "月額" && subscription.cycle == 0) ||
                (selectedCycle == "年額" && subscription.cycle == 1)
            
            // 金額範囲フィルタ
            let matchesAmountRange: Bool = {
                guard let amount = subscription.amount?.doubleValue else { return true }
                
                // 為替レート考慮
                let jpyAmount: Double
                if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
                    jpyAmount = amount * rate
                } else {
                    jpyAmount = amount
                }
                
                let minAmountValue = Double(minAmount) ?? 0
                let maxAmountValue = Double(maxAmount) ?? Double.greatestFiniteMagnitude
                
                return jpyAmount >= minAmountValue && jpyAmount <= maxAmountValue
            }()
            
            return matchesSearch && matchesPaymentMethod && matchesCurrency && matchesCycle && matchesAmountRange
        }
        
        return Array(filtered)
    }
    
    // 合計金額の計算（フィルタリング後）
    var monthlyTotal: Int {
        filteredSubscriptions
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
        filteredSubscriptions
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
    
    // フィルタ用のオプション
    var paymentMethods: [String] {
        let methods = Set(subscriptions.compactMap { $0.paymentMethod })
        return ["すべて"] + Array(methods).sorted()
    }
    
    var currencies: [String] {
        let currencies = Set(subscriptions.compactMap { $0.currency })
        return ["すべて"] + Array(currencies).sorted()
    }
    
    var totalPerMonth: Int {
        monthlyTotal + (yearlyTotal / 12)
    }
    
    var totalPerYear: Int {
        (monthlyTotal * 12) + yearlyTotal
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
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
                .buttonStyle(PrimaryButtonStyle())
                .scaleButtonStyle()
            }
            .padding()
            
            // 検索・フィルタバー
            HStack(spacing: 12) {
                // 検索フィールド
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("サービス名や備考で検索...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .frame(maxWidth: 300)
                
                // クイックフィルタ
                Picker("サイクル", selection: $selectedCycle) {
                    Text("すべて").tag("すべて")
                    Text("月額").tag("月額")
                    Text("年額").tag("年額")
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                
                // フィルタボタン
                Button(action: { showingFilterSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("フィルタ")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .scaleButtonStyle()
                
                // フィルタ表示数
                if !searchText.isEmpty || selectedPaymentMethod != "すべて" || 
                   selectedCurrency != "すべて" || selectedCycle != "すべて" ||
                   !minAmount.isEmpty || !maxAmount.isEmpty {
                    Text("\(filteredSubscriptions.count)/\(subscriptions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // フィルタリセット
                if !searchText.isEmpty || selectedPaymentMethod != "すべて" || 
                   selectedCurrency != "すべて" || selectedCycle != "すべて" ||
                   !minAmount.isEmpty || !maxAmount.isEmpty {
                    Button("リセット") {
                        resetFilters()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
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
                    ForEach(filteredSubscriptions, id: \.id) { subscription in
                        SubscriptionRow(subscription: subscription, editingSubscription: $editingSubscription)
                            .tag(subscription.id)
                            .slideIn(from: .left)
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
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(
                selectedPaymentMethod: $selectedPaymentMethod,
                selectedCurrency: $selectedCurrency,
                minAmount: $minAmount,
                maxAmount: $maxAmount,
                paymentMethods: paymentMethods,
                currencies: currencies
            )
        }
    }
    
    private func resetFilters() {
        searchText = ""
        selectedPaymentMethod = "すべて"
        selectedCurrency = "すべて"
        selectedCycle = "すべて"
        minAmount = ""
        maxAmount = ""
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
                        let paymentMethod = subscription.paymentMethod ?? "Unknown"
                        let iconInfo = PaymentMethodIcon.getIconAndColor(for: paymentMethod)
                        Label(paymentMethod, systemImage: iconInfo.icon)
                            .font(.caption)
                            .foregroundColor(iconInfo.color)
                        
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
                    withAnimation(AnimationConstants.cardExpand) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(AnimationConstants.quickSpring, value: isExpanded)
                }
                .buttonStyle(.plain)
                .scaleButtonStyle()
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
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
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

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPaymentMethod: String
    @Binding var selectedCurrency: String
    @Binding var minAmount: String
    @Binding var maxAmount: String
    
    let paymentMethods: [String]
    let currencies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー
            HStack {
                Text("詳細フィルタ")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("完了") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            
            // 支払い方法フィルタ
            VStack(alignment: .leading, spacing: 8) {
                Text("支払い方法")
                    .font(.headline)
                
                Picker("支払い方法", selection: $selectedPaymentMethod) {
                    ForEach(paymentMethods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200, alignment: .leading)
            }
            
            // 通貨フィルタ
            VStack(alignment: .leading, spacing: 8) {
                Text("通貨")
                    .font(.headline)
                
                Picker("通貨", selection: $selectedCurrency) {
                    ForEach(currencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }
            
            // 金額範囲フィルタ
            VStack(alignment: .leading, spacing: 8) {
                Text("金額範囲（円）")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最小金額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("例: 1000", text: $minAmount)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    Text("〜")
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最大金額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("例: 5000", text: $maxAmount)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }
            }
            
            Divider()
            
            // リセットボタン
            HStack {
                Button("すべてリセット") {
                    selectedPaymentMethod = "すべて"
                    selectedCurrency = "すべて"
                    minAmount = ""
                    maxAmount = ""
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct SubscriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionListView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
import SwiftUI
import CoreData

struct SubscriptionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.serviceName, ascending: true)],
        animation: .default)
    private var subscriptions: FetchedResults<Subscription>
    
    @State private var showingAddSheet = false
    @State private var selectedSubscription: Subscription?
    @State private var selection: Set<UUID> = []
    @State private var editingSubscription: Subscription?
    
    // 合計金額の計算
    var monthlyTotal: Int {
        subscriptions
            .filter { $0.cycle == 0 && $0.isActive }
            .compactMap { $0.amount?.intValue }
            .reduce(0, +)
    }
    
    var yearlyTotal: Int {
        subscriptions
            .filter { $0.cycle == 1 && $0.isActive }
            .compactMap { $0.amount?.intValue }
            .reduce(0, +)
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
                    
                    Button(action: {
                        if let id = selection.first,
                           let subscription = subscriptions.first(where: { $0.id == id }) {
                            selectedSubscription = subscription
                        }
                    }) {
                        Label("詳細を表示", systemImage: "info.circle")
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
                        SubscriptionRow(subscription: subscription, selectedSubscription: $selectedSubscription)
                            .tag(subscription.id)
                            .contextMenu {
                                Button(action: {
                                    editingSubscription = subscription
                                }) {
                                    Label("編集", systemImage: "pencil")
                                }
                                
                                Button(action: {
                                    selectedSubscription = subscription
                                }) {
                                    Label("詳細を表示", systemImage: "info.circle")
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
        .sheet(item: $selectedSubscription) { subscription in
            SubscriptionDetailView(subscription: subscription)
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
    @Binding var selectedSubscription: Subscription?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.serviceName ?? "Unknown")
                    .font(.headline)
                
                Text(subscription.paymentMethod ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("¥\((subscription.amount?.intValue ?? 0).formatted(.number))")
                    .font(.headline)
                
                Text(subscription.cycle == 0 ? "月額" : "年額")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                selectedSubscription = subscription
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("詳細を表示")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // クリック可能領域を行全体に拡張
    }
}

struct SubscriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionListView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
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
    @State private var lastClickTime: Date?
    @State private var lastClickedID: UUID?
    
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
                List(selection: $selection) {
                    ForEach(subscriptions) { subscription in
                        SubscriptionRow(subscription: subscription)
                            .tag(subscription.id)
                            .onTapGesture {
                                let now = Date()
                                if let lastTime = lastClickTime,
                                   let lastID = lastClickedID,
                                   lastID == subscription.id,
                                   now.timeIntervalSince(lastTime) < 0.5 {
                                    // ダブルクリックと判定
                                    selectedSubscription = subscription
                                    lastClickTime = nil
                                    lastClickedID = nil
                                } else {
                                    // シングルクリック
                                    lastClickTime = now
                                    lastClickedID = subscription.id
                                }
                            }
                            .contextMenu {
                                Button(action: {
                                    deleteSubscription(subscription)
                                }) {
                                    Label("削除", systemImage: "trash")
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    selectedSubscription = subscription
                                }) {
                                    Label("詳細を表示", systemImage: "info.circle")
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
                Text("¥\(subscription.amount?.intValue ?? 0)")
                    .font(.headline)
                
                Text(subscription.cycle == 0 ? "月額" : "年額")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SubscriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionListView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
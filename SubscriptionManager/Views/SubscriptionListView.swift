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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("サブスクリプション一覧")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
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
                List {
                    ForEach(subscriptions) { subscription in
                        SubscriptionRow(subscription: subscription)
                            .onTapGesture {
                                selectedSubscription = subscription
                            }
                    }
                    .onDelete(perform: deleteSubscriptions)
                }
                .listStyle(InsetListStyle())
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
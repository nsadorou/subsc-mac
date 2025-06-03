import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("サブスクリプション", systemImage: "creditcard.circle")
                    .tag(0)
                
                Label("設定", systemImage: "gear")
                    .tag(1)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            .listStyle(SidebarListStyle())
        } detail: {
            switch selectedTab {
            case 0:
                SubscriptionListView()
            case 1:
                SettingsView()
            default:
                Text("選択してください")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
      static var previews: some View {
          ContentView()
              .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
      }
  }

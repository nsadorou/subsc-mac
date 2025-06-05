import SwiftUI
import CoreData
import UserNotifications

@main
struct SubscriptionManagerApp: App {
    let coreDataManager = CoreDataManager.shared
    let notificationManager = NotificationManager.shared
    let logger = AppLogger.shared
    
    init() {
        logger.info("SubscriptionManager app starting up")
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
                .environmentObject(coreDataManager)
                .environmentObject(notificationManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
        }
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = notificationManager
        
        // アプリ起動時に通知を更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.notificationManager.refreshAllNotifications()
        }
    }
}

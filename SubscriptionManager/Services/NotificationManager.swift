import Foundation
import UserNotifications
import CoreData

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    private let logger = AppLogger.shared
    
    private override init() {
        super.init()
        logger.info("NotificationManager initialized")
        checkNotificationPermissionStatus()
    }
    
    func refreshAllNotifications() {
        guard notificationPermissionStatus == .authorized else {
            logger.warning("Cannot refresh notifications - permission not authorized")
            return
        }
        
        logger.info("Starting notification refresh for all subscriptions")
        
        let context = CoreDataManager.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Subscription")
        request.predicate = NSPredicate(format: "isActive == true")
        
        do {
            let subscriptions = try context.fetch(request)
            logger.info("Found \(subscriptions.count) active subscriptions")
            
            for subscription in subscriptions {
                scheduleNotification(for: subscription)
            }
            
            logger.info("Notification refresh completed successfully")
        } catch {
            logger.error("Failed to fetch subscriptions for notification refresh: \(error)")
        }
    }
    
    func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
                self.logger.info("Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    func requestNotificationPermission() {
        logger.info("Requesting notification permission")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                self.logger.error("Error requesting notification permission: \(error)")
            } else {
                self.logger.info("Notification permission request completed - granted: \(granted)")
            }
            
            DispatchQueue.main.async {
                self.checkNotificationPermissionStatus()
            }
        }
    }
    
    func scheduleNotification(for subscription: NSManagedObject) {
        guard notificationPermissionStatus == .authorized else { return }
        
        guard let timingsData = subscription.value(forKey: "notificationTimings") else { return }
        let notificationTimings = (timingsData as? [Int]) ?? []
        let nextRenewalDate = calculateNextRenewalDate(for: subscription)
        let notificationTime = subscription.value(forKey: "notificationTime") as? Date ?? Date()
        
        // 既存の通知を削除
        removeAllNotifications(for: subscription)
        
        for timing in notificationTimings {
            if let notificationDate = calculateNotificationDate(renewalDate: nextRenewalDate, timing: timing, notificationTime: notificationTime) {
                createNotification(for: subscription, at: notificationDate, timing: timing)
            }
        }
    }
    
    func removeAllNotifications(for subscription: NSManagedObject) {
        guard let subscriptionId = subscription.value(forKey: "id") as? UUID else { return }
        
        let identifiers = [0, 1, 2, 3].map { "\(subscriptionId.uuidString)_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    private func calculateNextRenewalDate(for subscription: NSManagedObject) -> Date {
        let startDate = subscription.value(forKey: "startDate") as? Date ?? Date()
        let cycle = subscription.value(forKey: "cycle") as? Int16 ?? 0
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        if cycle == 0 { // monthly
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
    
    private func calculateNotificationDate(renewalDate: Date, timing: Int, notificationTime: Date) -> Date? {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        switch timing {
        case 0: // 1日前
            dateComponents.day = -1
        case 1: // 3日前
            dateComponents.day = -3
        case 2: // 1週間前
            dateComponents.day = -7
        case 3: // 2週間前
            dateComponents.day = -14
        default:
            return nil
        }
        
        guard let notificationDate = calendar.date(byAdding: dateComponents, to: renewalDate) else {
            return nil
        }
        
        // 通知時刻を設定
        let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
        return calendar.date(bySettingHour: timeComponents.hour ?? 10, minute: timeComponents.minute ?? 0, second: 0, of: notificationDate)
    }
    
    private func createNotification(for subscription: NSManagedObject, at date: Date, timing: Int) {
        guard let subscriptionId = subscription.value(forKey: "id") as? UUID,
              let serviceName = subscription.value(forKey: "serviceName") as? String,
              let amount = subscription.value(forKey: "amount") as? NSDecimalNumber,
              let currency = subscription.value(forKey: "currency") as? String else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "サブスクリプション更新のお知らせ"
        
        let timingText = getTimingText(timing: timing)
        content.body = "\(serviceName)が\(timingText)に更新されます。金額: \(formatCurrency(amount: amount, currency: currency))"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(subscriptionId.uuidString)_\(timing)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func getTimingText(timing: Int) -> String {
        switch timing {
        case 0: return "明日"
        case 1: return "3日後"
        case 2: return "1週間後"
        case 3: return "2週間後"
        default: return "まもなく"
        }
    }
    
    private func formatCurrency(amount: NSDecimalNumber, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount) ?? ""
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
import CoreData
import Combine

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    private let containerName = "SubscriptionManager"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data failed to load: \(error.localizedDescription)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Failed to save context: \(nsError.localizedDescription)")
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func createSubscription(
        serviceName: String,
        amount: Decimal,
        currency: String,
        paymentMethod: String,
        notes: String?,
        startDate: Date,
        cycle: Int16,
        exchangeRate: Decimal? = nil
    ) -> Subscription {
        let subscription = Subscription(context: viewContext)
        subscription.id = UUID()
        subscription.serviceName = serviceName
        subscription.amount = NSDecimalNumber(decimal: amount)
        subscription.currency = currency
        subscription.paymentMethod = paymentMethod
        subscription.notes = notes
        subscription.startDate = startDate
        subscription.cycle = cycle
        subscription.exchangeRate = exchangeRate.map { NSDecimalNumber(decimal: $0) }
        subscription.isActive = true
        subscription.createdAt = Date()
        subscription.updatedAt = Date()
        
        save()
        
        return subscription
    }
    
    func updateSubscription(
        _ subscription: Subscription,
        serviceName: String? = nil,
        amount: Decimal? = nil,
        currency: String? = nil,
        paymentMethod: String? = nil,
        notes: String? = nil,
        startDate: Date? = nil,
        cycle: Int16? = nil,
        isActive: Bool? = nil
    ) {
        if let serviceName = serviceName {
            subscription.serviceName = serviceName
        }
        if let amount = amount {
            subscription.amount = NSDecimalNumber(decimal: amount)
        }
        if let currency = currency {
            subscription.currency = currency
        }
        if let paymentMethod = paymentMethod {
            subscription.paymentMethod = paymentMethod
        }
        if notes != nil {
            subscription.notes = notes
        }
        if let startDate = startDate {
            subscription.startDate = startDate
        }
        if let cycle = cycle {
            subscription.cycle = cycle
        }
        if let isActive = isActive {
            subscription.isActive = isActive
        }
        
        subscription.updatedAt = Date()
        
        save()
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        viewContext.delete(subscription)
        save()
    }
    
    func fetchAllSubscriptions() -> [Subscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.serviceName, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch subscriptions: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchActiveSubscriptions() -> [Subscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subscription.serviceName, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch active subscriptions: \(error.localizedDescription)")
            return []
        }
    }
    
    func calculateMonthlyTotal() -> Decimal {
        let subscriptions = fetchActiveSubscriptions()
        
        return subscriptions.reduce(Decimal(0)) { total, subscription in
            guard let amount = subscription.amount as? Decimal else { return total }
            
            if subscription.cycle == 0 {
                return total + amount
            } else {
                return total + (amount / 12)
            }
        }
    }
    
    func calculateYearlyTotal() -> Decimal {
        let subscriptions = fetchActiveSubscriptions()
        
        return subscriptions.reduce(Decimal(0)) { total, subscription in
            guard let amount = subscription.amount as? Decimal else { return total }
            
            if subscription.cycle == 0 {
                return total + (amount * 12)
            } else {
                return total + amount
            }
        }
    }
}
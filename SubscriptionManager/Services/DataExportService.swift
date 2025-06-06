//
//  DataExportService.swift
//  SubscriptionManager
//
//  Created on 2025/01/05.
//

import Foundation
import CoreData
import UniformTypeIdentifiers

class DataExportService {
    static let shared = DataExportService()
    
    private init() {}
    
    // MARK: - CSV Export
    
    func exportToCSV(subscriptions: [Subscription]) -> URL? {
        let csvContent = generateCSVContent(from: subscriptions)
        return saveCSVToFile(content: csvContent)
    }
    
    private func generateCSVContent(from subscriptions: [Subscription]) -> String {
        var csvLines: [String] = []
        
        // ヘッダー行
        let headers = [
            "サービス名",
            "金額",
            "通貨",
            "日本円換算",
            "為替レート",
            "支払い方法",
            "更新サイクル",
            "契約開始日",
            "次回更新日",
            "通知設定",
            "ステータス",
            "備考",
            "作成日",
            "更新日"
        ]
        csvLines.append(formatCSVRow(headers))
        
        // データ行
        for subscription in subscriptions {
            let row = [
                subscription.serviceName ?? "",
                String(subscription.amount?.doubleValue ?? 0),
                subscription.currency ?? "",
                formatJPYAmount(subscription),
                formatExchangeRate(subscription),
                subscription.paymentMethod ?? "",
                subscription.cycle == 0 ? "月額" : "年額",
                formatDate(subscription.startDate),
                formatDate(calculateNextRenewalDate(subscription)),
                formatNotificationSettings(subscription),
                subscription.isActive ? "有効" : "無効",
                subscription.notes ?? "",
                formatDate(subscription.createdAt),
                formatDate(subscription.updatedAt)
            ]
            csvLines.append(formatCSVRow(row))
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    private func formatCSVRow(_ fields: [String]) -> String {
        return fields.map { field in
            // カンマやダブルクォートを含む場合はエスケープ
            if field.contains(",") || field.contains("\"") || field.contains("\n") {
                let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escapedField)\""
            }
            return field
        }.joined(separator: ",")
    }
    
    private func formatJPYAmount(_ subscription: Subscription) -> String {
        guard let amount = subscription.amount?.doubleValue else { return "0" }
        
        if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
            let jpyAmount = amount * rate
            return String(format: "%.0f", jpyAmount)
        } else {
            return String(format: "%.0f", amount)
        }
    }
    
    private func formatExchangeRate(_ subscription: Subscription) -> String {
        if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
            return String(format: "%.2f", rate)
        }
        return ""
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func calculateNextRenewalDate(_ subscription: Subscription) -> Date? {
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
            guard let newDate = calendar.date(byAdding: dateComponents, to: nextDate) else { break }
            nextDate = newDate
        }
        
        return nextDate
    }
    
    private func formatNotificationSettings(_ subscription: Subscription) -> String {
        guard let timings = subscription.notificationTimings, !timings.isEmpty else {
            return "なし"
        }
        
        let timingTexts = timings.compactMap { timing in
            switch timing {
            case 0: return "1日前"
            case 1: return "3日前"
            case 2: return "1週間前"
            case 3: return "2週間前"
            default: return nil
            }
        }
        
        return timingTexts.joined(separator: ", ")
    }
    
    private func saveCSVToFile(content: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "subscription_export_\(timestamp).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            AppLogger.shared.info("CSV exported to: \(fileURL.path)")
            return fileURL
        } catch {
            AppLogger.shared.error("Failed to export CSV: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - JSON Export
    
    func exportToJSON(subscriptions: [Subscription]) -> URL? {
        let jsonData = generateJSONData(from: subscriptions)
        return saveJSONToFile(data: jsonData)
    }
    
    private func generateJSONData(from subscriptions: [Subscription]) -> Data? {
        let exportData = subscriptions.map { subscription in
            return [
                "id": subscription.id?.uuidString ?? "",
                "serviceName": subscription.serviceName ?? "",
                "amount": subscription.amount?.doubleValue ?? 0,
                "currency": subscription.currency ?? "",
                "exchangeRate": subscription.exchangeRate?.doubleValue,
                "paymentMethod": subscription.paymentMethod ?? "",
                "cycle": subscription.cycle,
                "startDate": subscription.startDate?.timeIntervalSince1970 ?? 0,
                "notificationTimings": subscription.notificationTimings ?? [],
                "notificationTime": subscription.notificationTime?.timeIntervalSince1970,
                "isActive": subscription.isActive,
                "notes": subscription.notes ?? "",
                "createdAt": subscription.createdAt?.timeIntervalSince1970 ?? 0,
                "updatedAt": subscription.updatedAt?.timeIntervalSince1970 ?? 0
            ] as [String: Any]
        }
        
        let jsonObject = [
            "exportDate": Date().timeIntervalSince1970,
            "version": "1.0",
            "subscriptions": exportData
        ] as [String: Any]
        
        do {
            return try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        } catch {
            AppLogger.shared.error("Failed to generate JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveJSONToFile(data: Data?) -> URL? {
        guard let data = data else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "subscription_export_\(timestamp).json"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            AppLogger.shared.info("JSON exported to: \(fileURL.path)")
            return fileURL
        } catch {
            AppLogger.shared.error("Failed to export JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Import Functions
    
    func importFromJSON(url: URL, context: NSManagedObjectContext) -> (success: Int, errors: [String]) {
        var successCount = 0
        var errors: [String] = []
        
        do {
            let data = try Data(contentsOf: url)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let rootDict = jsonObject as? [String: Any],
                  let subscriptions = rootDict["subscriptions"] as? [[String: Any]] else {
                errors.append("無効なJSONファイル形式です")
                return (0, errors)
            }
            
            for (index, subscriptionData) in subscriptions.enumerated() {
                do {
                    let subscription = Subscription(context: context)
                    
                    subscription.id = UUID(uuidString: subscriptionData["id"] as? String ?? "") ?? UUID()
                    subscription.serviceName = subscriptionData["serviceName"] as? String ?? ""
                    subscription.amount = NSDecimalNumber(value: subscriptionData["amount"] as? Double ?? 0)
                    subscription.currency = subscriptionData["currency"] as? String ?? "JPY"
                    
                    if let exchangeRate = subscriptionData["exchangeRate"] as? Double {
                        subscription.exchangeRate = NSDecimalNumber(value: exchangeRate)
                    }
                    
                    subscription.paymentMethod = subscriptionData["paymentMethod"] as? String ?? ""
                    subscription.cycle = Int16(subscriptionData["cycle"] as? Int ?? 0)
                    
                    if let startDateTimestamp = subscriptionData["startDate"] as? Double {
                        subscription.startDate = Date(timeIntervalSince1970: startDateTimestamp)
                    }
                    
                    subscription.notificationTimings = subscriptionData["notificationTimings"] as? [Int]
                    
                    if let notificationTimeTimestamp = subscriptionData["notificationTime"] as? Double {
                        subscription.notificationTime = Date(timeIntervalSince1970: notificationTimeTimestamp)
                    }
                    
                    subscription.isActive = subscriptionData["isActive"] as? Bool ?? true
                    subscription.notes = subscriptionData["notes"] as? String ?? ""
                    
                    if let createdAtTimestamp = subscriptionData["createdAt"] as? Double {
                        subscription.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                    } else {
                        subscription.createdAt = Date()
                    }
                    
                    subscription.updatedAt = Date()
                    
                    successCount += 1
                    
                } catch {
                    errors.append("項目 \(index + 1): \(error.localizedDescription)")
                }
            }
            
            try context.save()
            AppLogger.shared.info("Imported \(successCount) subscriptions from JSON")
            
        } catch {
            errors.append("ファイル読み込みエラー: \(error.localizedDescription)")
        }
        
        return (successCount, errors)
    }
}
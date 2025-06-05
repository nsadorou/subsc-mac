//
//  CurrencyFormatter.swift
//  SubscriptionManager
//
//  Created on 2025/01/05.
//

import Foundation

class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    
    private let jpyFormatter: NumberFormatter
    private let usdFormatter: NumberFormatter
    private let numberFormatter: NumberFormatter
    
    private init() {
        // 日本円フォーマッター
        jpyFormatter = NumberFormatter()
        jpyFormatter.numberStyle = .currency
        jpyFormatter.currencyCode = "JPY"
        jpyFormatter.locale = Locale(identifier: "ja_JP")
        jpyFormatter.maximumFractionDigits = 0
        
        // USドルフォーマッター
        usdFormatter = NumberFormatter()
        usdFormatter.numberStyle = .currency
        usdFormatter.currencyCode = "USD"
        usdFormatter.locale = Locale(identifier: "en_US")
        usdFormatter.maximumFractionDigits = 2
        
        // 通常の数値フォーマッター
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
    }
    
    // MARK: - Public Methods
    
    func format(amount: Double, currency: String) -> String {
        let formatter = getFormatter(for: currency)
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    func format(amount: Decimal, currency: String) -> String {
        let formatter = getFormatter(for: currency)
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
    
    func formatWithConversion(amount: Double, fromCurrency: String, toCurrency: String, exchangeRate: Double) -> String {
        if fromCurrency == toCurrency {
            return format(amount: amount, currency: fromCurrency)
        }
        
        let convertedAmount = amount * exchangeRate
        let originalFormatted = format(amount: amount, currency: fromCurrency)
        let convertedFormatted = format(amount: convertedAmount, currency: toCurrency)
        
        return "\(originalFormatted) (\(convertedFormatted))"
    }
    
    func parseAmount(from string: String, currency: String) -> Double? {
        // 通貨記号や区切り文字を除去
        let cleanedString = string
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        return Double(cleanedString)
    }
    
    // MARK: - Private Methods
    
    private func getFormatter(for currency: String) -> NumberFormatter {
        switch currency.uppercased() {
        case "JPY":
            return jpyFormatter
        case "USD":
            return usdFormatter
        default:
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            return formatter
        }
    }
    
    // MARK: - Utility Methods
    
    func getCurrencySymbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "JPY":
            return "¥"
        case "USD":
            return "$"
        default:
            return currency
        }
    }
    
    func formatExchangeRate(_ rate: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: rate)) ?? "\(rate)"
    }
    
    func formatWithRate(amount: Double, currency: String, rate: Double?) -> String {
        var result = format(amount: amount, currency: currency)
        
        if let rate = rate, currency == "USD" {
            let jpyAmount = amount * rate
            let jpyFormatted = format(amount: jpyAmount, currency: "JPY")
            result += " (\(jpyFormatted) @ ¥\(formatExchangeRate(rate)))"
        }
        
        return result
    }
}
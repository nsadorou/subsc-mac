//
//  PaymentMethodHelper.swift
//  SubscriptionManager
//
//  Created on 2025/01/08.
//

import SwiftUI

// MARK: - Payment Method Icon Mapper
struct PaymentMethodIcon {
    static func getIconAndColor(for method: String) -> (icon: String, color: Color) {
        let lowercased = method.lowercased()
        
        // 特定のサービス/ブランド
        if lowercased.contains("楽天") {
            return ("creditcard.fill", Color.red)
        } else if lowercased.contains("visa") {
            return ("creditcard", Color.blue)
        } else if lowercased.contains("mastercard") || lowercased.contains("master") {
            return ("creditcard", Color.orange)
        } else if lowercased.contains("jcb") {
            return ("creditcard", Color.green)
        } else if lowercased.contains("amex") || lowercased.contains("american express") {
            return ("creditcard", Color.indigo)
        }
        
        // QRコード決済
        else if lowercased.contains("paypay") {
            return ("qrcode", Color.red)
        } else if lowercased.contains("line pay") || lowercased.contains("linepay") {
            return ("qrcode", Color.green)
        } else if lowercased.contains("メルペイ") || lowercased.contains("merpay") {
            return ("qrcode", Color.blue)
        } else if lowercased.contains("d払い") || lowercased.contains("d payment") {
            return ("qrcode", Color.red)
        } else if lowercased.contains("au pay") || lowercased.contains("aupay") {
            return ("qrcode", Color.orange)
        }
        
        // 銀行
        else if lowercased.contains("銀行") || lowercased.contains("bank") {
            return ("building.columns", Color.green)
        } else if lowercased.contains("ゆうちょ") || lowercased.contains("郵便") {
            return ("envelope", Color.green)
        }
        
        // 電子マネー
        else if lowercased.contains("suica") || lowercased.contains("pasmo") {
            return ("tram", Color.green)
        } else if lowercased.contains("nanaco") {
            return ("creditcard.circle", Color.orange)
        } else if lowercased.contains("waon") {
            return ("creditcard.circle", Color.purple)
        } else if lowercased.contains("edy") {
            return ("creditcard.circle", Color.blue)
        }
        
        // その他
        else if lowercased.contains("現金") || lowercased.contains("cash") {
            return ("yensign.circle", Color.brown)
        } else if lowercased.contains("振込") || lowercased.contains("transfer") {
            return ("arrow.right.arrow.left", Color.blue)
        } else if lowercased.contains("引き落とし") || lowercased.contains("口座") {
            return ("building.columns.circle", Color.green)
        }
        
        // デフォルト（カード系の言葉が含まれる場合）
        else if lowercased.contains("カード") || lowercased.contains("card") {
            return ("creditcard", Color.gray)
        }
        
        // 完全にデフォルト
        return ("banknote", Color.gray)
    }
}

// MARK: - Payment Method Learning
class PaymentMethodLearning: ObservableObject {
    static let shared = PaymentMethodLearning()
    
    private let historyKey = "PaymentMethodHistory"
    private let maxHistory = 20
    
    @Published var recentMethods: [String] = []
    @Published var registeredMethods: [String] = []
    
    init() {
        loadHistory()
    }
    
    private func loadHistory() {
        recentMethods = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    }
    
    func updateRegisteredMethods(from subscriptions: [Subscription]) {
        let methods = subscriptions.compactMap { $0.paymentMethod }
            .filter { !$0.isEmpty }
        
        // 重複を削除してソート
        let uniqueMethods = Array(Set(methods)).sorted()
        
        DispatchQueue.main.async {
            self.registeredMethods = uniqueMethods
        }
    }
    
    func addToHistory(_ method: String) {
        guard !method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        var history = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        
        // 既存の項目を削除（重複回避）
        history.removeAll { $0 == method }
        
        // 先頭に追加
        history.insert(method, at: 0)
        
        // 最大数を制限
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }
        
        UserDefaults.standard.set(history, forKey: historyKey)
        
        // Publishedプロパティを更新
        DispatchQueue.main.async {
            self.recentMethods = history
        }
    }
    
    func getSuggestions(for query: String, includePresets: Bool = true, includeRegistered: Bool = true) -> [String] {
        var suggestions: [String] = []
        var addedMethods = Set<String>()
        
        // 登録済みの支払い方法を優先
        if includeRegistered {
            let registeredSuggestions = registeredMethods.filter { method in
                query.isEmpty || method.localizedCaseInsensitiveContains(query)
            }
            for method in registeredSuggestions {
                if addedMethods.insert(method).inserted {
                    suggestions.append(method)
                }
            }
        }
        
        // 履歴から検索
        let historySuggestions = recentMethods.filter { method in
            query.isEmpty || method.localizedCaseInsensitiveContains(query)
        }
        for method in historySuggestions {
            if addedMethods.insert(method).inserted {
                suggestions.append(method)
            }
        }
        
        // プリセットを追加
        if includePresets {
            let presetSuggestions = PaymentMethodPresets.allMethods.filter { preset in
                query.isEmpty || preset.localizedCaseInsensitiveContains(query)
            }
            for preset in presetSuggestions {
                if addedMethods.insert(preset).inserted {
                    suggestions.append(preset)
                }
            }
        }
        
        // 最大10件に制限
        return Array(suggestions.prefix(10))
    }
}

// MARK: - Payment Method Presets
struct PaymentMethodPresets {
    static let creditCards = [
        "楽天カード",
        "三井住友VISAカード",
        "JCBカード",
        "三菱UFJカード",
        "イオンカード",
        "dカード",
        "セゾンカード",
        "エポスカード",
        "ビューカード",
        "アメリカン・エキスプレス"
    ]
    
    static let qrPayments = [
        "PayPay",
        "LINE Pay",
        "楽天ペイ",
        "d払い",
        "au PAY",
        "メルペイ"
    ]
    
    static let banks = [
        "三菱UFJ銀行",
        "三井住友銀行",
        "みずほ銀行",
        "ゆうちょ銀行",
        "楽天銀行",
        "住信SBIネット銀行",
        "PayPay銀行"
    ]
    
    static let eMoney = [
        "Suica",
        "PASMO",
        "nanaco",
        "WAON",
        "楽天Edy"
    ]
    
    static let others = [
        "現金",
        "銀行振込",
        "口座引き落とし",
        "コンビニ払い",
        "その他"
    ]
    
    static let allMethods: [String] = {
        var all: [String] = []
        all.append(contentsOf: creditCards)
        all.append(contentsOf: qrPayments)
        all.append(contentsOf: banks)
        all.append(contentsOf: eMoney)
        all.append(contentsOf: others)
        return all
    }()
}

// MARK: - Smart Payment Method Field
struct SmartPaymentMethodField: View {
    @Binding var paymentMethod: String
    @StateObject private var learning = PaymentMethodLearning.shared
    @State private var showingSuggestions = false
    @State private var selectedIndex = -1
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.paymentMethod, ascending: true)],
        animation: .default)
    private var subscriptions: FetchedResults<Subscription>
    
    var suggestions: [String] {
        learning.getSuggestions(for: paymentMethod)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 入力フィールド
            HStack {
                // アイコン表示
                let iconInfo = PaymentMethodIcon.getIconAndColor(for: paymentMethod)
                Image(systemName: iconInfo.icon)
                    .foregroundColor(iconInfo.color)
                    .frame(width: 20)
                
                TextField("支払い方法（例：楽天カードVISA）", text: $paymentMethod, onEditingChanged: { editing in
                    showingSuggestions = editing && !suggestions.isEmpty
                })
                .textFieldStyle(.plain)
                .onSubmit {
                    if !paymentMethod.isEmpty {
                        learning.addToHistory(paymentMethod)
                    }
                    showingSuggestions = false
                }
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            
            // 候補リスト
            if showingSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // セクションヘッダー付きで表示
                    if !learning.registeredMethods.isEmpty && suggestions.contains(where: { learning.registeredMethods.contains($0) }) {
                        Text("登録済みの支払い方法")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.separatorColor).opacity(0.1))
                    }
                    
                    ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                        PaymentMethodSuggestionRow(
                            suggestion: suggestion,
                            isSelected: index == selectedIndex,
                            isRegistered: learning.registeredMethods.contains(suggestion)
                        ) {
                            paymentMethod = suggestion
                            showingSuggestions = false
                            learning.addToHistory(suggestion)
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                .padding(.top, 2)
            }
            
            // 登録済みまたは最近使用した支払い方法（最初の入力時のみ表示）
            if paymentMethod.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // 登録済みの支払い方法
                    if !learning.registeredMethods.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("登録済みの支払い方法")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(learning.registeredMethods.prefix(5), id: \.self) { method in
                                        PaymentMethodChip(method: method, isRegistered: true) {
                                            paymentMethod = method
                                            learning.addToHistory(method)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // 最近使用した支払い方法
                    if !learning.recentMethods.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("最近使用した支払い方法")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(learning.recentMethods.prefix(5), id: \.self) { method in
                                        if !learning.registeredMethods.contains(method) {
                                            PaymentMethodChip(method: method, isRegistered: false) {
                                                paymentMethod = method
                                                learning.addToHistory(method)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            learning.updateRegisteredMethods(from: Array(subscriptions))
        }
        .onChange(of: subscriptions.count) { _ in
            learning.updateRegisteredMethods(from: Array(subscriptions))
        }
    }
}

// MARK: - Supporting Views
struct PaymentMethodSuggestionRow: View {
    let suggestion: String
    let isSelected: Bool
    let isRegistered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                let iconInfo = PaymentMethodIcon.getIconAndColor(for: suggestion)
                Image(systemName: iconInfo.icon)
                    .foregroundColor(iconInfo.color)
                    .frame(width: 20)
                
                Text(suggestion)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isRegistered {
                    Text("登録済み")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct PaymentMethodChip: View {
    let method: String
    var isRegistered: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                let iconInfo = PaymentMethodIcon.getIconAndColor(for: method)
                Image(systemName: iconInfo.icon)
                    .font(.caption)
                    .foregroundColor(iconInfo.color)
                Text(method)
                    .font(.caption)
                    .lineLimit(1)
                
                if isRegistered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isRegistered ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isRegistered ? Color.accentColor.opacity(0.3) : Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(method + (isRegistered ? " (登録済み)" : "")) // ツールチップ
    }
}
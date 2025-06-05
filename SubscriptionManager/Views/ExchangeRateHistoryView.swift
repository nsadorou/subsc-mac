//
//  ExchangeRateHistoryView.swift
//  SubscriptionManager
//
//  Created on 2025/01/05.
//

import SwiftUI

struct ExchangeRateHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var exchangeRateService = ExchangeRateService.shared
    @State private var cachedRates: [CachedExchangeRate] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Text("為替レート履歴")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("更新") {
                        refreshRates()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("キャッシュクリア") {
                        clearCache()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                    
                    Button("閉じる") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.escape)
                }
            }
            
            // 現在の為替レート
            VStack(alignment: .leading, spacing: 8) {
                Text("現在の為替レート")
                    .font(.headline)
                
                HStack {
                    if exchangeRateService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("取得中...")
                            .foregroundColor(.secondary)
                    } else if let currentRate = exchangeRateService.currentRate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("USD → JPY")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("¥\(CurrencyFormatter.shared.formatExchangeRate(currentRate))")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Text("レートを取得できませんでした")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
            
            // キャッシュされた履歴
            VStack(alignment: .leading, spacing: 8) {
                Text("キャッシュ履歴")
                    .font(.headline)
                
                if cachedRates.isEmpty {
                    Text("履歴がありません")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(cachedRates.indices, id: \.self) { index in
                                let rate = cachedRates[index]
                                ExchangeRateHistoryRow(rate: rate)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 300)
                }
            }
            
            if let error = exchangeRateService.error {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("エラー")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCachedRates()
            refreshCurrentRate()
        }
    }
    
    private func loadCachedRates() {
        cachedRates = exchangeRateService.getCachedRates()
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private func refreshCurrentRate() {
        exchangeRateService.getExchangeRate(from: "USD", to: "JPY") { result in
            DispatchQueue.main.async {
                loadCachedRates()
            }
        }
    }
    
    private func refreshRates() {
        refreshCurrentRate()
    }
    
    private func clearCache() {
        exchangeRateService.clearCache()
        cachedRates.removeAll()
    }
}

struct ExchangeRateHistoryRow: View {
    let rate: CachedExchangeRate
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: rate.timestamp, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(rate.baseCurrency) → \(rate.targetCurrency)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("¥\(CurrencyFormatter.shared.formatExchangeRate(rate.rate))")
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(rate.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct ExchangeRateHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeRateHistoryView()
    }
}
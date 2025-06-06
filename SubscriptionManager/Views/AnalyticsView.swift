//
//  AnalyticsView.swift
//  SubscriptionManager
//
//  Created on 2025/01/05.
//

import SwiftUI
import CoreData
import Charts

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.serviceName, ascending: true)],
        animation: .default)
    private var subscriptions: FetchedResults<Subscription>
    
    @State private var selectedTimeFrame: TimeFrame = .yearly
    @State private var selectedAnalysisType: AnalysisType = .spending
    
    enum TimeFrame: String, CaseIterable {
        case monthly = "月次"
        case yearly = "年次"
    }
    
    enum AnalysisType: String, CaseIterable {
        case spending = "支出分析"
        case category = "カテゴリ別"
        case timeline = "時系列"
    }
    
    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }
    
    var totalMonthlySpending: Double {
        activeSubscriptions.reduce(0) { total, subscription in
            let amount = subscription.amount?.doubleValue ?? 0
            let jpyAmount: Double
            
            if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
                jpyAmount = amount * rate
            } else {
                jpyAmount = amount
            }
            
            if subscription.cycle == 0 { // monthly
                return total + jpyAmount
            } else { // yearly
                return total + (jpyAmount / 12)
            }
        }
    }
    
    var totalYearlySpending: Double {
        return totalMonthlySpending * 12
    }
    
    var spendingByCategory: [(category: String, amount: Double)] {
        let categoryAmounts = Dictionary(grouping: activeSubscriptions) { subscription in
            subscription.paymentMethod ?? "その他"
        }.mapValues { subscriptions in
            subscriptions.reduce(0.0) { total, subscription in
                let amount = subscription.amount?.doubleValue ?? 0
                let jpyAmount: Double
                
                if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
                    jpyAmount = amount * rate
                } else {
                    jpyAmount = amount
                }
                
                if subscription.cycle == 0 { // monthly
                    return total + jpyAmount
                } else { // yearly
                    return total + (jpyAmount / 12)
                }
            }
        }
        
        return categoryAmounts.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var monthlySpendingData: [MonthlySpendingData] {
        let calendar = Calendar.current
        let now = Date()
        var data: [MonthlySpendingData] = []
        
        // 過去12か月のデータを生成
        for i in (0..<12).reversed() {
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let monthName = DateFormatter.monthFormatter.string(from: date)
            
            // その月にアクティブだったサブスクリプションの合計を計算
            var monthlyTotal = 0.0
            
            for subscription in activeSubscriptions {
                guard let startDate = subscription.startDate else { continue }
                
                // その月にサブスクリプションがアクティブだったかチェック
                if startDate <= date {
                    let amount = subscription.amount?.doubleValue ?? 0
                    let jpyAmount: Double
                    
                    if subscription.currency == "USD", let rate = subscription.exchangeRate?.doubleValue {
                        jpyAmount = amount * rate
                    } else {
                        jpyAmount = amount
                    }
                    
                    if subscription.cycle == 0 { // monthly
                        monthlyTotal += jpyAmount
                    } else if subscription.cycle == 1 { // yearly
                        // 年額の場合、開始月か毎年の同じ月に課金
                        let yearComponent = calendar.component(.year, from: date)
                        let monthComponent = calendar.component(.month, from: date)
                        let startYearComponent = calendar.component(.year, from: startDate)
                        let startMonthComponent = calendar.component(.month, from: startDate)
                        
                        if monthComponent == startMonthComponent && yearComponent >= startYearComponent {
                            monthlyTotal += jpyAmount
                        }
                    }
                }
            }
            
            data.append(MonthlySpendingData(month: monthName, amount: monthlyTotal))
        }
        
        return data
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("支出分析")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Picker("分析タイプ", selection: $selectedAnalysisType) {
                        ForEach(AnalysisType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    
                    Picker("期間", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // サマリーカード
                    summaryCards
                    
                    // メインコンテンツ
                    switch selectedAnalysisType {
                    case .spending:
                        spendingAnalysisView
                    case .category:
                        categoryAnalysisView
                    case .timeline:
                        timelineAnalysisView
                    }
                }
                .padding()
            }
        }
    }
    
    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "月額総額",
                value: "¥\(Int(totalMonthlySpending).formatted(.number))",
                icon: "calendar",
                color: .blue
            )
            
            SummaryCard(
                title: "年額総額",
                value: "¥\(Int(totalYearlySpending).formatted(.number))",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            SummaryCard(
                title: "アクティブ",
                value: "\(activeSubscriptions.count)件",
                icon: "checkmark.circle",
                color: .orange
            )
            
            SummaryCard(
                title: "平均月額",
                value: "¥\(Int(totalMonthlySpending / max(1, Double(activeSubscriptions.count))).formatted(.number))",
                icon: "chart.bar",
                color: .purple
            )
        }
    }
    
    private var spendingAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支出の内訳")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 円グラフ（簡易版）
            if !activeSubscriptions.isEmpty {
                PieChartView(data: spendingByCategory.prefix(5).map { (label: $0.category, value: $0.amount) })
                    .frame(height: 300)
                    .cardStyle()
            }
            
            // 詳細リスト
            VStack(alignment: .leading, spacing: 8) {
                Text("詳細")
                    .font(.headline)
                
                ForEach(spendingByCategory.prefix(10), id: \.category) { item in
                    HStack {
                        Text(item.category)
                            .font(.body)
                        Spacer()
                        Text("¥\(Int(item.amount).formatted(.number))")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("(\(Int(item.amount / totalMonthlySpending * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .cardStyle()
            .padding()
        }
    }
    
    private var categoryAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カテゴリ別分析")
                .font(.title2)
                .fontWeight(.semibold)
            
            // バーチャート（簡易版）
            BarChartView(data: spendingByCategory.prefix(8).map { (label: $0.category, value: $0.amount) })
                .frame(height: 300)
                .cardStyle()
        }
    }
    
    private var timelineAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("時系列分析")
                .font(.title2)
                .fontWeight(.semibold)
            
            // ラインチャート（簡易版）
            LineChartView(data: monthlySpendingData)
                .frame(height: 300)
                .cardStyle()
            
            // 統計情報
            HStack(spacing: 20) {
                StatCard(title: "最高額", value: "¥\(Int(monthlySpendingData.map(\.amount).max() ?? 0).formatted(.number))")
                StatCard(title: "最低額", value: "¥\(Int(monthlySpendingData.map(\.amount).min() ?? 0).formatted(.number))")
                StatCard(title: "平均額", value: "¥\(Int(monthlySpendingData.map(\.amount).reduce(0, +) / max(1, Double(monthlySpendingData.count))).formatted(.number))")
            }
        }
    }
}

// MARK: - Data Models
struct MonthlySpendingData {
    let month: String
    let amount: Double
}

// MARK: - Supporting Views
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .cardStyle()
        .frame(maxWidth: .infinity)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .cardStyle()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Simple Charts
struct PieChartView: View {
    let data: [(label: String, value: Double)]
    
    var body: some View {
        VStack {
            Text("支払い方法別支出")
                .font(.headline)
                .padding()
            
            HStack {
                // 簡易円グラフ（色付きの円）
                ZStack {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        let startAngle = data.prefix(index).reduce(0) { $0 + $1.value } / data.reduce(0) { $0 + $1.value } * 360
                        let endAngle = data.prefix(index + 1).reduce(0) { $0 + $1.value } / data.reduce(0) { $0 + $1.value } * 360
                        
                        PieSlice(startAngle: startAngle, endAngle: endAngle)
                            .fill(Color.accentColor.opacity(0.8 - Double(index) * 0.15))
                    }
                }
                .frame(width: 150, height: 150)
                
                // 凡例
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.8 - Double(index) * 0.15))
                                .frame(width: 12, height: 12)
                            Text(item.label)
                                .font(.caption)
                            Spacer()
                            Text("¥\(Int(item.value).formatted(.number))")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle - 90),
            endAngle: .degrees(endAngle - 90),
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

struct BarChartView: View {
    let data: [(label: String, value: Double)]
    
    var body: some View {
        VStack {
            Text("カテゴリ別支出")
                .font(.headline)
                .padding()
            
            if !data.isEmpty {
                let maxValue = data.map(\.value).max() ?? 1
                
                VStack(spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text(item.label)
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack {
                                    Rectangle()
                                        .fill(Color.accentColor.opacity(0.8))
                                        .frame(width: CGFloat(item.value / maxValue) * geometry.size.width)
                                        .animation(.easeInOut(duration: 1.0), value: item.value)
                                    
                                    Spacer(minLength: 0)
                                }
                            }
                            .frame(height: 20)
                            
                            Text("¥\(Int(item.value).formatted(.number))")
                                .font(.caption)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct LineChartView: View {
    let data: [MonthlySpendingData]
    
    var body: some View {
        VStack {
            Text("月次支出推移")
                .font(.headline)
                .padding()
            
            if !data.isEmpty {
                let maxValue = data.map(\.amount).max() ?? 1
                
                GeometryReader { geometry in
                    let stepX = geometry.size.width / CGFloat(max(1, data.count - 1))
                    
                    ZStack {
                        // グリッド線
                        ForEach(0..<5) { i in
                            let y = geometry.size.height * CGFloat(i) / 4
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                            }
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        }
                        
                        // データライン
                        Path { path in
                            for (index, item) in data.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = geometry.size.height - (CGFloat(item.amount / maxValue) * geometry.size.height)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        
                        // データポイント
                        ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                            let x = CGFloat(index) * stepX
                            let y = geometry.size.height - (CGFloat(item.amount / maxValue) * geometry.size.height)
                            
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 200)
                .padding()
                
                // X軸ラベル
                HStack {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        if index % 3 == 0 { // 3か月おきに表示
                            Text(item.month)
                                .font(.caption2)
                                .frame(maxWidth: .infinity)
                        } else {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
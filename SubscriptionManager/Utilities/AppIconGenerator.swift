//
//  AppIconGenerator.swift
//  SubscriptionManager
//
//  Created on 2025/01/08.
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // 背景のグラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),  // 濃い青
                    Color(red: 0.3, green: 0.6, blue: 1.0)   // 明るい青
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // クレジットカードスタック
                ZStack {
                    // 背面のカード
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 50, height: 32)
                        .offset(x: 4, y: 4)
                    
                    // 中間のカード
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 50, height: 32)
                        .offset(x: 2, y: 2)
                    
                    // 前面のカード
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 50, height: 32)
                        .overlay(
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 8, height: 8)
                            }
                            .offset(x: -8, y: 0)
                        )
                }
                
                // カレンダーアイコン
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 40, height: 36)
                    
                    VStack(spacing: 0) {
                        // カレンダーヘッダー
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 40, height: 8)
                        
                        // カレンダーグリッド
                        HStack(spacing: 2) {
                            ForEach(0..<4) { _ in
                                VStack(spacing: 2) {
                                    ForEach(0..<3) { _ in
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 6, height: 4)
                                    }
                                }
                            }
                        }
                        .padding(4)
                    }
                }
                
                // 通知ベルアイコン
                ZStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    // 通知バッジ
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 8, y: -8)
                }
            }
        }
        .frame(width: 128, height: 128)
        .cornerRadius(28) // macOS Big Sur以降のアイコンスタイル
    }
}

// アイコン生成用のビュー（複数サイズ）
struct AppIconGenerator: View {
    let sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(sizes, id: \.self) { size in
                    VStack {
                        Text("\(size)x\(size)")
                            .font(.caption)
                        
                        AppIconView()
                            .frame(width: CGFloat(size), height: CGFloat(size))
                            .scaleEffect(CGFloat(size) / 128.0)
                            .frame(width: CGFloat(size), height: CGFloat(size))
                            .background(Color.gray.opacity(0.1))
                            .border(Color.gray, width: 1)
                    }
                }
            }
            .padding()
        }
    }
}

// 別のデザイン案：シンプルな円形デザイン
struct AppIconAlternativeView: View {
    var body: some View {
        ZStack {
            // 背景の円
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.5, blue: 0.95),
                            Color(red: 0.2, green: 0.6, blue: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 中央のシンボル
            VStack(spacing: 0) {
                // 円記号
                Text("¥")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // 更新を表す矢印
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
                
                // 小さなカレンダー
                HStack(spacing: 2) {
                    ForEach(0..<7) { i in
                        Rectangle()
                            .fill(i == 3 ? Color.orange : Color.white.opacity(0.7))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            
            // 通知インジケータ
            Circle()
                .fill(Color.red)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                )
                .offset(x: 40, y: -40)
        }
        .frame(width: 128, height: 128)
    }
}

// プレビュー
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            VStack {
                Text("デザイン案1: カードスタック")
                    .font(.headline)
                AppIconView()
                    .shadow(radius: 10)
            }
            
            VStack {
                Text("デザイン案2: 円形シンプル")
                    .font(.headline)
                AppIconAlternativeView()
                    .shadow(radius: 10)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}
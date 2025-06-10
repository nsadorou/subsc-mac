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
            // 中央の青い円（少し大きく）
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.6, blue: 1.0),
                            Color(red: 0.2, green: 0.4, blue: 0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
            
            // メインコンテンツ
            VStack(spacing: 3) {
                // クレジットカード（シンプル化）
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 24, height: 16)
                    .overlay(
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 3, height: 3)
                            Circle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 3, height: 3)
                        }
                        .offset(x: -4, y: 0)
                    )
                
                // カレンダー（シンプル化）
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 20, height: 18)
                        .overlay(
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(height: 4)
                                
                                HStack(spacing: 1) {
                                    ForEach(0..<3) { _ in
                                        VStack(spacing: 1) {
                                            ForEach(0..<3) { _ in
                                                Circle()
                                                    .fill(Color.blue.opacity(0.3))
                                                    .frame(width: 2, height: 2)
                                            }
                                        }
                                    }
                                }
                                .padding(2)
                            }
                        )
                }
                
                // ベルアイコン
                Image(systemName: "bell.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 128, height: 128)
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
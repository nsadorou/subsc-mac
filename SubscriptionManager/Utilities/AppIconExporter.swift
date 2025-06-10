//
//  AppIconExporter.swift
//  SubscriptionManager
//
//  Created on 2025/01/08.
//

import SwiftUI
import AppKit

struct AppIconDesign1: View {
    let size: CGFloat
    
    var scaleFactor: CGFloat {
        size / 1024.0
    }
    
    // サイズに応じた要素の調整
    var cornerRadius: CGFloat {
        size * 0.2195 // macOS Big Sur標準の角丸比率
    }
    
    var circleSize: CGFloat { size * 0.75 } // 中央の円のサイズ
    var cardWidth: CGFloat { size * 0.1875 }
    var cardHeight: CGFloat { size * 0.125 }
    var cardCornerRadius: CGFloat { size * 0.016 }
    
    var calendarWidth: CGFloat { size * 0.156 }
    var calendarHeight: CGFloat { size * 0.14 }
    var calendarCornerRadius: CGFloat { size * 0.008 }
    
    var bellSize: CGFloat { size * 0.094 }
    
    var body: some View {
        ZStack {
            // 中央の青い円
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
                .frame(width: circleSize, height: circleSize)
            
            VStack(spacing: size * 0.023) {
                // クレジットカード（シンプル）
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color.white)
                    .frame(width: cardWidth, height: cardHeight)
                    .overlay(
                        HStack(spacing: size * 0.016) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: size * 0.023, height: size * 0.023)
                            Circle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: size * 0.023, height: size * 0.023)
                        }
                        .offset(x: -size * 0.031, y: 0)
                    )
                
                // カレンダー（シンプル）
                Rectangle()
                    .fill(Color.white)
                    .frame(width: calendarWidth, height: calendarHeight)
                    .overlay(
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.red)
                                .frame(height: size * 0.031)
                            
                            HStack(spacing: size * 0.008) {
                                ForEach(0..<3) { _ in
                                    VStack(spacing: size * 0.008) {
                                        ForEach(0..<3) { _ in
                                            Circle()
                                                .fill(Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.3))
                                                .frame(width: size * 0.016, height: size * 0.016)
                                        }
                                    }
                                }
                            }
                            .padding(size * 0.016)
                        }
                    )
                
                // ベルアイコン
                Image(systemName: "bell.fill")
                    .font(.system(size: bellSize, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

// アイコンエクスポート用の拡張
extension NSView {
    func snapshot() -> NSImage? {
        guard let bitmapRep = self.bitmapImageRepForCachingDisplay(in: self.bounds) else { return nil }
        self.cacheDisplay(in: self.bounds, to: bitmapRep)
        let image = NSImage(size: self.bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }
}

struct AppIconExporter: View {
    @State private var exportStatus = ""
    
    let iconSizes = [
        (16, "16x16"),
        (32, "32x32"),
        (64, "64x64"),
        (128, "128x128"),
        (256, "256x256"),
        (512, "512x512"),
        (1024, "1024x1024")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("案1: カードスタックデザイン")
                .font(.title2)
            
            // プレビュー
            AppIconDesign1(size: 256)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(56)
                .shadow(radius: 10)
            
            // エクスポートボタン
            Button(action: exportIcons) {
                Label("アイコンをエクスポート", systemImage: "square.and.arrow.down")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if !exportStatus.isEmpty {
                Text(exportStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // サイズ別プレビュー
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach([128, 64, 32, 16], id: \.self) { size in
                        VStack {
                            Text("\(size)x\(size)")
                                .font(.caption)
                            AppIconDesign1(size: CGFloat(size))
                                .background(Color.white)
                                .cornerRadius(CGFloat(size) * 0.22)
                                .shadow(radius: 3)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 600, height: 700)
    }
    
    func exportIcons() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "AppIcons"
        savePanel.prompt = "フォルダを作成"
        savePanel.message = "アイコンファイルを保存する新しいフォルダを作成してください"
        savePanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                exportIconSet(to: url)
            } else {
                exportStatus = "エクスポートがキャンセルされました"
            }
        }
    }
    
    func exportIconSet(to folderURL: URL) {
        var successCount = 0
        
        // ディレクトリが存在しない場合は作成
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            exportStatus = "ディレクトリの作成に失敗しました: \(error.localizedDescription)"
            return
        }
        
        for (size, name) in iconSizes {
            // より正確な画像生成
            let image = generateIconImage(size: CGFloat(size))
            
            if let image = image {
                let fileURL = folderURL.appendingPathComponent("AppIcon_\(name).png")
                
                // 正確なサイズのNSBitmapImageRepを作成
                guard let bitmapRep = NSBitmapImageRep(
                    bitmapDataPlanes: nil,
                    pixelsWide: size,
                    pixelsHigh: size,
                    bitsPerSample: 8,
                    samplesPerPixel: 4,
                    hasAlpha: true,
                    isPlanar: false,
                    colorSpaceName: .calibratedRGB,
                    bytesPerRow: 0,
                    bitsPerPixel: 0
                ) else {
                    print("Failed to create bitmap rep for \(name)")
                    continue
                }
                
                // 描画コンテキストを設定
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
                
                // 背景をクリア
                NSColor.clear.set()
                NSRect(x: 0, y: 0, width: size, height: size).fill()
                
                // 画像を描画
                image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
                
                NSGraphicsContext.restoreGraphicsState()
                
                // PNGデータとして保存
                if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: fileURL)
                        successCount += 1
                        print("Successfully saved \(name): \(size)x\(size) pixels")
                    } catch {
                        print("Failed to save \(name): \(error)")
                        exportStatus = "エラー: \(name) の保存に失敗しました"
                        return
                    }
                }
            } else {
                print("Failed to generate image for \(name)")
                exportStatus = "エラー: \(name) の画像生成に失敗しました"
                return
            }
        }
        
        exportStatus = "\(successCount)個のアイコンをエクスポートしました\n保存先: \(folderURL.path)"
        
        // Contents.jsonも生成
        generateContentsJSON(at: folderURL)
    }
    
    private func generateIconImage(size: CGFloat) -> NSImage? {
        let hostingView = NSHostingView(rootView: AppIconDesign1(size: size))
        hostingView.frame = NSRect(x: 0, y: 0, width: size, height: size)
        
        // ビューを正しくレイアウト
        hostingView.layout()
        
        // 高DPIディスプレイ対応
        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        
        bitmapRep.size = NSSize(width: size, height: size)
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        
        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(bitmapRep)
        
        return image
    }
    
    func generateContentsJSON(at folderURL: URL) {
        let contents = """
        {
          "images" : [
            {
              "filename" : "AppIcon_16x16.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "16x16"
            },
            {
              "filename" : "AppIcon_32x32.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "16x16"
            },
            {
              "filename" : "AppIcon_32x32.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "32x32"
            },
            {
              "filename" : "AppIcon_64x64.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "32x32"
            },
            {
              "filename" : "AppIcon_128x128.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "128x128"
            },
            {
              "filename" : "AppIcon_256x256.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "128x128"
            },
            {
              "filename" : "AppIcon_256x256.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "256x256"
            },
            {
              "filename" : "AppIcon_512x512.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "256x256"
            },
            {
              "filename" : "AppIcon_512x512.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "512x512"
            },
            {
              "filename" : "AppIcon_1024x1024.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "512x512"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        
        let jsonURL = folderURL.appendingPathComponent("Contents.json")
        do {
            try contents.write(to: jsonURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save Contents.json: \(error)")
        }
    }
}

struct AppIconExporter_Previews: PreviewProvider {
    static var previews: some View {
        AppIconExporter()
    }
}
# Xcodeへのファイル追加手順

## 追加が必要なファイル

### 1. Services フォルダ
- `DataExportService.swift`

### 2. Utilities フォルダ（新規作成が必要）
- `AnimationHelpers.swift`
- `ErrorHandler.swift`
- `CurrencyFormatter.swift`（既存）

### 3. Views フォルダ
- `AnalyticsView.swift`

## 追加手順

1. **Utilities フォルダの作成**
   - プロジェクトナビゲーターでプロジェクトを右クリック
   - "New Group" → "Utilities" と名前を付ける

2. **ファイルの追加**
   - 各フォルダを右クリック
   - "Add Files to 'SubscriptionManager'" を選択
   - 対応するファイルを選択

3. **ビルド確認**
   - Command + B でビルド
   - エラーがないことを確認

## ファイル追加後の修正

ContentView.swift の以下の部分を元に戻す：

```swift
// 現在（一時的）
case 1:
    // AnalyticsView()
    Text("分析画面（実装中）")
        .font(.title)
        .foregroundColor(.secondary)

// 修正後
case 1:
    AnalyticsView()
```

```swift
// 現在（一時的）
// .errorHandling()
// .performanceMeasured("ContentView")

// 修正後
.errorHandling()
.performanceMeasured("ContentView")
```

## トラブルシューティング

- **"Cannot find in scope" エラー**: ファイルがプロジェクトに追加されていない
- **"has no member" エラー**: モジュールが正しくインポートされていない
- **ビルドエラー**: Clean Build Folder (Shift + Command + K) を実行
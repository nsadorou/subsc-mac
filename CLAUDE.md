# サブスク管理アプリ (macOS) - 包括的ドキュメント

## プロジェクト概要
macOS向けの包括的なサブスクリプション管理アプリケーション。ユーザーが複数のサブスクリプションサービスを一元管理し、更新日前に通知を受け取り、支出を分析できる高機能なアプリです。

## 実装済み機能一覧

### 1. サブスクリプション管理 ✅
- **基本情報の入力・編集** ✅
  - サービス名（必須）
  - 金額（日本円・ドル対応）
  - 支払い方法（クレジットカード、デビットカード、銀行振替、PayPal、その他）
  - 備考欄（自由記述）
  - 契約開始日
  - 更新サイクル（月次・年次）
  - アクティブ/非アクティブ切り替え

- **通貨換算機能** ✅
  - USD→JPY自動換算（リアルタイム為替レート）
  - exchangerate-api.com API連携
  - 入力時の為替レートを記録・保持
  - フォールバック機能（API失敗時は150円/ドル）
  - 24時間キャッシュ機能

### 2. 通知システム ✅
- **通知タイミング設定** ✅
  - 更新日の1日前、3日前、1週間前、2週間前から複数選択可能
  - 通知時間の指定（デフォルト：10:00）
  - バックグラウンド自動更新機能

- **通知内容** ✅
  - サービス名
  - 更新予定日
  - 金額（円換算含む）
  - 支払い方法

### 3. データ管理・表示 ✅
- **一覧表示** ✅
  - 月額・年額別での表示切り替え
  - 次回更新日順でのソート
  - 月間・年間総額の表示
  - アクティブ/全体の切り替え

- **検索・フィルタ機能** ✅
  - サービス名での検索
  - 支払い方法での絞り込み
  - 金額範囲での絞り込み
  - リアルタイム検索

### 4. 支出分析・グラフ表示 ✅
- **分析ダッシュボード** ✅
  - 月額総額、年額総額、アクティブ件数、平均月額
  - 支払い方法別円グラフ
  - カテゴリ別バーチャート
  - 月次支出推移ラインチャート

- **詳細統計** ✅
  - 最高額、最低額、平均額の表示
  - パーセンテージ表示
  - 過去12か月の推移分析

### 5. データエクスポート・インポート ✅
- **エクスポート機能** ✅
  - CSV形式エクスポート
  - JSON形式エクスポート
  - ファイル保存とシェア機能

- **インポート機能** ✅
  - JSON形式インポート
  - データ重複チェック
  - エラーハンドリング

### 6. UI/UX改善 ✅
- **アニメーション** ✅
  - ボタンプレス効果
  - カード展開アニメーション
  - スライドイン効果
  - パルス効果、グロー効果

- **視覚的フィードバック** ✅
  - ローディングドット
  - 成功チェックマーク
  - シェイク効果（エラー時）
  - ホバー効果

### 7. エラーハンドリング・ロギング ✅
- **包括的エラー管理** ✅
  - カスタムエラー型定義
  - リカバリ提案付きエラーメッセージ
  - 自動エラーアラート表示

- **アプリケーションロギング** ✅
  - 構造化ログ出力
  - ファイルベースログ保存
  - 自動ログクリーンアップ（7日間）
  - デバッグビューでのログ表示

### 8. パフォーマンス最適化 ✅
- **監視・計測** ✅
  - 操作時間の自動計測
  - 遅い操作の自動警告
  - パフォーマンスメトリクス

## 技術仕様

### アーキテクチャ
- **フレームワーク**: SwiftUI + Combine（リアクティブプログラミング）
- **データ永続化**: Core Data（NSManagedObject）
- **通知**: UserNotifications framework
- **為替レート取得**: exchangerate-api.com REST API
- **パターン**: MVVM（Model-View-ViewModel）
- **言語**: Swift 5.0+
- **最小対応**: macOS 11.0+

### データモデル（Core Data）

```swift
// Subscription Entity (Core Data)
@objc(Subscription)
public class Subscription: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var serviceName: String?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var currency: String?
    @NSManaged public var exchangeRate: NSDecimalNumber?
    @NSManaged public var paymentMethod: String?
    @NSManaged public var notes: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var cycle: Int16 // 0: monthly, 1: yearly
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var notificationSettings: NSSet?
}

// NotificationTiming Entity
@objc(NotificationTiming)
public class NotificationTiming: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timing: Int16 // 1, 3, 7, 14 (days before)
    @NSManaged public var subscription: Subscription?
}
```

### 実装済みファイル構造
```
SubscriptionManager/
├── SubscriptionManager.xcodeproj/
├── SubscriptionManager/
│   ├── SubscriptionManagerApp.swift ✅
│   ├── ContentView.swift ✅
│   ├── Info.plist ✅
│   └── SubscriptionManager.xcdatamodeld/ ✅
├── Models/
│   ├── NotificationTiming.swift ✅
│   └── SubscriptionCycle.swift ✅
├── Services/
│   ├── AppLogger.swift ✅
│   ├── CoreDataManager.swift ✅
│   ├── NotificationManager.swift ✅
│   ├── ExchangeRateService.swift ✅
│   ├── CurrencyFormatter.swift ✅
│   └── DataExportService.swift ✅
├── Views/
│   ├── AddEditSubscriptionView.swift ✅
│   ├── AnalyticsView.swift ✅
│   ├── DebugLogView.swift ✅
│   ├── NotificationPermissionView.swift ✅
│   ├── NotificationSettingsView.swift ✅
│   ├── SettingsView.swift ✅
│   ├── SubscriptionDetailView.swift ✅
│   └── SubscriptionListView.swift ✅
├── Utilities/
│   ├── AnimationHelpers.swift ✅
│   └── ErrorHandler.swift ✅
└── Tests/
    ├── SubscriptionManagerTests.swift ✅
    └── SubscriptionManagerUITests.swift ✅
```

### 主要サービス詳細

#### ExchangeRateService
```swift
class ExchangeRateService: ObservableObject {
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"
    private let cacheKey = "ExchangeRateCache"
    private let cacheTimeKey = "ExchangeRateCacheTime"
    private let cacheValidityDuration: TimeInterval = 24 * 60 * 60 // 24時間
    
    func fetchExchangeRate(from: String = "USD", to: String = "JPY") -> AnyPublisher<Double, ExchangeRateError>
}
```

#### NotificationManager
```swift
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    func requestPermission()
    func scheduleNotification(for subscription: Subscription, timing: NotificationTiming)
    func refreshAllNotifications()
    func cancelNotifications(for subscription: Subscription)
}
```

#### DataExportService
```swift
class DataExportService {
    static let shared = DataExportService()
    
    func exportToCSV(subscriptions: [Subscription]) -> URL?
    func exportToJSON(subscriptions: [Subscription]) -> URL?
    func importFromJSON(fileURL: URL) -> Result<[SubscriptionData], DataImportError>
}
```

## 開発履歴

### Phase 1: 基本構造とデータモデル ✅ 完了
1. ✅ Xcodeプロジェクトの作成
2. ✅ Core Dataスタックの設定（CoreDataManager.swift）
3. ✅ 基本的なデータモデルの実装（Subscription, NotificationTiming）
4. ✅ CRUD操作の実装

### Phase 2: UI実装 ✅ 完了
1. ✅ SwiftUIによる基本画面の作成（ContentView.swift）
2. ✅ サブスクリプション一覧画面（SubscriptionListView.swift）
3. ✅ 追加・編集画面（AddEditSubscriptionView.swift）
4. ✅ 詳細表示画面（SubscriptionDetailView.swift）

### Phase 3: 通知機能 ✅ 完了
1. ✅ UserNotificationsの設定（NotificationManager.swift）
2. ✅ 通知スケジューリング機能
3. ✅ 通知タイミング設定UI（NotificationSettingsView.swift）
4. ✅ バックグラウンド通知の実装（BackgroundTaskManager）

### Phase 4: 為替レート機能 ✅ 完了
1. ✅ 外部API連携（ExchangeRateService.swift）
2. ✅ 通貨換算ロジック（CurrencyFormatter.swift）
3. ✅ オフライン時の対応（フォールバック機能）
4. ✅ レート履歴保存（Core Dataに保存）

### Phase 5: 追加機能・改善 ✅ 完了
1. ✅ 検索・フィルタ機能（SubscriptionListView内実装）
2. ✅ エクスポート機能（DataExportService.swift）
3. ✅ UI/UXの改善（AnimationHelpers.swift）
4. ✅ パフォーマンス最適化（PerformanceMonitor）

### 追加実装機能
- ✅ **分析ダッシュボード**（AnalyticsView.swift）- 支出分析とグラフ表示
- ✅ **包括的エラーハンドリング**（ErrorHandler.swift）- カスタムエラー型と自動アラート
- ✅ **アプリケーションロギング**（AppLogger.swift）- 構造化ログとファイル保存
- ✅ **デバッグ機能**（DebugLogView.swift）- ログ表示とデバッグ情報
- ✅ **データインポート機能**（JSON形式）
- ✅ **高度なアニメーション**（カスタムボタンスタイル、効果）

## 実装詳細・仕様

### 通知システム詳細
- **許可要求**: アプリ初回起動時に自動要求
- **スケジューリング**: サブスクリプション追加/編集時に自動設定
- **更新メカニズム**: バックグラウンドで1時間ごとに自動更新
- **通知内容**: タイトル、本文、サウンド、バッジ対応

### 為替レート機能詳細
- **API**: exchangerate-api.com/v4/latest/USD
- **キャッシュ**: UserDefaultsで24時間キャッシュ
- **フォールバック**: API失敗時は150円/ドルの固定レート
- **更新タイミング**: サブスクリプション追加時とアプリ起動時

### 分析機能詳細
- **チャート種類**: 円グラフ、バーチャート、ラインチャート
- **集計期間**: 過去12か月の月次データ
- **分析軸**: 支払い方法別、時系列、統計サマリー
- **リアルタイム更新**: データ変更時に自動再計算

### エクスポート機能詳細
- **CSV形式**: サービス名、金額、通貨、支払い方法、開始日、サイクル
- **JSON形式**: 完全なデータ構造（インポート対応）
- **ファイル保存**: ユーザーが選択したディレクトリに保存

## セキュリティ・プライバシー
- ✅ **ローカルデータのみ**: Core Dataでローカル保存（クラウド同期なし）
- ✅ **HTTPS通信**: 為替レートAPI通信はSSL/TLS暗号化
- ✅ **通知許可**: 適切なユーザー同意取得
- ✅ **データ暗号化**: Core Dataの標準暗号化使用
- ✅ **ログセキュリティ**: 機密情報のログ出力回避

## 配布・リリース準備
- ✅ **サンドボックス対応**: macOS App Store配布準備完了
- ✅ **権限設定**: 通知、ネットワークアクセス権限設定済み
- ⚠️ **アプリアイコン**: 基本アイコンのみ（カスタムアイコン未作成）
- ⚠️ **スクリーンショット**: 未準備

## ペンディング機能
- 🔄 **カテゴリ分類機能**: 支払い方法以外のカスタムカテゴリ（実装保留）
- 🔄 **iCloud同期**: 複数デバイス間でのデータ同期
- 🔄 **ウィジェット**: macOS ウィジェット対応
- 🔄 **多言語対応**: 英語・中国語等の国際化

## トラブルシューティング
- **ビルドエラー**: 全ファイルがXcodeプロジェクトに追加済み確認
- **API失敗**: フォールバック機能により継続動作可能
- **通知不達**: 通知許可状況をデバッグログで確認可能
- **データ不整合**: エラーハンドリングによる適切なエラー表示

## コマンド
- **ビルド・実行**: `./build_and_run.sh`
- **ログ確認**: アプリ内デバッグビューまたは`~/Documents/subscription_manager.log`

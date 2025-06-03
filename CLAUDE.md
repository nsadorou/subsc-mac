# サブスク管理アプリ (macOS)

## プロジェクト概要
macOS向けのサブスクリプション管理アプリケーション。ユーザーが複数のサブスクリプションサービスを一元管理し、更新日前に通知を受け取ることができるアプリです。

## 主要機能

### 1. サブスクリプション管理
- **基本情報の入力・編集**
  - サービス名
  - 金額（日本円・ドル対応）
  - 支払い方法（クレジットカード、デビットカード、銀行振替など）
  - 備考欄（自由記述）
  - 契約開始日
  - 更新サイクル（月次・年次）

- **通貨換算機能**
  - ドル入力時の自動円換算
  - 入力時の為替レートを記録・保持
  - 換算レート履歴の表示

### 2. 通知システム
- **通知タイミング設定**
  - 更新日の1日前、3日前、1週間前、2週間前から選択可能
  - 複数タイミングの同時設定対応
  - 通知時間の指定（例：毎日10:00）

- **通知内容**
  - サービス名
  - 更新予定日
  - 金額
  - 支払い方法

### 3. データ管理・表示
- **一覧表示**
  - 月額・年額別での表示切り替え
  - 次回更新日順でのソート
  - 月間・年間総額の表示

- **検索・フィルタ機能**
  - サービス名での検索
  - 支払い方法での絞り込み
  - 金額範囲での絞り込み

## 技術仕様

### アーキテクチャ
- **フレームワーク**: SwiftUI + Combine
- **データ永続化**: Core Data
- **通知**: UserNotifications framework
- **為替レート取得**: RESTful API（例：ExchangeRate-API）

### データモデル

```swift
// Subscription Entity
struct Subscription {
    var id: UUID
    var serviceName: String
    var amount: Decimal
    var currency: String // "JPY" or "USD"
    var exchangeRate: Decimal? // ドル入力時のレート
    var paymentMethod: String
    var notes: String
    var startDate: Date
    var cycle: SubscriptionCycle // .monthly or .yearly
    var notificationSettings: [NotificationTiming]
    var isActive: Bool
}

enum SubscriptionCycle {
    case monthly
    case yearly
}

enum NotificationTiming: CaseIterable {
    case oneDayBefore
    case threeDaysBefore
    case oneWeekBefore
    case twoWeeksBefore
}
```

### ファイル構造
```
SubscriptionManager/
├── App/
│   ├── SubscriptionManagerApp.swift
│   └── AppDelegate.swift
├── Views/
│   ├── ContentView.swift
│   ├── SubscriptionListView.swift
│   ├── SubscriptionDetailView.swift
│   ├── AddEditSubscriptionView.swift
│   └── SettingsView.swift
├── ViewModels/
│   ├── SubscriptionListViewModel.swift
│   ├── SubscriptionDetailViewModel.swift
│   └── SettingsViewModel.swift
├── Models/
│   ├── Subscription.swift
│   ├── SubscriptionCycle.swift
│   └── NotificationTiming.swift
├── Services/
│   ├── CoreDataManager.swift
│   ├── NotificationManager.swift
│   ├── ExchangeRateService.swift
│   └── SubscriptionCalculator.swift
├── Utilities/
│   ├── DateExtensions.swift
│   ├── CurrencyFormatter.swift
│   └── Constants.swift
└── Resources/
    ├── Localizable.strings
    └── SubscriptionManager.xcdatamodeld
```

## 開発手順

### Phase 1: 基本構造とデータモデル
1. Xcodeプロジェクトの作成
2. Core Dataスタックの設定
3. 基本的なデータモデルの実装
4. CRUD操作の実装

### Phase 2: UI実装
1. SwiftUIによる基本画面の作成
2. サブスクリプション一覧画面
3. 追加・編集画面
4. 詳細表示画面

### Phase 3: 通知機能
1. UserNotificationsの設定
2. 通知スケジューリング機能
3. 通知タイミング設定UI
4. バックグラウンド通知の実装

### Phase 4: 為替レート機能
1. 外部API連携
2. 通貨換算ロジック
3. オフライン時の対応
4. レート履歴保存

### Phase 5: 追加機能・改善
1. 検索・フィルタ機能
2. エクスポート機能
3. UI/UXの改善
4. パフォーマンス最適化

## セキュリティ・プライバシー考慮事項
- 支払い情報の暗号化保存
- ローカルデータのみでの動作（クラウド同期は任意）
- 通知許可の適切な要求
- API通信時のSSL/TLS使用

## 配布・リリース
- Mac App Store配布を想定
- サンドボックス環境での動作確認
- 必要な権限（通知、ネットワーク）の申請
- アプリアイコン・スクリーンショットの準備

## 今後の拡張可能性
- iOSアプリの開発
- iCloud同期機能
- 支出分析・グラフ表示
- カテゴリ分類機能
- CSVエクスポート機能
- 複数通貨での同時管理

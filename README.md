# SubscriptionManager for macOS

macOS向けのサブスクリプション管理アプリケーション。複数のサブスクリプションサービスを一元管理し、更新日前に通知を受け取ることができます。

## 機能

### 実装済み
- ✅ サブスクリプションの追加・編集・削除
- ✅ 月額・年額の管理
- ✅ 支払い方法の記録
- ✅ Core Dataによるデータ永続化
- ✅ SwiftUIによるモダンなUI

### 開発中
- 🚧 通知システム（更新日前の通知）
- 🚧 為替レート対応（USD→JPY自動換算）
- 🚧 検索・フィルタ機能
- 🚧 データエクスポート機能

## 必要環境

- macOS 13.0以降
- Xcode 14.0以降

## セットアップ

1. リポジトリをクローン
```bash
git clone [repository-url]
cd subsc-mac
```

2. Xcodeでプロジェクトを開く
```bash
open SubscriptionManager/SubscriptionManager.xcodeproj
```

3. ビルド＆実行
- Xcodeで `Cmd + R` を押すか、▶️ボタンをクリック

## プロジェクト構造

```
SubscriptionManager/
├── App/                    # アプリケーションのエントリーポイント
├── Views/                  # SwiftUIビュー
├── Models/                # データモデル
├── Services/              # ビジネスロジック・サービス
└── Resources/             # リソースファイル
```

## 開発状況

詳細な開発計画は `development_plan.txt` を参照してください。

## ライセンス

[ライセンスを追加]
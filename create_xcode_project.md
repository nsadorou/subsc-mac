# Xcodeプロジェクトの作成手順

## 1. Xcodeで新規プロジェクトを作成

1. Xcodeを開く
2. "Create New Project" を選択
3. 以下の設定でプロジェクトを作成：
   - **Platform**: macOS
   - **Application Type**: App
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Use Core Data**: ✅ チェックを入れる
   - **Include Tests**: 任意

## 2. プロジェクト設定

- **Product Name**: SubscriptionManager
- **Team**: あなたの開発者アカウント（なければNoneでOK）
- **Organization Identifier**: com.yourname
- **Bundle Identifier**: com.yourname.SubscriptionManager
- **Location**: /Users/morisatoru/claude/subsc-mac

## 3. 既存のファイルを置き換え

プロジェクト作成後、以下のファイルを置き換えてください：

### 置き換えるファイル：
1. `SubscriptionManagerApp.swift` → App/SubscriptionManagerApp.swift の内容で置き換え
2. `ContentView.swift` → Views/ContentView.swift の内容で置き換え
3. `Persistence.swift` を削除

### 追加するファイル：
1. **Views グループを作成**して以下を追加：
   - SubscriptionListView.swift
   - AddEditSubscriptionView.swift
   - SubscriptionDetailView.swift
   - SettingsView.swift

2. **Models グループを作成**して以下を追加：
   - SubscriptionCycle.swift
   - NotificationTiming.swift

3. **Services グループを作成**して以下を追加：
   - CoreDataManager.swift

## 4. Core Dataモデルの更新

1. `SubscriptionManager.xcdatamodeld` を選択
2. 既存のEntityを削除
3. 新しいEntity「Subscription」を追加
4. 以下の属性を追加：
   - amount (Decimal)
   - createdAt (Date)
   - currency (String)
   - cycle (Integer 16)
   - exchangeRate (Decimal, Optional)
   - id (UUID)
   - isActive (Boolean)
   - notes (String, Optional)
   - paymentMethod (String)
   - serviceName (String)
   - startDate (Date)
   - updatedAt (Date)

## 5. ビルド設定の確認

1. **Deployment Target**: macOS 13.0
2. **Signing & Capabilities**:
   - App Sandboxを有効化
   - Network → Outgoing Connections (Client) を有効化

これで正しくビルドできるはずです。
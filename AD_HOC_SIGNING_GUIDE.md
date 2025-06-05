# Ad Hoc署名ガイド

## Ad Hoc署名とは
Ad Hoc署名は、Apple Developer証明書なしでアプリに最小限の署名を付与する方法です。
ローカルマシンでのみ有効で、他のMacでは動作しません。

## 署名手順

### 1. アプリをビルド（署名なし）
```bash
cd SubscriptionManager
xcodebuild -project SubscriptionManager.xcodeproj \
           -scheme SubscriptionManager \
           -configuration Release \
           -derivedDataPath build/ \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           build
```

### 2. ビルドされたアプリの場所を確認
```bash
# 通常は以下のパスにビルドされます
ls build/Build/Products/Release/SubscriptionManager.app
```

### 3. Ad Hoc署名を適用
```bash
# アプリに署名を付与
codesign --force --deep --sign - build/Build/Products/Release/SubscriptionManager.app

# 署名の確認
codesign --verify --verbose build/Build/Products/Release/SubscriptionManager.app
```

### 4. アプリケーションフォルダにコピー（オプション）
```bash
cp -R build/Build/Products/Release/SubscriptionManager.app /Applications/
```

## 注意事項

### セキュリティ
- この署名は最小限のもので、完全な保護は提供しません
- ローカルマシンでのみ有効
- macOSのアップデート後に再署名が必要な場合があります

### 制限事項
- 他のMacでは動作しません
- 一部のシステム機能（iCloud等）は使用できません
- App Storeでの配布は不可能

### Gatekeeperの警告を回避
初回起動時に警告が出る場合：
1. Finderでアプリを右クリック
2. 「開く」を選択
3. 警告ダイアログで「開く」をクリック

## トラブルシューティング

### 「壊れているため開けません」エラー
```bash
# 拡張属性をクリア
xattr -cr /Applications/SubscriptionManager.app
```

### 署名の詳細を確認
```bash
codesign -dvvv /Applications/SubscriptionManager.app
```

### 再署名が必要な場合
アプリを更新した後は、再度署名を適用：
```bash
codesign --force --deep --sign - /Applications/SubscriptionManager.app
```

## 推奨事項
- 開発・テスト用途には便利
- 長期使用には無料のApple Developerアカウントを推奨
- 配布する場合は正式な開発者証明書が必要
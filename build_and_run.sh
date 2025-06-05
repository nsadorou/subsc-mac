#!/bin/bash

# SubscriptionManagerアプリのビルドと実行

echo "🔨 SubscriptionManagerをビルドしています..."

# Xcodeプロジェクトディレクトリに移動
cd "$(dirname "$0")"

# ビルドディレクトリをクリーン
rm -rf build/

# デバッグビルドを実行（コード署名を無効にしてテストビルド）
xcodebuild -project SubscriptionManager.xcodeproj \
           -scheme SubscriptionManager \
           -configuration Debug \
           -derivedDataPath build/ \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           build

if [ $? -eq 0 ]; then
    echo "✅ ビルド成功！"
    echo "🚀 アプリを起動しています..."
    
    # ビルドされたアプリを実行
    open build/Build/Products/Debug/SubscriptionManager.app
else
    echo "❌ ビルドに失敗しました"
    exit 1
fi
#!/bin/bash

# SubscriptionManagerアプリのビルドと実行

echo "🔨 SubscriptionManagerをビルドしています..."

# Xcodeプロジェクトディレクトリに移動
cd "$(dirname "$0")"

# ビルドディレクトリをクリーン
rm -rf build/

# デバッグビルドを実行
xcodebuild -project SubscriptionManager.xcodeproj \
           -scheme SubscriptionManager \
           -configuration Debug \
           -derivedDataPath build/ \
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
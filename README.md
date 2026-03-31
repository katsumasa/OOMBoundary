# OOMBoundary

iOSアプリケーション内で利用可能なメモリの絶対的上限を高精度に計測するツール

## 概要

このアプリは、iOS端末で利用可能なメモリの上限を科学的に測定するために設計された高度なテストツールです。Apple公式のlow-level APIを活用し、メモリを段階的に確保しながら、Out of Memory（OOM）が発生するまでの最大メモリ量を計測します。

## アーキテクチャの特徴

### 1. 高精度なメモリアロケーション
- **UnsafeMutableRawPointer**を使用した低レベルメモリ制御
- **ランダムデータによるDirty化**: iOSのメモリ圧縮を回避し、物理RAMを確実に消費
- **16KBページサイズ対応**: iOSのメモリページアーキテクチャに最適化

### 2. 科学的な限界値算出
- **phys_footprint API**: Xcodeのメモリゲージと完全一致する正確なフットプリント測定
- **os_proc_available_memory()**: 残存メモリの動的取得
- **絶対的限界の計算式**: `Absolute Limit = phys_footprint + os_proc_available_memory()`

### 3. データの永続化
- OOMクラッシュ（SIGKILL）に備えた同期的なUserDefaults保存
- アプリ再起動時の前回セッション結果の自動表示
- メモリ警告閾値の記録

### 4. MetricKit統合
- システム視点でのピークメモリ使用量検証
- アプリ計測値とOS記録値の精度比較
- OOM診断レポートの取得

### 5. Increased Memory Limitエンタイトルメント対応
- 8GB以上のRAM搭載デバイスで拡張メモリ制限を有効化
- iPhone 15 Pro、iPhone 16 Proなどの大容量RAMデバイスに最適

## 機能

### リアルタイム表示
- **Allocated Memory**: 確保したメモリ量
- **Memory Footprint**: 実際の物理メモリ使用量（phys_footprint）
- **Available Memory**: 残り利用可能メモリ（os_proc_available_memory）
- **Absolute Limit**: 計算された絶対的限界値

### メモリタイプ別内訳
- **Clean Memory**: システムが解放可能なメモリ
- **Dirty Memory**: アプリが使用中の解放不可メモリ
- **Compressed Memory**: メモリ圧縮されたページ

### 前回セッション結果
- OOMクラッシュ後の最大到達メモリ
- メモリ警告発生の閾値
- OS報告値との精度比較

## 要件

- iOS 17.0以降
- Xcode 15.0以降
- Swift 5.9以降

## ビルド方法

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/OOMBoundary.git
cd OOMBoundary

# Xcodeで開く
open OOMBoundary.xcodeproj
```

Xcodeでプロジェクトを開き、実機またはシミュレーターを選択して実行（⌘R）してください。

## 使用方法

### 初回測定
1. **Start Allocation** ボタンをタップしてメモリ確保を開始
2. メモリ使用量がリアルタイムで表示されます
3. `Available Memory`が減少し、限界の95%に到達すると警告が表示されます
4. メモリ警告（UIApplication.didReceiveMemoryWarning）が発火します
5. 最終的にアプリがOOMによりクラッシュします（SIGKILL）

### 結果の確認
1. アプリを再起動します
2. **Previous Session Results**セクションに以下が表示されます：
   - **Max Memory Reached (App)**: アプリが記録した最大メモリ
   - **Warning Threshold**: メモリ警告が発生した閾値
3. 24時間後、MetricKitからOS報告値が取得され、精度が検証されます

### 再測定
1. **Reset** ボタンでメモリを解放
2. 再度測定を開始できます

## 技術的詳細

### メモリ計測の信頼性

このツールは以下の3つの独立したデータソースで計測を検証します：

1. **アプリ内計測**: `phys_footprint` によるリアルタイム測定
2. **永続化データ**: OOMクラッシュ直前にUserDefaultsに保存された最終値
3. **MetricKit**: OSが外部から記録したピークメモリ使用量

3つの値が一致することで、計測の正確性が科学的に証明されます。

### Jetsamメカニズム

iOSのJetsamデーモンは以下の手順でアプリを終了します：

1. メモリプレッシャー検知
2. 低メモリ警告の送信（UIApplicationDidReceiveMemoryWarning）
3. バックグラウンドアプリの優先順位順終了
4. フォアグラウンドアプリがハードリミット到達でSIGKILL送信

本ツールはこのプロセス全体を追跡・記録します。

## 注意事項

- **実機での測定を強く推奨**: シミュレーターではMacのメモリに依存するため、実際のiPhoneの制限とは全く異なる結果になります
- **意図的なクラッシュ**: このアプリはOOMを発生させることが目的です
- **テスト目的専用**: このアプリは開発・テスト・研究目的で使用してください
- **MetricKitの配信タイミング**: OS報告値は24時間後に配信されます
- **メモリ制限の変動**: iOSのバージョンやデバイスの状態によって限界値は変動します

## 参考文献

このツールの実装は、以下のApple公式ドキュメントおよび技術資料に基づいています：

- [Identifying high-memory use with jetsam event reports](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports)
- [os_proc_available_memory - Apple Developer Documentation](https://developer.apple.com/documentation/os/os_proc_available_memory)
- [Reducing your app's memory use](https://developer.apple.com/documentation/xcode/reducing-your-app-s-memory-use)
- [iOS Memory Deep Dive - WWDC18](https://developer.apple.com/videos/play/wwdc2018/416/)
- [MetricKit - Apple Developer Documentation](https://developer.apple.com/documentation/MetricKit)

## ライセンス

MIT License

## 作成者

Katsumasa Kimura

---

**Note**: このツールは、iOSのメモリ管理メカニズムの理解を深め、メモリ集約型アプリケーションの開発に役立てることを目的としています。App Storeへの提出は推奨されません。

# OOMBoundary

![Version](https://img.shields.io/badge/version-1.0-blue)
![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

<details open>
<summary>🇯🇵 日本語</summary>

## 概要

iOSアプリケーション内で利用可能なメモリの絶対的上限を高精度に計測するツールです。

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

### メモリタイプの選択
- **Dirty Memory**: ランダムデータを書き込み、メモリ圧縮を無効化
  - 物理RAMを確実に消費し、真のメモリ限界を測定
  - OOM限界値の正確な計測に推奨
- **Clean Memory**: ゼロデータで初期化（圧縮可能）
  - iOSのメモリ圧縮により、物理メモリ消費が少なくなる
  - 論理アドレス空間と物理メモリ消費の乖離を観察可能

### リアルタイム表示
- **Allocated Memory**: 確保したメモリ量（選択したタイプ）
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
1. **Memory Type** でDirtyまたはCleanを選択
   - **Dirty**: 正確なOOM限界測定（推奨）
   - **Clean**: メモリ圧縮の挙動観察用
2. **Start Allocation** ボタンをタップしてメモリ確保を開始
3. メモリ使用量がリアルタイムで表示されます
4. `Available Memory`が減少し、限界の95%に到達すると警告が表示されます
5. メモリ警告（UIApplication.didReceiveMemoryWarning）が発火します
6. 最終的にアプリがOOMによりクラッシュします（SIGKILL）

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

### Dirty vs Clean メモリの違い

**Dirty Memory:**
- アプリが書き込んだデータを含むメモリページ
- ディスク上に同一のデータが存在しない
- システムが勝手に破棄できない
- 物理RAMを確実に消費
- **本ツールでのOOM限界測定に最適**

**Clean Memory:**
- 書き込まれていない、または圧縮可能なデータ
- システムがメモリプレッシャー時に破棄可能
- メモリ圧縮により物理メモリ消費が抑えられる
- 論理的に確保したサイズと物理的な消費量が乖離
- **メモリ圧縮の挙動観察に有用**

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

</details>

<details>
<summary>🇺🇸 English</summary>

## Overview

A high-precision tool for measuring the absolute memory limit available to iOS applications.

This app is an advanced testing tool designed to scientifically measure the memory limits of iOS devices. It leverages Apple's official low-level APIs to progressively allocate memory and measure the maximum amount of memory available before an Out of Memory (OOM) event occurs.

## Architecture Features

### 1. High-Precision Memory Allocation
- **UnsafeMutableRawPointer** for low-level memory control
- **Random Data Dirtying**: Prevents iOS memory compression and ensures physical RAM consumption
- **16KB Page Size Optimization**: Optimized for iOS memory page architecture

### 2. Scientific Limit Calculation
- **phys_footprint API**: Accurate footprint measurement that matches Xcode's memory gauge
- **os_proc_available_memory()**: Dynamic retrieval of remaining available memory
- **Absolute Limit Formula**: `Absolute Limit = phys_footprint + os_proc_available_memory()`

### 3. Data Persistence
- Synchronous UserDefaults saving to survive OOM crashes (SIGKILL)
- Automatic display of previous session results on app restart
- Memory warning threshold recording

### 4. MetricKit Integration
- Peak memory usage verification from the system's perspective
- Accuracy comparison between app measurements and OS-reported values
- OOM diagnostic report retrieval

### 5. Increased Memory Limit Entitlement Support
- Enables extended memory limits on devices with 8GB+ RAM
- Optimized for high-capacity RAM devices like iPhone 15 Pro and iPhone 16 Pro

## Features

### Memory Type Selection
- **Dirty Memory**: Writes random data to prevent memory compression
  - Ensures physical RAM consumption for accurate OOM limit measurement
  - Recommended for precise OOM threshold testing
- **Clean Memory**: Initializes with zero data (compressible)
  - iOS memory compression reduces physical memory consumption
  - Useful for observing the difference between logical and physical memory usage

### Real-time Display
- **Allocated Memory**: Amount of memory allocated (selected type)
- **Memory Footprint**: Actual physical memory usage (phys_footprint)
- **Available Memory**: Remaining available memory (os_proc_available_memory)
- **Absolute Limit**: Calculated absolute memory limit

### Memory Type Breakdown
- **Clean Memory**: Memory that can be reclaimed by the system
- **Dirty Memory**: Memory in use by the app that cannot be reclaimed
- **Compressed Memory**: Memory-compressed pages

### Previous Session Results
- Maximum memory reached before OOM crash
- Memory warning threshold
- Accuracy comparison with OS-reported values

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Build Instructions

```bash
# Clone the repository
git clone https://github.com/yourusername/OOMBoundary.git
cd OOMBoundary

# Open in Xcode
open OOMBoundary.xcodeproj
```

Open the project in Xcode, select a physical device or simulator, and run (⌘R).

## Usage

### Initial Measurement
1. Select **Dirty** or **Clean** under **Memory Type**
   - **Dirty**: Accurate OOM limit measurement (recommended)
   - **Clean**: For observing memory compression behavior
2. Tap **Start Allocation** to begin memory allocation
3. Memory usage will be displayed in real-time
4. When `Available Memory` decreases to 95% of the limit, a warning will appear
5. A memory warning (UIApplication.didReceiveMemoryWarning) will fire
6. Eventually, the app will crash due to OOM (SIGKILL)

### Viewing Results
1. Restart the app
2. The **Previous Session Results** section will display:
   - **Max Memory Reached (App)**: Maximum memory recorded by the app
   - **Warning Threshold**: Threshold at which memory warning occurred
3. After 24 hours, OS-reported values will be retrieved from MetricKit for accuracy verification

### Re-measurement
1. Tap **Reset** to release memory
2. Start the measurement again

## Technical Details

### Measurement Reliability

This tool verifies measurements using three independent data sources:

1. **In-App Measurement**: Real-time measurement via `phys_footprint`
2. **Persisted Data**: Final values saved to UserDefaults just before OOM crash
3. **MetricKit**: Peak memory usage recorded externally by the OS

The agreement of these three values scientifically validates the measurement accuracy.

### Jetsam Mechanism

iOS's Jetsam daemon terminates apps in the following sequence:

1. Memory pressure detection
2. Low memory warning dispatch (UIApplicationDidReceiveMemoryWarning)
3. Priority-based termination of background apps
4. SIGKILL sent to foreground apps when hard limit is reached

This tool tracks and records the entire process.

### Dirty vs Clean Memory

**Dirty Memory:**
- Memory pages containing data written by the app
- No identical data exists on disk
- Cannot be arbitrarily discarded by the system
- Ensures physical RAM consumption
- **Optimal for OOM limit measurement with this tool**

**Clean Memory:**
- Unwritten or compressible data
- Can be discarded by the system under memory pressure
- Memory compression reduces physical memory consumption
- Logical allocation size differs from physical consumption
- **Useful for observing memory compression behavior**

## Notes

- **Strongly recommend testing on physical devices**: Simulator results depend on Mac's memory and differ significantly from actual iPhone limits
- **Intentional crashes**: This app is designed to cause OOM events
- **Testing purposes only**: This app should be used for development, testing, and research purposes
- **MetricKit delivery timing**: OS-reported values are delivered 24 hours later
- **Memory limit variability**: Limits vary depending on iOS version and device state

## References

The implementation of this tool is based on the following official Apple documentation and technical resources:

- [Identifying high-memory use with jetsam event reports](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports)
- [os_proc_available_memory - Apple Developer Documentation](https://developer.apple.com/documentation/os/os_proc_available_memory)
- [Reducing your app's memory use](https://developer.apple.com/documentation/xcode/reducing-your-app-s-memory-use)
- [iOS Memory Deep Dive - WWDC18](https://developer.apple.com/videos/play/wwdc2018/416/)
- [MetricKit - Apple Developer Documentation](https://developer.apple.com/documentation/MetricKit)

## License

MIT License

## Author

Katsumasa Kimura

---

**Note**: This tool is intended to deepen understanding of iOS memory management mechanisms and aid in the development of memory-intensive applications. It is not recommended for App Store submission.

</details>

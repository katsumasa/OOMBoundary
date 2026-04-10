# OOMBoundary

![Version](https://img.shields.io/badge/version-1.3-blue)
![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

<details>
<summary>🇯🇵 日本語</summary>

## 📚 ドキュメント

| ドキュメント | 説明 |
|------------|------|
| [⚡ クイックスタート](QUICK_START.md) | 今すぐ始める |
| [🔧 Xcodeスキーム設定](XCODE_SCHEME_SETUP.md) | Xcodeでモード切り替え（図解付き） |
| [📦 リリースプロセス](RELEASE_PROCESS.md) | Version更新・リリース手順 |
| [🔢 Version管理](VERSION_MANAGEMENT.md) | Version/Build番号の管理 |
| [🔐 Memory Enforcement](MEMORY_ENFORCEMENT_GUIDE.md) | モード切り替え詳細ガイド |
| [📁 プロジェクト構造](PROJECT_STRUCTURE.md) | ファイル構成の説明 |

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

### Memory Integrity Enforcement
Runtime中のiOSメモリ保護機能の状態を確認：

**iOS 18以降の新機能:**
アプリケーションがMemory Integrity Enforcementのフル保護にオプトインできるようになりました。以前はSoft Modeに制限されていましたが、現在はより強力なメモリ安全保護を有効化できます。

**保護モード:**
- **Soft Mode** (従来): 基本的なメモリ保護のみ
- **Full Mode** (新機能): 完全なメモリ整合性の強制
  - より厳格なメモリアクセス制御
  - 高度なメモリ改ざん検知
  - 最大限のセキュリティ保護

**検出項目:**

- **Hardened Runtime**: アプリがHardened Runtime環境で実行されているか
  - コード署名の厳格な検証
  - 脱獄検知やデバッガアタッチの防止
  - セキュリティ強化されたランタイム環境

- **Memory Enforcement**: メモリ整合性の強制が有効か
  - 署名されていないコードの実行を防止
  - メモリ改ざん攻撃からの保護
  - Code Signingの強制適用

- **W^X Protection**: Write XOR Execute保護（書き込み可能または実行可能の排他制御）
  - メモリページは「書き込み可能」または「実行可能」のいずれか一方のみ
  - バッファオーバーフロー攻撃やコード注入攻撃を防御
  - JITコンパイラなど正当な用途には例外を許可

- **PAC Support**: Pointer Authentication Code対応（A12以降のチップ）
  - 関数ポインタや戻りアドレスに暗号学的署名を追加
  - ROP (Return-Oriented Programming) 攻撃を防御
  - Apple Siliconの最新セキュリティ機能

- **Library Validation**: ダイナミックライブラリの署名検証
  - 読み込まれるライブラリが正しく署名されているか検証
  - 悪意のあるライブラリの注入を防止

- **Protection Level**: 全体的な保護レベル（Full/Standard/Partial/Minimal）
  - Full Protection: すべての主要保護機能が有効
  - Standard Protection: 基本的な保護が有効
  - Partial Protection: 一部の保護のみ有効
  - Minimal Protection: 最小限の保護のみ

これらの機能により、アプリが安全なメモリ環境で動作していることを確認できます。

## 要件

- iOS 17.0以降
- Xcode 15.0以降
- Swift 5.9以降

## ビルド方法

### 方法1: Xcode（シンプル）

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/OOMBoundary.git
cd OOMBoundary

# スキームを自動セットアップ（初回のみ）
./Scripts/setup-xcode-schemes.sh

# Xcodeで開く
open OOMBoundary.xcodeproj
```

Xcodeでプロジェクトを開き、ツールバーでスキームを選択：
- **OOMBoundary**: Soft Mode
- **OOMBoundary-Full**: Full Mode

実機またはシミュレーターを選択して実行（⌘R）してください。

**詳細:** [Xcode スキーム設定ガイド](XCODE_SCHEME_SETUP.md)

### 方法2: コマンドライン

```bash
# Soft Modeでビルド
./Scripts/build.sh soft simulator debug

# Full Modeでビルド
./Scripts/build.sh full simulator debug
```

### リリースビルド

```bash
# バージョンを更新（例: 1.1 → 1.2）
./Scripts/bump-version.sh minor

# 両モードをビルド
./Scripts/build.sh soft device release
./Scripts/build.sh full device release
```

詳細は [RELEASE_PROCESS.md](RELEASE_PROCESS.md) を参照してください。

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

### Memory Integrity Enforcementの確認
アプリ起動時に自動的にメモリ保護機能の状態を検出し、デバイス情報の下に表示します。

**表示の見方:**
- 🟢 緑色のチェックマーク: 機能が有効（推奨）
- 🔴 赤色のバツ印: 機能が無効
- Protection Level:
  - **Maximum Protection** (緑): Full Mode + 全保護機能有効（最高レベル）
  - **Full Protection** (緑): すべての主要保護が有効
  - **Standard Protection** (オレンジ): 標準的な保護レベル。基本的な保護は有効
  - **Partial Protection**: 一部の保護のみ有効
  - **Minimal Protection**: 最小限の保護のみ
- Enforcement Mode (iOS 18+):
  - **Full Mode** ⭐: 完全なメモリ整合性強制（最強の保護）
  - **Soft Mode**: 基本的なメモリ保護（デフォルト）
  - **Unknown**: モード検出不可またはiOS 18未満

**実機とシミュレーターの違い:**
- 実機（特にA12以降）: PAC Supportが有効になり、より高度な保護
- シミュレーター: Macの保護機能に依存するため、実機と結果が異なる可能性あり

**Full Modeを有効にする方法（iOS 18+）:**
アプリでFull Modeを有効にするには、Entitlementsに追加：
```xml
<key>com.apple.security.memory-integrity-enforcement</key>
<string>full</string>
```
または、ビルド設定で指定します。再ビルドと再署名が必要です。

**詳細なモード切り替え方法:**
複数の切り替え方法（スクリプト、Build Configurations、xcconfig等）については、以下のガイドを参照してください：
- [📖 Memory Enforcement モード切り替えガイド (日本語)](MEMORY_ENFORCEMENT_GUIDE.md)
- [📖 Memory Enforcement Mode Switching Guide (English)](MEMORY_ENFORCEMENT_GUIDE_EN.md)

**セキュリティEntitlements:**
表示されている場合、アプリが特別な権限を持つことを示します：
- `allow-jit`: JITコンパイルを許可（通常のアプリでは不要）
- `allow-unsigned-executable-memory`: 未署名の実行可能メモリを許可（セキュリティリスク）
- オレンジ色のチェックマーク = 権限が有効（セキュリティが緩和されている）
- 緑色のバツ印 = 権限が無効（より安全）

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

### Memory Integrity Enforcementの技術詳細

**実装方法:**
- **csops システムコール**: Code Signingフラグを取得してHardened Runtimeの状態を確認
- **vm_protect テスト**: 実際にメモリを確保して書き込み+実行の同時設定を試み、W^X保護の有効性を検証
- **sysctlbyname**: ハードウェアの機能（PAC対応など）を確認

**検証される項目:**
1. **CS_HARD**: Hardened Runtime環境で実行されているか
2. **CS_ENFORCEMENT**: Code Signing強制が有効か
3. **CS_RUNTIME**: Runtimeフラグが設定されているか
4. **CS_RESTRICT**: 制限が有効か
5. **W^X Protection**: メモリの書き込みと実行が排他的か
6. **PAC Support**: Pointer Authentication Codeに対応しているか

**Soft Mode vs Full Mode:**
- **Soft Mode**: デフォルトモード。基本的なメモリ保護のみ適用
- **Full Mode**: オプトイン方式（iOS 18+）。完全なメモリ整合性強制を有効化
  - より厳格なメモリアクセス検証
  - メモリ破壊の早期検出
  - パフォーマンスへの影響がある可能性
  - セキュリティが最優先のアプリに推奨

**モード検出の実装:**
このツールは以下の方法でEnforcement Modeを検出します：
1. **OSバージョンチェック**: iOS 18以降でのみFull Mode対応
2. **Code Signingフラグ**: csopsシステムコールで取得したフラグを解析
3. **task_info API**: タスクのメモリ保護属性を確認
4. **実測テスト**: 実際のメモリ保護の厳格さをテストして推定

iOS 18未満の場合は自動的にSoft Modeと判定されます。

**iOSの制限事項:**
- Entitlementsの詳細は実行時に取得不可（セキュリティ上の理由）
- Code Signingの状態のみ確認可能
- macOS専用のSecurityフレームワークAPIは使用不可

## 注意事項

- **実機での測定を強く推奨**: シミュレーターではMacのメモリに依存するため、実際のiPhoneの制限とは全く異なる結果になります
- **意図的なクラッシュ**: このアプリはOOMを発生させることが目的です
- **テスト目的専用**: このアプリは開発・テスト・研究目的で使用してください
- **MetricKitの配信タイミング**: OS報告値は24時間後に配信されます
- **メモリ制限の変動**: iOSのバージョンやデバイスの状態によって限界値は変動します

## 参考文献

このツールの実装は、以下のApple公式ドキュメントおよび技術資料に基づいています：

**メモリ管理:**
- [Identifying high-memory use with jetsam event reports](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports)
- [os_proc_available_memory - Apple Developer Documentation](https://developer.apple.com/documentation/os/os_proc_available_memory)
- [Reducing your app's memory use](https://developer.apple.com/documentation/xcode/reducing-your-app-s-memory-use)
- [iOS Memory Deep Dive - WWDC18](https://developer.apple.com/videos/play/wwdc2018/416/)
- [MetricKit - Apple Developer Documentation](https://developer.apple.com/documentation/MetricKit)

**セキュリティ:**
- [Hardened Runtime - Apple Developer Documentation](https://developer.apple.com/documentation/security/hardened_runtime)
- [Code Signing - Apple Developer Documentation](https://developer.apple.com/documentation/security/code_signing_services)
- [Pointer Authentication on ARM64e](https://developer.apple.com/documentation/security/preparing_your_app_to_work_with_pointer_authentication)

## ライセンス

MIT License

## 作成者

Katsumasa Kimura

---

**Note**: このツールは、iOSのメモリ管理メカニズムの理解を深め、メモリ集約型アプリケーションの開発に役立てることを目的としています。App Storeへの提出は推奨されません。

</details>

<details>
<summary>🇺🇸 English</summary>

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [⚡ Quick Start](QUICK_START.md) | Get started now |
| [🔧 Xcode Scheme Setup](XCODE_SCHEME_SETUP.md) | Switch modes in Xcode (illustrated) |
| [📦 Release Process](RELEASE_PROCESS.md) | Version updates & release procedures |
| [🔢 Version Management](VERSION_MANAGEMENT.md) | Version/Build number management |
| [🔐 Memory Enforcement](MEMORY_ENFORCEMENT_GUIDE_EN.md) | Mode switching detailed guide |
| [📁 Project Structure](PROJECT_STRUCTURE.md) | File organization explained |

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

### Memory Integrity Enforcement
Runtime verification of iOS memory protection features:

**New Features in iOS 18+:**
Applications can now opt in to the full protections of Memory Integrity Enforcement for enhanced memory safety protection. Previously applications were limited to Soft Mode. (160719439)

**Protection Modes:**
- **Soft Mode** (Legacy): Basic memory protection only
- **Full Mode** (New): Complete memory integrity enforcement
  - Stricter memory access control
  - Advanced memory tampering detection
  - Maximum security protection

**Detection Items:**

- **Hardened Runtime**: Whether the app runs in a Hardened Runtime environment
  - Strict code signature verification
  - Jailbreak detection and debugger attachment prevention
  - Security-hardened runtime environment

- **Memory Enforcement**: Code signing enforcement status
  - Prevents execution of unsigned code
  - Protection against memory tampering attacks
  - Mandatory code signing enforcement

- **W^X Protection**: Write XOR Execute protection (mutual exclusion of writable/executable pages)
  - Memory pages can be either writable OR executable, never both
  - Defends against buffer overflow and code injection attacks
  - Exceptions allowed for legitimate use cases like JIT compilers

- **PAC Support**: Pointer Authentication Code support (A12+ chips)
  - Adds cryptographic signatures to function pointers and return addresses
  - Defends against ROP (Return-Oriented Programming) attacks
  - Latest security feature in Apple Silicon

- **Library Validation**: Dynamic library signature verification
  - Verifies that loaded libraries are properly signed
  - Prevents injection of malicious libraries

- **Protection Level**: Overall protection level (Full/Standard/Partial/Minimal)
  - Full Protection: All major protection features enabled
  - Standard Protection: Basic protections enabled
  - Partial Protection: Only some protections enabled
  - Minimal Protection: Minimal protections only

These features allow you to verify that your app is running in a secure memory environment.

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Build Instructions

### Method 1: Xcode (Simple)

```bash
# Clone the repository
git clone https://github.com/yourusername/OOMBoundary.git
cd OOMBoundary

# Auto-setup schemes (first time only)
./Scripts/setup-xcode-schemes.sh

# Open in Xcode
open OOMBoundary.xcodeproj
```

Open the project in Xcode and select a scheme from the toolbar:
- **OOMBoundary**: Soft Mode
- **OOMBoundary-Full**: Full Mode

Select a physical device or simulator, and run (⌘R).

**Details:** [Xcode Scheme Setup Guide](XCODE_SCHEME_SETUP.md)

### Method 2: Command Line

```bash
# Build with Soft Mode
./Scripts/build.sh soft simulator debug

# Build with Full Mode
./Scripts/build.sh full simulator debug
```

### Release Build

```bash
# Update version (e.g., 1.1 → 1.2)
./Scripts/bump-version.sh minor

# Build both modes
./Scripts/build.sh soft device release
./Scripts/build.sh full device release
```

See [RELEASE_PROCESS.md](RELEASE_PROCESS.md) for details.

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

### Memory Integrity Enforcement Verification
The app automatically detects memory protection feature status on launch and displays it below the device information section.

**How to Read the Display:**
- 🟢 Green checkmark: Feature is enabled (recommended)
- 🔴 Red X mark: Feature is disabled
- Protection Level:
  - **Maximum Protection** (green): Full Mode + All protections enabled (highest level)
  - **Full Protection** (green): All major protections enabled
  - **Standard Protection** (orange): Standard protection level. Basic protections enabled
  - **Partial Protection**: Only some protections enabled
  - **Minimal Protection**: Minimal protections only
- Enforcement Mode (iOS 18+):
  - **Full Mode** ⭐: Complete memory integrity enforcement (strongest protection)
  - **Soft Mode**: Basic memory protection (default)
  - **Unknown**: Mode detection unavailable or pre-iOS 18

**Physical Device vs Simulator:**
- Physical device (especially A12+): PAC Support enabled for advanced protection
- Simulator: Depends on Mac's protection features, may differ from physical devices

**How to Enable Full Mode (iOS 18+):**
To enable Full Mode in your app, add to Entitlements:
```xml
<key>com.apple.security.memory-integrity-enforcement</key>
<string>full</string>
```
Or specify in build settings. Requires rebuild and re-signing.

**Detailed Mode Switching Instructions:**
For multiple switching methods (script, Build Configurations, xcconfig, etc.), see the following guides:
- [📖 Memory Enforcement Mode Switching Guide (日本語)](MEMORY_ENFORCEMENT_GUIDE.md)
- [📖 Memory Enforcement Mode Switching Guide (English)](MEMORY_ENFORCEMENT_GUIDE_EN.md)

**Security Entitlements:**
When displayed, indicates the app has special permissions:
- `allow-jit`: JIT compilation allowed (not needed for normal apps)
- `allow-unsigned-executable-memory`: Unsigned executable memory allowed (security risk)
- Orange checkmark = Permission enabled (security relaxed)
- Green X mark = Permission disabled (more secure)

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

### Memory Integrity Enforcement Technical Details

**Implementation:**
- **csops system call**: Retrieves Code Signing flags to verify Hardened Runtime status
- **vm_protect test**: Allocates memory and attempts simultaneous write+execute permissions to verify W^X protection
- **sysctlbyname**: Checks hardware features (PAC support, etc.)

**Verified Items:**
1. **CS_HARD**: Running in Hardened Runtime environment
2. **CS_ENFORCEMENT**: Code Signing enforcement enabled
3. **CS_RUNTIME**: Runtime flag set
4. **CS_RESTRICT**: Restrictions enabled
5. **W^X Protection**: Memory write and execute are mutually exclusive
6. **PAC Support**: Pointer Authentication Code support available

**Soft Mode vs Full Mode:**
- **Soft Mode**: Default mode. Only basic memory protection applied
- **Full Mode**: Opt-in mode (iOS 18+). Enables complete memory integrity enforcement
  - Stricter memory access validation
  - Early detection of memory corruption
  - May impact performance
  - Recommended for security-critical applications

**Mode Detection Implementation:**
This tool detects Enforcement Mode using the following methods:
1. **OS Version Check**: Full Mode only available on iOS 18+
2. **Code Signing Flags**: Analyzes flags retrieved via csops system call
3. **task_info API**: Checks task memory protection attributes
4. **Empirical Testing**: Tests actual memory protection strictness for estimation

Pre-iOS 18 automatically defaults to Soft Mode detection.

**iOS Limitations:**
- Entitlements details cannot be retrieved at runtime (security reasons)
- Only Code Signing status can be verified
- macOS-specific Security framework APIs unavailable

## Notes

- **Strongly recommend testing on physical devices**: Simulator results depend on Mac's memory and differ significantly from actual iPhone limits
- **Intentional crashes**: This app is designed to cause OOM events
- **Testing purposes only**: This app should be used for development, testing, and research purposes
- **MetricKit delivery timing**: OS-reported values are delivered 24 hours later
- **Memory limit variability**: Limits vary depending on iOS version and device state

## References

The implementation of this tool is based on the following official Apple documentation and technical resources:

**Memory Management:**
- [Identifying high-memory use with jetsam event reports](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports)
- [os_proc_available_memory - Apple Developer Documentation](https://developer.apple.com/documentation/os/os_proc_available_memory)
- [Reducing your app's memory use](https://developer.apple.com/documentation/xcode/reducing-your-app-s-memory-use)
- [iOS Memory Deep Dive - WWDC18](https://developer.apple.com/videos/play/wwdc2018/416/)
- [MetricKit - Apple Developer Documentation](https://developer.apple.com/documentation/MetricKit)

**Security:**
- [Hardened Runtime - Apple Developer Documentation](https://developer.apple.com/documentation/security/hardened_runtime)
- [Code Signing - Apple Developer Documentation](https://developer.apple.com/documentation/security/code_signing_services)
- [Pointer Authentication on ARM64e](https://developer.apple.com/documentation/security/preparing_your_app_to_work_with_pointer_authentication)

## License

MIT License

## Author

Katsumasa Kimura

---

**Note**: This tool is intended to deepen understanding of iOS memory management mechanisms and aid in the development of memory-intensive applications. It is not recommended for App Store submission.

</details>

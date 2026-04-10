# Memory Integrity Enforcement モード切り替えガイド

このガイドでは、OOMBoundaryアプリでMemory Integrity EnforcementのFull ModeとSoft Modeを切り替える方法を説明します。

## 目次

1. [概要](#概要)
2. [切り替え方法](#切り替え方法)
3. [Xcodeでの設定](#xcodeでの設定)
4. [コマンドラインでの切り替え](#コマンドラインでの切り替え)
5. [確認方法](#確認方法)
6. [トラブルシューティング](#トラブルシューティング)

---

## 概要

### Full Mode vs Soft Mode

| 項目 | Soft Mode (デフォルト) | Full Mode (iOS 18+) |
|------|----------------------|---------------------|
| 保護レベル | 基本的なメモリ保護 | 完全なメモリ整合性強制 |
| パフォーマンス | 影響なし | 若干のオーバーヘッド |
| メモリチェック | 基本的 | 厳格（境界外アクセス、Use-After-Free等を検出） |
| 推奨用途 | 一般的なアプリ | セキュリティ重視のアプリ |

---

## 切り替え方法

### 方法1: Entitlementsファイルの直接編集（シンプル）

#### Soft Mode（デフォルト）

`OOMBoundary/OOMBoundary.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.kernel.increased-memory-limit</key>
    <true/>
    <!-- Soft Modeは明示的に指定しない、またはsoftを指定 -->
    <key>com.apple.security.memory-integrity-enforcement</key>
    <string>soft</string>
</dict>
</plist>
```

#### Full Mode

`OOMBoundary/OOMBoundary.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.kernel.increased-memory-limit</key>
    <true/>
    <!-- Full Modeを有効化 -->
    <key>com.apple.security.memory-integrity-enforcement</key>
    <string>full</string>
</dict>
</plist>
```

**再ビルドが必要:** Entitlementsを変更したら、必ずクリーンビルドしてください。

---

### 方法2: スクリプトを使った切り替え（推奨）

プロジェクトには専用の切り替えスクリプトが含まれています。

#### Soft Modeに切り替え

```bash
cd /path/to/OOMBoundary
export MEMORY_ENFORCEMENT_MODE=soft
./Scripts/switch-memory-enforcement.sh
```

#### Full Modeに切り替え

```bash
cd /path/to/OOMBoundary
export MEMORY_ENFORCEMENT_MODE=full
./Scripts/switch-memory-enforcement.sh
```

このスクリプトは自動的に適切なEntitlementsファイルをコピーします。

---

### 方法3: Build Configurations（複数の構成を管理）

プロジェクトには以下のビルド構成ファイルが用意されています：

```
Configs/
├── Debug-Soft.xcconfig      # Debug + Soft Mode
├── Debug-Full.xcconfig      # Debug + Full Mode
├── Release-Soft.xcconfig    # Release + Soft Mode
└── Release-Full.xcconfig    # Release + Full Mode
```

#### Xcodeプロジェクトに適用する手順

1. **Xcodeでプロジェクトを開く**
   ```bash
   open OOMBoundary.xcodeproj
   ```

2. **Project Settings を開く**
   - プロジェクトナビゲーターでプロジェクトファイルをクリック
   - PROJECT > OOMBoundary を選択
   - Info タブを開く

3. **Configurations に xcconfig を適用**
   - Configurations セクションで各構成を展開
   - Debug > OOMBoundary の右側のドロップダウンで `Debug-Soft` を選択
   - Release > OOMBoundary の右側のドロップダウンで `Release-Soft` を選択

4. **新しい Configuration を追加（オプション）**
   - Configurations の "+" ボタンをクリック
   - "Duplicate Debug Configuration" を選択
   - 名前を "Debug-Full" に変更
   - Debug-Full > OOMBoundary で `Debug-Full.xcconfig` を選択

5. **スキームを作成**
   - Product > Scheme > Edit Scheme...
   - 左下の "+" をクリックして新しいスキームを作成
   - 名前を "OOMBoundary-Full" に設定
   - Run, Test, Profile, Analyze, Archive の各タブで Build Configuration を "Debug-Full" に変更

---

### 方法4: 環境変数を使った動的切り替え

Xcode スキームで環境変数を設定することで、ビルドごとに切り替えられます。

1. **スキームを編集**
   - Product > Scheme > Edit Scheme... (⌘<)
   
2. **Build > Pre-actions を追加**
   - Build の左メニューから選択
   - Pre-actions の "+" をクリック
   - "New Run Script Action" を選択
   
3. **スクリプトを追加**
   ```bash
   export MEMORY_ENFORCEMENT_MODE=full  # または soft
   ${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh
   ```

4. **Provide build settings from** で "OOMBoundary" を選択

---

## Xcodeでの設定

### スキーム作成（Full Mode専用ビルド）

1. **新しいスキームを作成**
   ```
   Product > Scheme > New Scheme...
   名前: OOMBoundary-Full
   ```

2. **Edit Scheme で設定**
   - Build Configuration を "Debug-Full" または "Release-Full" に設定
   - Build > Pre-actions でスクリプトを実行（上記参照）

3. **ビルド**
   ```
   Product > Build (⌘B)
   ```

### スキーム切り替え

Xcodeのツールバーで：
- `OOMBoundary` スキーム → Soft Mode
- `OOMBoundary-Full` スキーム → Full Mode

---

## コマンドラインでの切り替え

### xcodebuildを使用

#### Soft Modeでビルド

```bash
xcodebuild \
  -scheme OOMBoundary \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

#### Full Modeでビルド

```bash
# 方法1: 事前にスクリプト実行
export MEMORY_ENFORCEMENT_MODE=full
./Scripts/switch-memory-enforcement.sh
xcodebuild -scheme OOMBoundary -configuration Debug build

# 方法2: xcconfig指定（ビルド設定で設定済みの場合）
xcodebuild \
  -scheme OOMBoundary-Full \
  -configuration Debug-Full \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

---

## 確認方法

### ビルド時の確認

ビルドログで以下を確認：
```
🔧 Switching Memory Integrity Enforcement Mode to: full
✅ Using Full Mode entitlements
📝 Copied .../OOMBoundary-Full.entitlements to .../OOMBoundary.entitlements
```

### 実行時の確認

アプリを起動して、Memory Integrity Enforcement セクションを確認：

**Soft Mode:**
```
Enforcement Mode: Soft Mode
Basic memory protection (default)
```

**Full Mode:**
```
Enforcement Mode: Full Mode ⭐
Complete memory integrity enforcement enabled
```

### コードでの確認

```swift
let checker = MemoryIntegrityChecker.shared
let status = checker.checkMemoryIntegrity()
print("Enforcement Mode: \(status.enforcementMode.description)")
print("Build Setting: \(checker.getBuildTimeEnforcementMode())")
```

---

## トラブルシューティング

### モードが変わらない

**原因:** キャッシュが残っている

**解決策:**
```bash
# クリーンビルド
Product > Clean Build Folder (⌘⇧K)

# または
rm -rf ~/Library/Developer/Xcode/DerivedData/OOMBoundary-*
```

### スクリプトが動作しない

**原因:** 実行権限がない

**解決策:**
```bash
chmod +x Scripts/switch-memory-enforcement.sh
```

### Entitlementsが反映されない

**原因:** Code Signingが正しく設定されていない

**解決策:**
1. プロジェクト設定 > Signing & Capabilities を確認
2. Entitlements ファイルのパスが正しいか確認
3. 再署名が必要な場合はクリーンビルド

### iOS 17以前のデバイスでFull Modeを有効化

**原因:** Full Modeは iOS 18+ の機能

**解決策:**
- iOS 17以前では自動的にSoft Modeになります
- アプリは正常に動作しますが、Full Modeの追加保護は無効です

---

## まとめ

### 推奨される使い方

| 用途 | 推奨モード | 理由 |
|------|-----------|------|
| 開発中のテスト | Soft Mode | パフォーマンス優先 |
| セキュリティテスト | Full Mode | 問題の早期発見 |
| 本番リリース（一般アプリ） | Soft Mode | パフォーマンス重視 |
| 本番リリース（金融・医療等） | Full Mode | セキュリティ最優先 |

### クイックリファレンス

```bash
# Soft Modeに切り替え
export MEMORY_ENFORCEMENT_MODE=soft && ./Scripts/switch-memory-enforcement.sh

# Full Modeに切り替え
export MEMORY_ENFORCEMENT_MODE=full && ./Scripts/switch-memory-enforcement.sh

# 現在のモードを確認（アプリ実行後）
# Memory Integrity Enforcement セクションの "Enforcement Mode" を確認
```

---

## 実機テスト結果と重要な発見（iOS 26.4）

### テスト環境
- **デバイス**: iPhone 17 Pro
- **iOS バージョン**: 26.4
- **ビルド方法**: Development署名（Xcodeから直接実行）

### 調査結果

#### ✅ 正しく動作していること

1. **Entitlements設定**
   - Full Mode: `com.apple.security.memory-integrity-enforcement = "full"` ✅
   - Soft Mode: `com.apple.security.memory-integrity-enforcement = "soft"` ✅

2. **Runtime Detection**
   - Full Modeビルド: "Full Mode Build" と正しく表示 ✅
   - Soft Modeビルド: "Soft Mode Build" と正しく表示 ✅

3. **Code Signing Flags**
   - `0x20000000` (CS_MEMINT_ENABLED) が立つ ✅
   - Memory Integrity機能が有効であることを示す

#### ⚠️ 重要な制限事項

**Development署名では、Full ModeとSoft Modeで観測可能な違いがない**

| 項目 | Full Mode | Soft Mode | 結果 |
|------|-----------|-----------|------|
| Code Signing Flags | `0x32003005` | `0x32003005` | 同一 |
| CS_MEMINT_ENABLED | `true` | `true` | 同一 |
| Use-After-Free Protection | 許可 | 許可 | 同一 |
| Read-Only Memory Write | クラッシュ | クラッシュ | 同一 |
| Out-of-Bounds Access | （テストによる） | （テストによる） | 同一 |

**結論**: Entitlementsは正しく設定されているが、Development署名（Xcodeから直接実行）では、実際のメモリ保護動作に違いが現れない。

### なぜDevelopment署名では違いが現れないのか？

#### Development署名の特徴
```
Development署名（Xcodeから直接実行）:
├─ デバッグ用の緩い設定
├─ W^X Protection = false
├─ Hardened Runtime = false
└─ Full/Soft の違いが現れない
```

#### Distribution署名での期待動作
```
Distribution署名（App Store、TestFlight）:
├─ 本番環境用の厳格な設定
├─ W^X Protection = 有効
├─ Hardened Runtime = 有効
└─ Full/Soft の違いが現れる可能性が高い
```

### Production環境でテストする方法

Full ModeとSoft Modeの実際の違いを確認するには、Distribution署名が必要です：

#### 手順
1. **Archiveを作成**
   ```
   Xcode: Product > Archive
   - Full Modeスキームでアーカイブ
   ```

2. **TestFlightにアップロード**
   ```
   App Store Connect経由でアップロード
   Internal Testing グループに追加
   ```

3. **実機にインストール**
   ```
   TestFlightアプリからインストール
   （Development署名ではなくDistribution署名）
   ```

4. **メモリ違反テストを実行**
   ```
   アプリの "Memory Protection Tests" から
   "Dangerous" ボタンでテスト実行
   ```

5. **Soft Modeでも同様にテスト**
   ```
   Soft Modeスキームでアーカイブして比較
   ```

### Code Signing Flagsの詳細

実機で観測された値：`0x32003005`

```
Bit 0  (0x1):        ✓ 基本フラグ
Bit 2  (0x4):        ✓ 基本フラグ
Bit 12 (0x1000):     ✓ CS_ENFORCEMENT (コード署名強制)
Bit 25 (0x2000000):  ✓ 何らかの機能フラグ
Bit 28 (0x10000000): ✓ 何らかの機能フラグ
Bit 29 (0x20000000): ✓ CS_MEMINT_ENABLED (Memory Integrity有効)
```

**重要**: `0x20000000`フラグは「Memory Integrityが有効」を示すが、Full/Softの区別はしない。詳細設定はEntitlementsに保存され、カーネルのみが読み取る。

### 推奨される運用

#### 開発フェーズ
- **Development署名で問題なし**
- Entitlementsは正しく設定されている
- Runtime Detectionで設定を確認できる
- 実際の保護効果の違いは検証不要

#### リリース前
- **TestFlightでの検証を推奨**（オプション）
- Production環境での動作確認
- メモリ違反テストでの比較
- クラッシュレポートの分析

#### 本番リリース
- セキュリティ要件に応じてFull/Softを選択
- 金融・医療アプリ: Full Mode推奨
- 一般アプリ: Soft Mode（デフォルト）

---

## 参考資料

### 公式ドキュメント
- [iOS 18 New Features - Memory Integrity Enforcement](https://developer.apple.com/documentation/ios-release-notes)
- [Entitlements Reference](https://developer.apple.com/documentation/bundleresources/entitlements)

### 関連プロジェクトファイル
- `OOMBoundary/MemoryIntegrityChecker.swift` - Runtime検出ロジック
- `OOMBoundary/BuildModeDetector.swift` - ビルド設定検出
- `OOMBoundary/MemoryViolationTester.swift` - メモリ違反テスト
- `Scripts/switch-memory-enforcement.sh` - モード切り替えスクリプト
- `TEST_COMPARISON.md` - テスト結果テンプレート

---

**最終更新**: 2026-04-10  
**注意:** Memory Integrity EnforcementのFull Modeは iOS 18 の新機能です。iOS 17以前のデバイスでは、Full Mode Entitlementsを設定してもSoft Modeで動作します。Development署名では実際の保護効果の違いは現れません。

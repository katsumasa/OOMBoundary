# Memory Enforcement モード切り替え - クイックスタート

## Xcode で切り替え（最も簡単）

### 初回セットアップ

```bash
./Scripts/setup-xcode-schemes.sh
open OOMBoundary.xcodeproj
```

### 使い方

Xcodeのツールバーでスキームを選択:
- **OOMBoundary**: Soft Mode でビルド
- **OOMBoundary-Full**: Full Mode でビルド

⌘R で実行！

詳細: [Xcode スキーム設定ガイド](XCODE_SCHEME_SETUP.md)

---

## コマンドライン（上級者向け）

### Soft Mode に切り替え

```bash
export MEMORY_ENFORCEMENT_MODE=soft
./Scripts/switch-memory-enforcement.sh
xcodebuild -scheme OOMBoundary -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Full Mode に切り替え

```bash
export MEMORY_ENFORCEMENT_MODE=full
./Scripts/switch-memory-enforcement.sh
xcodebuild -scheme OOMBoundary -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Xcodeでの切り替え

### 方法1: スキーム経由（推奨）

1. **Edit Scheme** (⌘<)
2. **Build > Pre-actions** に移動
3. 以下のスクリプトを追加:
   ```bash
   export MEMORY_ENFORCEMENT_MODE=full  # または soft
   ${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh
   ```
4. **Provide build settings from:** で "OOMBoundary" を選択
5. ビルド (⌘B)

### 方法2: 直接編集

`OOMBoundary/OOMBoundary.entitlements` を直接編集:

**Soft Mode:**
```xml
<key>com.apple.security.memory-integrity-enforcement</key>
<string>soft</string>
```

**Full Mode:**
```xml
<key>com.apple.security.memory-integrity-enforcement</key>
<string>full</string>
```

保存後、クリーンビルド (⌘⇧K) → ビルド (⌘B)

## 確認方法

アプリを起動 → Memory Integrity Enforcement セクション:

```
Enforcement Mode: Full Mode ⭐  ← Full Mode
Enforcement Mode: Soft Mode     ← Soft Mode
```

## ファイル一覧

```
プロジェクト/
├── OOMBoundary/
│   ├── OOMBoundary.entitlements        # 実際に使用されるファイル（自動生成）
│   ├── OOMBoundary-Full.entitlements   # Full Mode用テンプレート
│   └── OOMBoundary-Soft.entitlements   # Soft Mode用テンプレート
├── Scripts/
│   └── switch-memory-enforcement.sh    # 切り替えスクリプト
└── Configs/
    ├── Debug-Full.xcconfig              # Debug + Full Mode
    ├── Debug-Soft.xcconfig              # Debug + Soft Mode
    ├── Release-Full.xcconfig            # Release + Full Mode
    └── Release-Soft.xcconfig            # Release + Soft Mode
```

## トラブルシューティング

### モードが変わらない
```bash
# クリーンビルド
rm -rf ~/Library/Developer/Xcode/DerivedData/OOMBoundary-*
xcodebuild clean
```

### スクリプトが実行できない
```bash
chmod +x Scripts/switch-memory-enforcement.sh
```

---

詳細は [MEMORY_ENFORCEMENT_GUIDE.md](MEMORY_ENFORCEMENT_GUIDE.md) を参照してください。

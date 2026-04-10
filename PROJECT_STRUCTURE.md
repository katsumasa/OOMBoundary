# OOMBoundary プロジェクト構造

このドキュメントは、OOMBoundaryプロジェクトのファイル構造と各ファイルの役割を説明します。

## ディレクトリ構造

```
OOMBoundary/
├── OOMBoundary/                      # メインアプリケーション
│   ├── OOMBoundaryApp.swift         # アプリエントリーポイント
│   ├── ContentView.swift            # メインUI
│   ├── MemoryAllocator.swift        # メモリ確保ロジック
│   ├── MetricReporter.swift         # MetricKit統合
│   ├── MemoryIntegrityChecker.swift # メモリ保護機能チェック
│   ├── OOMBoundary.entitlements     # 実際に使用されるEntitlements（自動生成）
│   ├── OOMBoundary-Soft.entitlements    # Soft Mode用テンプレート
│   ├── OOMBoundary-Full.entitlements    # Full Mode用テンプレート
│   └── OOMBoundary-Bridging-Header.h    # Objective-C ブリッジング
│
├── Scripts/                          # 自動化スクリプト
│   ├── bump-version.sh              # Version番号更新
│   ├── build.sh                     # モード指定ビルド
│   ├── switch-memory-enforcement.sh # Entitlements切り替え
│   └── setup-xcode-schemes.sh       # Xcodeスキーム自動設定
│
├── Configs/                          # Build Configurations
│   ├── Debug-Soft.xcconfig          # Debug + Soft Mode
│   ├── Debug-Full.xcconfig          # Debug + Full Mode
│   ├── Release-Soft.xcconfig        # Release + Soft Mode
│   └── Release-Full.xcconfig        # Release + Full Mode
│
├── .github/workflows/                # GitHub Actions
│   └── release.yml                  # 自動ビルド・リリース
│
├── OOMBoundary.xcodeproj/           # Xcodeプロジェクト
│   └── xcshareddata/schemes/        # 共有スキーム
│       ├── OOMBoundary.xcscheme     # Soft Modeスキーム
│       └── OOMBoundary-Full.xcscheme # Full Modeスキーム
│
└── ドキュメント/
    ├── README.md                     # プロジェクト概要
    ├── QUICK_START.md                # クイックスタートガイド
    ├── RELEASE_PROCESS.md            # リリース手順
    ├── VERSION_MANAGEMENT.md         # Version/Build管理
    ├── MEMORY_ENFORCEMENT_GUIDE.md   # モード切り替えガイド（日本語）
    ├── MEMORY_ENFORCEMENT_GUIDE_EN.md # モード切り替えガイド（英語）
    ├── XCODE_SCHEME_SETUP.md         # Xcodeスキーム設定ガイド
    └── PROJECT_STRUCTURE.md          # このファイル
```

---

## 主要ファイルの説明

### アプリケーションコード

#### `OOMBoundary/OOMBoundaryApp.swift`
- **役割**: アプリのエントリーポイント
- **内容**: SwiftUI App プロトコル実装、MetricKit初期化

#### `OOMBoundary/ContentView.swift`
- **役割**: メインUI画面
- **内容**: 
  - デバイス情報表示
  - Memory Integrity Enforcement状態表示
  - メモリ確保コントロール
  - リアルタイムメモリ情報表示
  - Version/Build/Mode表示

#### `OOMBoundary/MemoryAllocator.swift`
- **役割**: メモリ確保・管理ロジック
- **内容**:
  - Dirty/Clean メモリの確保
  - メモリフットプリント計測
  - OOM検知
  - UserDefaultsへの永続化

#### `OOMBoundary/MetricReporter.swift`
- **役割**: MetricKit統合
- **内容**:
  - OSからのピークメモリ取得
  - OOM診断情報の取得

#### `OOMBoundary/MemoryIntegrityChecker.swift`
- **役割**: メモリ保護機能の検証
- **内容**:
  - Code Signingフラグチェック
  - W^X保護テスト
  - PAC対応確認
  - Enforcement Mode検出（Full/Soft）

---

### Entitlements

#### `OOMBoundary/OOMBoundary.entitlements`
- **役割**: 実際にビルドで使用されるEntitlements
- **管理**: スクリプトによって自動生成・更新
- **注意**: 手動編集しない（テンプレートから自動コピーされる）

#### `OOMBoundary/OOMBoundary-Soft.entitlements`
- **役割**: Soft Mode用テンプレート
- **内容**:
  ```xml
  <key>com.apple.security.memory-integrity-enforcement</key>
  <string>soft</string>
  ```

#### `OOMBoundary/OOMBoundary-Full.entitlements`
- **役割**: Full Mode用テンプレート
- **内容**:
  ```xml
  <key>com.apple.security.memory-integrity-enforcement</key>
  <string>full</string>
  ```

---

### スクリプト

#### `Scripts/bump-version.sh`
- **役割**: Version/Build番号の更新
- **使い方**:
  ```bash
  ./Scripts/bump-version.sh major  # 1.x → 2.0
  ./Scripts/bump-version.sh minor  # 1.1 → 1.2
  ./Scripts/bump-version.sh patch  # 1.1.0 → 1.1.1
  ```
- **機能**:
  - 対話的なVersion更新
  - Build番号自動インクリメント
  - Gitコミット・タグ作成（オプション）

#### `Scripts/build.sh`
- **役割**: モードを指定してビルド
- **使い方**:
  ```bash
  ./Scripts/build.sh [soft|full] [device|simulator] [debug|release]
  ```
- **例**:
  ```bash
  ./Scripts/build.sh soft simulator debug
  ./Scripts/build.sh full device release
  ```

#### `Scripts/switch-memory-enforcement.sh`
- **役割**: Entitlementsファイルの切り替え
- **使い方**:
  ```bash
  export MEMORY_ENFORCEMENT_MODE=full
  ./Scripts/switch-memory-enforcement.sh
  ```
- **動作**:
  - テンプレートから `OOMBoundary.entitlements` にコピー

#### `Scripts/setup-xcode-schemes.sh`
- **役割**: Xcodeスキームの自動設定
- **使い方**:
  ```bash
  ./Scripts/setup-xcode-schemes.sh
  ```
- **動作**:
  - `OOMBoundary.xcscheme` 作成（Soft Mode）
  - `OOMBoundary-Full.xcscheme` 作成（Full Mode）
  - Pre-actionスクリプトを設定

---

### Build Configurations

#### `Configs/*.xcconfig`
- **役割**: Xcodeビルド設定の定義
- **使い方**: Xcodeプロジェクト設定で適用
- **内容**:
  - Entitlementsファイルパス指定
  - コンパイラフラグ設定
  - プロダクト名設定

**注意**: 現在は未適用。将来的にXcodeプロジェクトに統合可能。

---

### GitHub Actions

#### `.github/workflows/release.yml`
- **役割**: 自動ビルド・リリース
- **トリガー**:
  - Git タグのプッシュ（`v*.*.*`）
  - 手動トリガー
- **動作**:
  1. Soft/Full を並列ビルド
  2. IPA生成
  3. GitHub Release作成
  4. 両方のIPAを添付

---

### Xcodeスキーム

#### `OOMBoundary.xcscheme`
- **役割**: Soft Modeビルド用スキーム
- **Pre-action**: `export MEMORY_ENFORCEMENT_MODE=soft`

#### `OOMBoundary-Full.xcscheme`
- **役割**: Full Modeビルド用スキーム
- **Pre-action**: `export MEMORY_ENFORCEMENT_MODE=full`

---

## ドキュメント

### `README.md`
- **役割**: プロジェクト概要・使い方
- **内容**:
  - 機能説明
  - ビルド方法
  - 技術的詳細
  - Memory Integrity Enforcement概要

### `QUICK_START.md`
- **役割**: すぐに始めるための最小限の情報
- **対象**: 初めて使う人

### `RELEASE_PROCESS.md`
- **役割**: 詳細なリリース手順
- **内容**:
  - 手動リリース手順
  - GitHub Actions使用方法
  - Version番号の決め方
  - トラブルシューティング

### `VERSION_MANAGEMENT.md`
- **役割**: Version/Build管理システムの説明
- **内容**:
  - 実装方針の説明
  - セマンティックバージョニング
  - 自動化の仕組み
  - ベストプラクティス

### `MEMORY_ENFORCEMENT_GUIDE.md` / `_EN.md`
- **役割**: Memory Enforcement Mode切り替えガイド
- **内容**:
  - Full/Soft Modeの違い
  - 切り替え方法（4通り）
  - Xcodeでの設定
  - コマンドライン使用方法

### `XCODE_SCHEME_SETUP.md`
- **役割**: Xcodeスキーム設定の詳細ガイド
- **内容**:
  - スクリーンショット風の図解
  - ステップバイステップ手順
  - トラブルシューティング
  - FAQ

### `PROJECT_STRUCTURE.md`
- **役割**: このファイル
- **内容**: プロジェクト構造の全体像

---

## ワークフロー

### 開発フロー

```
1. develop ブランチで開発
   ├── Xcode で OOMBoundary スキーム選択
   └── ⌘R で実行（Soft Mode）

2. Full Mode でテスト
   ├── Xcode で OOMBoundary-Full スキーム選択
   └── ⌘R で実行（Full Mode）

3. コミット & プッシュ
   └── git push origin develop
```

### リリースフロー

```
1. Version 更新
   └── ./Scripts/bump-version.sh minor

2. main にマージ
   ├── git checkout main
   ├── git merge develop
   └── git push origin main

3. タグプッシュ
   └── git push origin v1.2.0

4. GitHub Actions が自動実行
   ├── Soft Mode ビルド
   ├── Full Mode ビルド
   └── GitHub Release 作成
```

---

## 依存関係

### ビルド時

```
bump-version.sh
    ↓ 使用
agvtool (Xcode Tools)

build.sh
    ↓ 呼び出し
switch-memory-enforcement.sh
    ↓ コピー
OOMBoundary-[Soft|Full].entitlements → OOMBoundary.entitlements

Xcode スキーム
    ↓ Pre-action
switch-memory-enforcement.sh
    ↓ コピー
Entitlements
```

### 実行時

```
アプリ起動
    ↓
MemoryIntegrityChecker
    ↓ 検出
- Code Signing Flags
- W^X Protection
- PAC Support
- Enforcement Mode
    ↓ 表示
ContentView
```

---

## Git管理対象

### コミット対象

✅ **含める:**
- ソースコード（`OOMBoundary/*.swift`）
- Entitlementsテンプレート（`*-Soft.entitlements`, `*-Full.entitlements`）
- スクリプト（`Scripts/*.sh`）
- ドキュメント（`*.md`）
- Xcodeスキーム（`*.xcscheme`）
- GitHub Actions（`.github/workflows/*.yml`）
- Build Configurations（`Configs/*.xcconfig`）

❌ **除外:**
- ビルド成果物（`build/`, `DerivedData/`）
- 自動生成ファイル（`OOMBoundary.entitlements`）
- ユーザー設定（`*.xcuserdata`）
- `.DS_Store`

### .gitignore 推奨設定

```gitignore
# Xcode
build/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Auto-generated Entitlements
OOMBoundary/OOMBoundary.entitlements

# OS
.DS_Store
```

---

## 拡張性

### 新しいモードを追加する場合

1. Entitlementsテンプレートを作成:
   ```bash
   cp OOMBoundary/OOMBoundary-Soft.entitlements \
      OOMBoundary/OOMBoundary-Custom.entitlements
   ```

2. `switch-memory-enforcement.sh` を修正:
   ```bash
   case "${MODE}" in
       custom|CUSTOM|Custom)
           SOURCE="${ENTITLEMENTS_DIR}/OOMBoundary-Custom.entitlements"
           ;;
   esac
   ```

3. Xcodeスキームを追加（オプション）

---

## まとめ

このプロジェクトは以下の3層構造：

```
┌─────────────────────────────┐
│  アプリケーション層         │
│  (Swift コード)             │
└─────────────────────────────┘
            ↓
┌─────────────────────────────┐
│  ビルド設定層               │
│  (Entitlements, Schemes)    │
└─────────────────────────────┘
            ↓
┌─────────────────────────────┐
│  自動化層                   │
│  (Scripts, GitHub Actions)  │
└─────────────────────────────┘
```

各層が独立しているため、必要に応じて個別に変更・拡張可能です。

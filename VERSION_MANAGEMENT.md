# Version & Build 管理システム

## 実装済みの自動化

### 📁 作成したファイル

```
Scripts/
├── bump-version.sh              # Version番号更新スクリプト
├── build.sh                     # モード指定ビルドスクリプト
└── switch-memory-enforcement.sh # Entitlements切り替え（既存）

.github/workflows/
└── release.yml                  # GitHub Actions 自動ビルド・リリース

ドキュメント/
├── RELEASE_PROCESS.md           # リリース手順書
├── VERSION_MANAGEMENT.md        # このファイル
├── MEMORY_ENFORCEMENT_GUIDE.md  # モード切り替えガイド
└── QUICK_START.md               # クイックスタート
```

---

## 🎯 実装方針（確定）

### Q1: Version 更新タイミング
**✅ A. リリース直前（main マージ前）**

```
develop で開発 → Version 更新 → main にマージ → タグプッシュ
```

### Q2: Build 番号管理
**✅ C. CI/CD で自動インクリメント**

```
Build 番号 = Git コミット数（自動）
```

### Q3: Soft/Full の Version
**✅ 同じ Version を使用**

```
OOMBoundary 1.2.0 (Soft Mode Build)
OOMBoundary 1.2.0 (Full Mode Build)
```

---

## 🚀 使い方

### 開発中

```bash
# 通常は develop ブランチで開発
git checkout develop

# Soft Mode でテスト
./Scripts/build.sh soft simulator debug

# Full Mode でテスト
./Scripts/build.sh full simulator debug
```

### リリース準備

```bash
# 1. Version を決定（セマンティックバージョニング）
#    - 新機能 → minor
#    - バグ修正 → patch
#    - 破壊的変更 → major

# 2. Version 更新（例: Minor バージョンアップ）
./Scripts/bump-version.sh minor

# 出力例:
# Current Version: 1.1.0
# New Version:     1.2.0
# Build:           45 → 46

# 3. README.md のバージョンバッジを更新
sed -i '' 's/version-[0-9]\+\.[0-9]\+-blue/version-1.2-blue/' README.md
git add README.md
git commit -m "Update version badge in README to 1.2"
```

### リリース実行

```bash
# 3. main にマージ
git checkout main
git merge develop
git push origin main

# 4. タグをプッシュ
git push origin v1.2.0
```

**GitHub Actions が自動実行！**
- ✅ Soft Mode ビルド（Version 1.2.0, Build = commit数）
- ✅ Full Mode ビルド（Version 1.2.0, Build = commit数）
- ✅ GitHub Release 作成
- ✅ 両方の IPA を添付

---

## 📊 Version 番号の体系

### セマンティックバージョニング

```
Major . Minor . Patch
  1   .   2   .   3

例: 1.2.3
```

### 使い分け

| Type | いつ | 例 | コマンド |
|------|------|-----|---------|
| **Major** | 破壊的変更 | 1.9.0 → 2.0.0 | `./Scripts/bump-version.sh major` |
| **Minor** | 新機能追加 | 1.1.0 → 1.2.0 | `./Scripts/bump-version.sh minor` |
| **Patch** | バグ修正 | 1.1.0 → 1.1.1 | `./Scripts/bump-version.sh patch` |

### Build 番号

- **ローカル**: `bump-version.sh` が自動インクリメント
- **GitHub Actions**: Git コミット数を使用（完全に一意）

---

## 🤖 GitHub Actions

### 自動トリガー

```bash
# v で始まるタグをプッシュすると自動実行
git tag v1.2.0
git push origin v1.2.0
```

### 手動トリガー

1. GitHub の **Actions** タブを開く
2. **Build and Release** を選択
3. **Run workflow** をクリック
4. Version を入力（例: 1.2.0）
5. 実行

### 成果物

```
GitHub Release: v1.2.0
├── OOMBoundary-1.2.0-soft.ipa    # Soft Mode
├── OOMBoundary-1.2.0-full.ipa    # Full Mode
└── Release Notes（自動生成）
```

---

## 🔍 Version 確認方法

### アプリ内で確認

アプリを起動すると、タイトル下に表示：

```
Memory Boundary Tester
Version 1.2.0 (Build 45)
Soft Mode Build
```

### コマンドラインで確認

```bash
# Marketing Version
xcrun agvtool what-marketing-version -terse1

# Build Number
xcrun agvtool what-version -terse
```

### Git タグで確認

```bash
# 最新のタグ
git describe --tags --abbrev=0

# すべてのタグ
git tag -l
```

---

## 📝 リリースチェックリスト

### リリース前

- [ ] develop ブランチですべてのテストが通る
- [ ] Soft Mode でビルド成功
- [ ] Full Mode でビルド成功
- [ ] README.md が最新
- [ ] `bump-version.sh` で Version 更新
- [ ] **README.md のバージョンバッジを更新**
- [ ] Version 番号が適切（セマンティックバージョニング）

### リリース時

- [ ] main ブランチにマージ
- [ ] Git タグを作成（v1.2.0）
- [ ] タグをプッシュ
- [ ] GitHub Actions の実行を確認

### リリース後

- [ ] GitHub Release が作成された
- [ ] 両方の IPA がダウンロード可能
- [ ] Release Notes が正しい
- [ ] develop ブランチを main から更新

---

## 🛠️ トラブルシューティング

### bump-version.sh が動かない

```bash
# 実行権限を確認
ls -la Scripts/bump-version.sh

# 権限を付与
chmod +x Scripts/bump-version.sh
```

### Build 番号がおかしい

```bash
# 手動でリセット
xcrun agvtool new-version -all 1

# または特定の番号に設定
xcrun agvtool new-version -all 100
```

### GitHub Actions が失敗

1. **Actions** タブで詳細ログを確認
2. Xcode バージョンの互換性を確認
3. ローカルで同じコマンドを実行してテスト

---

## 🎓 ベストプラクティス

### Version 管理

✅ **推奨:**
- develop で開発、main にマージ前に Version 更新
- セマンティックバージョニングに従う
- Git タグを必ず作成

❌ **避ける:**
- 開発途中で Version を頻繁に変更
- main ブランチで直接開発
- リリース済み Version の再利用

### Build 番号

✅ **推奨:**
- CI/CD で自動管理（Git コミット数）
- 手動では `bump-version.sh` を使用

❌ **避ける:**
- 手動で直接編集
- Build 番号の重複

### Git タグ

✅ **推奨:**
- `v` プレフィックス付き（v1.2.0）
- Version 番号と一致させる
- アノテーション付きタグ（`git tag -a`）

❌ **避ける:**
- タグなしでリリース
- タグの後からの変更

---

## 📚 関連ドキュメント

- [RELEASE_PROCESS.md](RELEASE_PROCESS.md) - 詳細なリリース手順
- [MEMORY_ENFORCEMENT_GUIDE.md](MEMORY_ENFORCEMENT_GUIDE.md) - モード切り替え詳細
- [QUICK_START.md](QUICK_START.md) - クイックスタート

---

## 💡 クイックリファレンス

```bash
# Version 更新
./Scripts/bump-version.sh [major|minor|patch]

# README.md バッジ更新（バージョン例: 1.2）
sed -i '' 's/version-[0-9]\+\.[0-9]\+-blue/version-1.2-blue/' README.md

# ビルド
./Scripts/build.sh [soft|full] [device|simulator] [debug|release]

# リリース
git tag v1.2.0 && git push origin v1.2.0

# 確認
xcrun agvtool what-marketing-version -terse1  # Version
xcrun agvtool what-version -terse             # Build
git describe --tags                           # Git tag
```

---

**Happy Releasing! 🚀**

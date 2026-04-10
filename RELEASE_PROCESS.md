# OOMBoundary リリースプロセス

このドキュメントは、OOMBoundaryの新バージョンをリリースする手順を説明します。

## 目次

1. [リリースフロー概要](#リリースフロー概要)
2. [手動リリース](#手動リリース)
3. [自動リリース（GitHub Actions）](#自動リリースgithub-actions)
4. [バージョン番号の決め方](#バージョン番号の決め方)
5. [トラブルシューティング](#トラブルシューティング)

---

## リリースフロー概要

```
develop ブランチ
    ↓ 開発・テスト
    ↓
main へマージ準備
    ↓
Version 更新（例: 1.1 → 1.2）
    ↓
main にマージ
    ↓
Git タグ作成（v1.2.0）
    ↓
GitHub Actions が自動実行
    ↓ ビルド（Soft & Full 並列）
    ↓
GitHub Release 作成
    ├── OOMBoundary-1.2.0-soft.ipa
    └── OOMBoundary-1.2.0-full.ipa
```

---

## 手動リリース

### 前提条件

- Xcode がインストールされている
- コマンドラインツールがインストールされている
- main ブランチにマージ権限がある

### ステップ 1: Version の決定

次のバージョン番号を決定します。[セマンティックバージョニング](#バージョン番号の決め方)に従います。

例:
- 新機能追加 → Minor バージョンアップ（1.1 → 1.2）
- バグ修正 → Patch バージョンアップ（1.1.0 → 1.1.1）
- 破壊的変更 → Major バージョンアップ（1.x → 2.0）

### ステップ 2: develop ブランチで最終確認

```bash
git checkout develop
git pull origin develop

# 最新の状態でビルドテスト
./Scripts/build.sh soft simulator debug
./Scripts/build.sh full simulator debug
```

### ステップ 3: Version を更新

```bash
# Minor バージョンアップの場合
./Scripts/bump-version.sh minor

# Patch バージョンアップの場合
./Scripts/bump-version.sh patch

# Major バージョンアップの場合
./Scripts/bump-version.sh major
```

スクリプトは以下を実行します：
1. Version 番号を更新
2. Build 番号を自動インクリメント
3. 変更をコミット（オプション）
4. Git タグを作成（オプション）

### ステップ 3.5: README.md のバージョンバッジを更新

**重要:** バージョンを更新したら、必ず README.md のバージョンバッジも更新してください。

```bash
# README.md を編集
# 3行目のバージョンバッジを更新
# 例: version-1.2-blue → version-1.3-blue
sed -i '' 's/version-[0-9]\+\.[0-9]\+-blue/version-1.3-blue/' README.md

# 変更を確認
git diff README.md

# コミット
git add README.md
git commit -m "Update version badge in README to 1.3"
```

または手動で編集：
```markdown
# 変更前
![Version](https://img.shields.io/badge/version-1.2-blue)

# 変更後
![Version](https://img.shields.io/badge/version-1.3-blue)
```

### ステップ 4: main にマージ

```bash
# develop ブランチから main へのプルリクエストを作成
gh pr create --base main --head develop \
  --title "Release v1.2.0" \
  --body "Release version 1.2.0"

# またはローカルでマージ
git checkout main
git merge develop
git push origin main
```

### ステップ 5: Git タグをプッシュ

```bash
# タグを作成（bump-version.sh で作成していない場合）
git tag v1.2.0

# タグをプッシュ
git push origin v1.2.0
```

**GitHub Actions が自動的に実行されます！**

### ステップ 6: Release の確認

1. GitHub のリポジトリページを開く
2. **Actions** タブで進行状況を確認
3. 完了後、**Releases** に自動的に作成される

---

## 自動リリース（GitHub Actions）

### タグのプッシュで自動実行

```bash
git tag v1.2.0
git push origin v1.2.0
```

GitHub Actions が以下を自動実行：
1. ✅ Soft Mode ビルド（Version 1.2.0）
2. ✅ Full Mode ビルド（Version 1.2.0）
3. ✅ 両方の IPA を生成
4. ✅ GitHub Release を作成
5. ✅ IPA ファイルを添付

### 手動トリガー（オプション）

GitHub の **Actions** タブから手動で実行可能：

1. **Actions** タブを開く
2. **Build and Release** ワークフローを選択
3. **Run workflow** をクリック
4. Version を入力（例: 1.2.0）
5. **Run workflow** を実行

### ビルド成果物

各リリースには以下のファイルが含まれます：

```
Release v1.2.0
├── OOMBoundary-1.2.0-soft.ipa    # Soft Mode ビルド
└── OOMBoundary-1.2.0-full.ipa    # Full Mode ビルド
```

---

## バージョン番号の決め方

### セマンティックバージョニング

```
Major.Minor.Patch
  2  . 1   .  3

例: 2.1.3
```

### いつ何を上げるか

| Version | いつ上げるか | 例 |
|---------|------------|-----|
| **Major** | 破壊的変更、互換性のない変更 | 1.9.0 → 2.0.0 |
| **Minor** | 新機能追加、下位互換性あり | 1.1.0 → 1.2.0 |
| **Patch** | バグ修正、小さな改善 | 1.1.0 → 1.1.1 |

### 具体例

#### Major バージョンアップ（2.0.0）
- UIの大幅な刷新
- 最小サポートOSバージョンの変更（iOS 17 → iOS 18）
- APIの破壊的変更

#### Minor バージョンアップ（1.2.0）
- Memory Integrity Enforcement 機能の追加 ✅（今回の実装）
- 新しいメモリタイプの追加
- MetricKit 統合の追加

#### Patch バージョンアップ（1.1.1）
- クラッシュの修正
- UIの小さな調整
- パフォーマンス改善

### Build 番号

Build 番号は**自動的に**管理されます：
- GitHub Actions: Git のコミット数
- 手動ビルド: `bump-version.sh` が自動インクリメント

---

## ローカルビルド（開発用）

### Soft Mode でビルド

```bash
# Simulator
./Scripts/build.sh soft simulator debug

# Device
./Scripts/build.sh soft device release
```

### Full Mode でビルド

```bash
# Simulator
./Scripts/build.sh full simulator debug

# Device
./Scripts/build.sh full device release
```

### 直接ビルド（スクリプトなし）

```bash
# Soft Mode に切り替え
export MEMORY_ENFORCEMENT_MODE=soft
./Scripts/switch-memory-enforcement.sh

# ビルド
xcodebuild -scheme OOMBoundary -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

---

## トラブルシューティング

### Version が更新されない

**原因:** agvtool が正しく設定されていない

**解決策:**
```bash
# プロジェクト設定を確認
xcodebuild -project OOMBoundary.xcodeproj -showBuildSettings | grep VERSIONING

# 手動で更新
xcrun agvtool new-marketing-version 1.2.0
xcrun agvtool new-version -all 123
```

### GitHub Actions が失敗する

**原因1:** コード署名の問題

**解決策:**
- GitHub Actions は署名なしでビルド
- ローカルでテストする場合は署名設定を確認

**原因2:** Xcode バージョンの不一致

**解決策:**
- `.github/workflows/release.yml` の `xcode-version` を確認

### タグをプッシュしても Actions が動かない

**原因:** ワークフローファイルが main ブランチにない

**解決策:**
```bash
# .github/workflows/release.yml が main にあるか確認
git checkout main
ls -la .github/workflows/
```

### IPA の生成に失敗する

**原因:** エクスポート設定の問題

**解決策:**
- GitHub Actions は zip ファイルもフォールバックとして作成
- ローカルでは Xcode から直接エクスポート

---

## クイックリファレンス

### リリースコマンド（推奨フロー）

```bash
# 1. develop で開発
git checkout develop

# 2. Version 更新（例: Minor バージョンアップ）
./Scripts/bump-version.sh minor
# → 対話的にコミット & タグ作成

# 3. README.md のバージョンバッジを更新
sed -i '' 's/version-[0-9]\+\.[0-9]\+-blue/version-1.2-blue/' README.md
git add README.md
git commit -m "Update version badge in README to 1.2"

# 4. main にマージ
git checkout main
git merge develop
git push origin main

# 5. タグをプッシュ（GitHub Actions が自動実行）
git push origin v1.2.0

# 6. Release を確認
open https://github.com/yourusername/OOMBoundary/releases
```

### 緊急ホットフィックス

```bash
# main から直接修正
git checkout main
git checkout -b hotfix/1.1.1

# 修正をコミット
git commit -am "Fix critical bug"

# Version 更新（Patch）
./Scripts/bump-version.sh patch

# README.md のバージョンバッジを更新
sed -i '' 's/version-[0-9]\+\.[0-9]\+-blue/version-1.1.1-blue/' README.md
git add README.md
git commit -m "Update version badge in README to 1.1.1"

# main にマージ & タグプッシュ
git checkout main
git merge hotfix/1.1.1
git push origin main
git push origin v1.1.1

# develop にも反映
git checkout develop
git merge main
git push origin develop
```

---

## チェックリスト

リリース前に確認：

- [ ] すべてのテストが通る
- [ ] Soft Mode でビルド成功
- [ ] Full Mode でビルド成功
- [ ] README.md が最新
- [ ] **README.md のバージョンバッジを更新**
- [ ] CHANGELOG.md を更新（あれば）
- [ ] Version 番号が適切
- [ ] Git タグが作成済み
- [ ] main ブランチにマージ済み

リリース後に確認：

- [ ] GitHub Release が作成された
- [ ] IPA ファイルがダウンロード可能
- [ ] Release Notes が正しい
- [ ] develop ブランチを最新に保つ

---

**ヒント:** 
- リリースは金曜日を避ける（問題発生時の対応が難しい）
- 大きな変更は Beta リリースを検討
- Version 番号は一度リリースしたら変更しない

Happy Releasing! 🚀

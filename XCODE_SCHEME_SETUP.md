# Xcode スキーム設定ガイド

このガイドでは、XcodeでSoft ModeとFull Modeを簡単に切り替えられるようにスキームを設定する方法を、ステップバイステップで説明します。

## 目次

1. [自動セットアップ（推奨）](#自動セットアップ推奨)
2. [手動セットアップ](#手動セットアップ)
3. [使い方](#使い方)
4. [トラブルシューティング](#トラブルシューティング)

---

## 自動セットアップ（推奨）

### コマンド1つで完了

```bash
./Scripts/setup-xcode-schemes.sh
```

**実行結果:**
```
🔧 Setting up Xcode Schemes

✅ Created OOMBoundary scheme (Soft Mode)
✅ Created OOMBoundary-Full scheme (Full Mode)

📝 Schemes created:
   • OOMBoundary      (Soft Mode)
   • OOMBoundary-Full (Full Mode)
```

このスクリプトは以下を自動的に作成します:
- ✅ `OOMBoundary` スキーム（Soft Mode用）
- ✅ `OOMBoundary-Full` スキーム（Full Mode用）
- ✅ Pre-actionスクリプトの設定

### 確認方法

Xcodeを開いて、ツールバーでスキームを確認:

```
┌─────────────────────────────────┐
│ OOMBoundary      ▼  iPhone 17   │
└─────────────────────────────────┘
         ↓ クリック
┌─────────────────────────────────┐
│ ✓ OOMBoundary                   │  ← Soft Mode
│   OOMBoundary-Full              │  ← Full Mode
│   ────────────────              │
│   Manage Schemes...             │
└─────────────────────────────────┘
```

---

## 手動セットアップ

自動セットアップが動作しない場合は、以下の手順で手動設定してください。

### ステップ 1: Xcodeでプロジェクトを開く

```bash
open OOMBoundary.xcodeproj
```

---

### ステップ 2: スキーム管理画面を開く

**方法A: メニューバーから**
```
Product > Scheme > Manage Schemes...
```

**方法B: キーボードショートカット**
```
⌘ < (Command + Shift + ,)
```

**方法C: ツールバーから**
```
ツールバーのスキーム名をクリック > Manage Schemes...
```

**画面イメージ:**
```
┌─────────────────────────────────────────────────┐
│  Manage Schemes                            × ⚙  │
├─────────────────────────────────────────────────┤
│  ☐ OOMBoundary              OOMBoundary.xcod... │
│  ☐ OOMBoundaryTests         OOMBoundary.xcod... │
│  ☐ OOMBoundaryUITests       OOMBoundary.xcod... │
│                                                  │
│  [ Show ] All Schemes  Container: OOMBoundary   │
│                                                  │
│                                    [   Close   ] │
└─────────────────────────────────────────────────┘
          ↑
     ここで OOMBoundary にチェック（Shared）
```

---

### ステップ 3: スキームを複製

1. **OOMBoundary** スキームを選択
2. 画面下部の **歯車アイコン ⚙** をクリック
3. **Duplicate** を選択

**画面イメージ:**
```
OOMBoundary を選択した状態で...

┌──────────────┐
│ ⚙ メニュー   │
├──────────────┤
│ Duplicate    │  ← これをクリック
│ Delete       │
│ Show in...   │
└──────────────┘
```

---

### ステップ 4: 新しいスキームの名前を変更

1. 複製されたスキーム名をダブルクリック
2. **OOMBoundary copy** → **OOMBoundary-Full** に変更
3. **Shared** にチェックを入れる
4. **Close** をクリック

**画面イメージ:**
```
┌─────────────────────────────────────────────────┐
│  Manage Schemes                            × ⚙  │
├─────────────────────────────────────────────────┤
│  ☑ OOMBoundary              OOMBoundary.xcod... │
│  ☑ OOMBoundary-Full         OOMBoundary.xcod... │ ← 名前変更 & Sharedにチェック
│  ☐ OOMBoundaryTests         OOMBoundary.xcod... │
│                                                  │
│  [ Show ] All Schemes  Container: OOMBoundary   │
│                                                  │
│                                    [   Close   ] │
└─────────────────────────────────────────────────┘
```

---

### ステップ 5: Full Mode スキームを編集

1. ツールバーで **OOMBoundary-Full** を選択
2. **Product** > **Scheme** > **Edit Scheme...** (⌘<)

**画面イメージ:**
```
┌─────────────────────────────────────────────────┐
│  Edit Scheme - OOMBoundary-Full            × ⚙  │
├──────────┬──────────────────────────────────────┤
│ Build    │  Info  Arguments  Options             │ ← Buildを選択
│ Run      │                                        │
│ Test     │  ▼ Pre-actions                        │ ← Pre-actionsを展開
│ Profile  │     + New Run Script Action           │ ← +をクリック
│ Analyze  │                                        │
│ Archive  │  ▼ Post-actions                       │
└──────────┴──────────────────────────────────────┘
```

---

### ステップ 6: Pre-action スクリプトを追加

1. **Pre-actions** セクションを展開
2. **+** ボタンをクリック
3. **New Run Script Action** を選択

**画面イメージ:**
```
┌─────────────────────────────────────────────────┐
│  ▼ Pre-actions                                   │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │ Run Script                              ⊗  │ │
│  │                                            │ │
│  │ ┌────────────────────────────────────────┐│ │
│  │ │ export MEMORY_ENFORCEMENT_MODE=full    ││ │ ← ここにスクリプト入力
│  │ │ ${PROJECT_DIR}/Scripts/switch-memory-  ││ │
│  │ │ enforcement.sh                         ││ │
│  │ └────────────────────────────────────────┘│ │
│  │                                            │ │
│  │ Provide build settings from:              │ │
│  │ [ OOMBoundary                          ▼] │ │ ← OOMBoundaryを選択
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**入力するスクリプト:**
```bash
export MEMORY_ENFORCEMENT_MODE=full
${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh
```

4. **Provide build settings from** で **OOMBoundary** を選択
5. **Close** をクリック

---

### ステップ 7: Soft Mode スキームも設定（オプション）

同様の手順で **OOMBoundary** スキームにも設定:

1. ツールバーで **OOMBoundary** を選択
2. **Edit Scheme...** (⌘<)
3. **Build** > **Pre-actions** > **+**
4. スクリプトを入力:

```bash
export MEMORY_ENFORCEMENT_MODE=soft
${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh
```

5. **Provide build settings from**: **OOMBoundary**
6. **Close**

---

## 使い方

### スキームの切り替え

#### ツールバーで選択

```
┌─────────────────────────────────────────────┐
│  Xcode ツールバー                           │
├─────────────────────────────────────────────┤
│  [▶] [ OOMBoundary ▼ ] [ iPhone 17 Pro ▼ ] │ ← ここをクリック
└─────────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────────┐
│  ✓ OOMBoundary                              │ ← Soft Mode
│    OOMBoundary-Full                         │ ← Full Mode
│  ─────────────────                          │
│    Manage Schemes...                        │
└─────────────────────────────────────────────┘
```

#### または、メニューから

```
Product > Scheme > OOMBoundary       (Soft Mode)
Product > Scheme > OOMBoundary-Full  (Full Mode)
```

---

### ビルド・実行

スキームを選択したら、通常通りビルド・実行:

```
⌘ B  - Build
⌘ R  - Run
⌘ U  - Test
⌘ I  - Profile
```

---

### ビルド時の動作確認

#### Soft Mode (OOMBoundary スキーム)

ビルドを開始すると、**Report Navigator** に表示:

```
┌─────────────────────────────────────────────┐
│  ▼ Build OOMBoundary                        │
│    ▼ Pre-actions                            │
│      🔧 Switching Memory Enforcement...     │
│      ✅ Using Soft Mode entitlements        │
│    ▼ Compile Sources                        │
│      ...                                    │
└─────────────────────────────────────────────┘
```

#### Full Mode (OOMBoundary-Full スキーム)

```
┌─────────────────────────────────────────────┐
│  ▼ Build OOMBoundary-Full                   │
│    ▼ Pre-actions                            │
│      🔧 Switching Memory Enforcement...     │
│      ✅ Using Full Mode entitlements        │
│    ▼ Compile Sources                        │
│      ...                                    │
└─────────────────────────────────────────────┘
```

---

### アプリでの確認

ビルドしたアプリを起動すると、タイトル下に表示:

#### Soft Mode でビルドした場合

```
┌─────────────────────────────────────┐
│                                     │
│    Memory Boundary Tester           │
│    Version 1.1 (Build 2)            │
│    Soft Mode Build                  │ ← これを確認
│                                     │
└─────────────────────────────────────┘
```

#### Full Mode でビルドした場合

```
┌─────────────────────────────────────┐
│                                     │
│    Memory Boundary Tester           │
│    Version 1.1 (Build 2)            │
│    ⭐ Full Mode Build               │ ← これを確認
│                                     │
└─────────────────────────────────────┘
```

---

## トラブルシューティング

### スキームが表示されない

**原因:** スキームファイルが正しく生成されていない

**解決策:**
1. Xcodeを完全に終了
2. スクリプトを再実行:
   ```bash
   ./Scripts/setup-xcode-schemes.sh
   ```
3. Xcodeを再起動
4. **Product** > **Scheme** でスキームを確認

---

### Pre-action が実行されない

**原因:** スクリプトのパスが正しくない

**解決策:**
1. **Edit Scheme** > **Build** > **Pre-actions**
2. スクリプト内容を確認:
   ```bash
   export MEMORY_ENFORCEMENT_MODE=full
   ${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh
   ```
3. **Provide build settings from** が **OOMBoundary** になっているか確認

---

### スクリプトの実行権限エラー

**エラー:**
```
/path/to/switch-memory-enforcement.sh: Permission denied
```

**解決策:**
```bash
chmod +x Scripts/switch-memory-enforcement.sh
```

---

### Mode が切り替わらない

**原因:** Entitlements ファイルがキャッシュされている

**解決策:**
1. **Product** > **Clean Build Folder** (⌘⇧K)
2. DerivedData を削除:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/OOMBoundary-*
   ```
3. 再ビルド

---

### ビルド時にスクリプトが見つからない

**エラー:**
```
/path/to/Scripts/switch-memory-enforcement.sh: No such file or directory
```

**解決策:**

スクリプトのパスを絶対パスで指定:
```bash
export MEMORY_ENFORCEMENT_MODE=full
"${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh"
```

または、直接スクリプトの内容を記述:
```bash
export MEMORY_ENFORCEMENT_MODE=full
if [ -f "${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh" ]; then
    "${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh"
else
    echo "Script not found!"
    exit 1
fi
```

---

## よくある質問

### Q: 両方のスキームを設定する必要がありますか？

**A:** いいえ、最低限 **OOMBoundary-Full** だけ設定すれば、Soft/Full を切り替えられます。
- **OOMBoundary**: デフォルト（手動で Entitlements を切り替え）
- **OOMBoundary-Full**: Full Mode（自動切り替え）

ただし、両方設定すれば完全自動化できます。

---

### Q: スキームの設定は Git に含めるべきですか？

**A:** はい、**Shared** にチェックを入れると、`.xcodeproj/xcshareddata/schemes/` に保存され、チームで共有できます。

```bash
git add OOMBoundary.xcodeproj/xcshareddata/schemes/
git commit -m "Add Xcode schemes for Soft/Full mode"
```

---

### Q: Release ビルドでも動作しますか？

**A:** はい、Pre-action は Debug/Release どちらでも実行されます。

---

### Q: CI/CD でも使えますか？

**A:** はい、コマンドラインでスキームを指定できます:

```bash
# Soft Mode
xcodebuild -scheme OOMBoundary ...

# Full Mode
xcodebuild -scheme OOMBoundary-Full ...
```

---

## クイックリファレンス

### 自動セットアップ

```bash
./Scripts/setup-xcode-schemes.sh
```

### スキーム切り替え（Xcode）

```
ツールバー > スキーム名 ▼ > 選択
```

### ビルド・実行

```
⌘B  ビルド
⌘R  実行
⌘U  テスト
```

### 確認

```
アプリ起動 > タイトル下の "Soft Mode Build" / "Full Mode Build" を確認
```

---

## 視覚的フロー

```
┌────────────────────────────────────────────────┐
│  1. Xcode を開く                               │
│     open OOMBoundary.xcodeproj                 │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  2. スキームを選択                             │
│     ツールバー > OOMBoundary-Full              │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  3. ビルド・実行                               │
│     ⌘R (Run)                                   │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  4. Pre-action が自動実行                      │
│     export MEMORY_ENFORCEMENT_MODE=full        │
│     ./Scripts/switch-memory-enforcement.sh     │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  5. Entitlements が Full Mode に切り替わる     │
│     OOMBoundary-Full.entitlements をコピー     │
└────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  6. ビルド完了                                 │
│     Full Mode でビルドされたアプリが起動       │
└────────────────────────────────────────────────┘
```

---

**Happy Building! 🚀**

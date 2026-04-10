# Ad-Hoc配布ガイド

このガイドでは、Xcode Archive経由でAd-Hoc配布用のIPAファイルを作成し、実機にインストールする方法を説明します。

## 目的

Development署名では Full Mode と Soft Mode の挙動に違いが見られませんでした（Code Signing Flags: 0x32003005で同一）。Distribution署名（Ad-Hoc配布）を使用することで、実際の本番環境に近い状態でメモリ保護機能の違いを検証できます。

## 前提条件

- Apple Developer Program の有料会員であること
- テスト対象のiOS実機があること
- Xcodeがインストールされていること

---

## ステップ1: デバイスUDIDの取得と登録

### 1.1 デバイスUDIDの取得

1. **Xcodeで確認する方法（推奨）:**
   - Xcode を開く
   - メニューバー: `Window` > `Devices and Simulators` (⇧⌘2)
   - 左側でテストしたいデバイスを選択
   - 右側の「Identifier」欄に表示されている値がUDID

2. **デバイス本体で確認する方法:**
   - 設定アプリ > 一般 > 情報 > 「デバイス名」を長押し
   - "コピー"を選択

### 1.2 Apple Developer Centerに登録

1. [Apple Developer Center](https://developer.apple.com/account) にログイン
2. 左メニューから `Certificates, Identifiers & Profiles` を選択
3. 左側の `Devices` を選択
4. 右上の `+` ボタンをクリック
5. デバイス情報を入力:
   - **Platform:** iOS, tvOS, watchOS から選択（通常はiOS）
   - **Device Name:** 識別しやすい名前（例: iPhone 17 Pro Test）
   - **Device ID (UDID):** コピーしたUDIDを貼り付け
6. `Continue` → `Register` をクリック

---

## ステップ2: Provisioning Profileの作成

### 2.1 App IDの確認

1. Apple Developer Center の `Identifiers` を開く
2. 既存のApp ID `com.katsumasakimura.OOMBoundary` が存在することを確認
3. 存在しない場合は新規作成:
   - `+` ボタンをクリック
   - `App IDs` を選択 → `Continue`
   - **Bundle ID:** `com.katsumasakimura.OOMBoundary`
   - 必要な Capabilities を選択
   - `Continue` → `Register`

### 2.2 Ad-Hoc Provisioning Profileの作成

1. Apple Developer Center の `Profiles` を開く
2. 右上の `+` ボタンをクリック
3. **Distribution** セクションから `Ad Hoc` を選択
4. `Continue` をクリック
5. **App ID:** `com.katsumasakimura.OOMBoundary` を選択 → `Continue`
6. **Certificate:** 配布用証明書を選択（iOS Distribution証明書）→ `Continue`
   - 証明書がない場合は先に `Certificates` セクションで作成
7. **Devices:** 登録したデバイスにチェックを入れる → `Continue`
8. **Provisioning Profile Name:** わかりやすい名前を入力
   - 例: `OOMBoundary Ad Hoc Full Mode`
   - 例: `OOMBoundary Ad Hoc Soft Mode`
9. `Generate` をクリック
10. `Download` ボタンをクリックしてダウンロード

### 2.3 Provisioning Profileのインストール

ダウンロードした `.mobileprovision` ファイルをダブルクリックすると、Xcodeに自動的にインストールされます。

---

## ステップ3: Xcodeでのビルド設定

### 3.1 Signing設定の確認

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターでプロジェクトファイル（OOMBoundary.xcodeproj）を選択
3. `TARGETS` > `OOMBoundary` を選択
4. `Signing & Capabilities` タブを開く
5. **Release** 設定を確認:
   - `Automatically manage signing` のチェックを**外す**（手動管理）
   - `Team` を選択
   - `Provisioning Profile` で先ほど作成したAd-Hoc Profileを選択

---

## ステップ4: Archive の作成と Ad-Hoc 配布

### 4.1 Archiveの作成

1. Xcodeでスキームを選択:
   - **Full Modeをテストする場合:** `OOMBoundary-Full` スキームを選択
   - **Soft Modeをテストする場合:** `OOMBoundary` スキームを選択

2. ビルドターゲットを `Any iOS Device (arm64)` に変更
   - ツールバーのデバイス選択メニューから選択
   - 特定のデバイスが接続されている場合はそのデバイスでもOK

3. メニューバーから: `Product` > `Archive` を実行
   - ⚠️ 注意: Archiveは Release 設定でビルドされます
   - ビルドには数分かかる場合があります

4. ビルドが完了すると、自動的に `Organizer` ウィンドウが開きます
   - 開かない場合: `Window` > `Organizer` (⇧⌘O)

### 4.2 Ad-Hocの選択とIPAエクスポート（重要）

1. **Organizer** ウィンドウで:
   - 左側の `Archives` タブが選択されていることを確認
   - 作成されたArchiveが一覧に表示されます

2. 右側の **`Distribute App`** ボタンをクリック

3. **配布方法の選択** 画面が表示されます:
   ```
   ┌─────────────────────────────────────┐
   │ Select a method of distribution:    │
   │                                     │
   │ ◯ App Store Connect               │
   │ ◯ Ad Hoc                           │  ← これを選択！
   │ ◯ Enterprise                        │
   │ ◯ Development                       │
   │ ◯ Copy App                          │
   └─────────────────────────────────────┘
   ```
   
   **`Ad Hoc`** のラジオボタンを選択して `Next` をクリック

4. **App Thinning** 画面:
   - `None` を選択（全デバイスアーキテクチャを含める）
   - または特定デバイス向けに最適化する場合はそのデバイスを選択
   - `Next` をクリック

5. **Re-sign** 画面:
   - 自動的に適切な Distribution Certificate と Provisioning Profile が選択されます
   - 作成したAd-Hoc Profileが選択されていることを確認
   - `Next` をクリック

6. **Review** 画面:
   - 設定内容を確認
   - `Export` をクリック

7. **保存場所の選択:**
   - 保存先のフォルダを選択（例: デスクトップ）
   - `Export` をクリック
   - IPAファイルが作成されます

### 4.3 エクスポートされるファイル

指定したフォルダに以下のファイルが作成されます:
```
OOMBoundary.ipa                    # インストール用IPAファイル
DistributionSummary.plist          # 配布情報
ExportOptions.plist                # エクスポート設定
Packaging.log                      # パッケージングログ
```

---

## ステップ5: 実機へのインストール

### 5.1 Xcode経由でのインストール（推奨）

1. **デバイスを接続:**
   - USBケーブルでMacとiOSデバイスを接続
   - デバイスのロックを解除
   - 初回接続時は「このコンピュータを信頼しますか？」に `信頼` をタップ

2. **Devices and Simulators ウィンドウを開く:**
   - Xcode メニュー: `Window` > `Devices and Simulators` (⇧⌘2)
   - 左側でインストール先のデバイスを選択

3. **IPAファイルをインストール:**
   - エクスポートした `.ipa` ファイルを、右側の `Installed Apps` エリアにドラッグ&ドロップ
   - または、`Installed Apps` エリア下部の `+` ボタンをクリックして `.ipa` ファイルを選択
   - インストールが開始されます

4. **インストール完了:**
   - `Installed Apps` リストに `OOMBoundary` が表示されます
   - デバイスのホーム画面にアプリアイコンが表示されます

### 5.2 Finder経由でのインストール（macOS Catalina以降）

1. Finderを開く
2. 左サイドバーの `場所` セクションからデバイスを選択
3. IPAファイルをデバイスのウィンドウにドラッグ&ドロップ

---

## ステップ6: アプリの起動と検証

### 6.1 初回起動

1. デバイスでアプリを起動
2. 「信頼されていないエンタープライズデベロッパ」エラーが表示される場合:
   - 設定アプリを開く
   - `一般` > `VPNとデバイス管理`
   - Developer App セクションで自分の Apple ID を選択
   - `"<あなたのApple ID>"を信頼` をタップ
   - 確認ダイアログで `信頼` をタップ
3. アプリを再起動

### 6.2 Memory Integrity Enforcement の確認

アプリが起動したら、以下を確認します:

#### Build Configuration
- **Full Mode版:** `Full Mode Entitlements` と表示されているか
- **Soft Mode版:** `Soft Mode Entitlements` と表示されているか

#### Runtime Detection
- **Enforcement Mode** が意図したモード（Full/Soft）になっているか
- **Protection Level** の表示
- **Code Signing Flags** の値

#### メモリ保護テストの実行

1. `Memory Protection Tests` セクションで各テストボタンをタップ:
   - **Safe Tests:** 基本的な動作確認
   - **All Tests:** すべてのテストを実行
   - **Dangerous Tests:** 危険なメモリ操作テスト

2. **期待される挙動の違い:**
   - **Full Mode（Distribution署名）:**
     - より厳格なメモリ保護
     - 不正なメモリアクセスで即座にクラッシュする可能性が高い
   - **Soft Mode（Distribution署名）:**
     - 基本的な保護のみ
     - 一部の不正アクセスが検出されない可能性

---

## ステップ7: 両モードの比較テスト

### 7.1 Full Modeのビルドとテスト

1. `OOMBoundary-Full` スキームを選択
2. `Product` > `Archive` でArchive作成
3. Ad-Hoc配布でIPAをエクスポート
4. デバイスにインストール
5. Memory Protection Tests を実行してコンソールログを記録

### 7.2 Soft Modeのビルドとテスト

1. `OOMBoundary` スキームを選択（Soft Mode）
2. `Product` > `Archive` でArchive作成
3. Ad-Hoc配布でIPAをエクスポート
4. デバイスにインストール（Full Mode版は上書きされます）
5. Memory Protection Tests を実行してコンソールログを記録

### 7.3 結果の比較

両モードで以下の項目を比較します:
- Code Signing Flags の値
- Memory Protection Tests の成功/失敗パターン
- クラッシュするテストケース
- コンソールログの違い

---

## トラブルシューティング

### エラー: "No applicable devices found"

**原因:** デバイスのUDIDがProvisioning Profileに登録されていない

**解決策:**
1. Apple Developer Center でデバイスのUDIDが登録されているか確認
2. Provisioning Profile にデバイスが含まれているか確認
3. Provisioning Profile を再生成してXcodeに再インストール

### エラー: "Code signing error"

**原因:** 証明書またはProvisioning Profileが正しく設定されていない

**解決策:**
1. Xcode の `Signing & Capabilities` で Release 設定を確認
2. 正しいAd-Hoc Provisioning Profileが選択されているか確認
3. 証明書の有効期限を確認（Apple Developer Center）

### エラー: "App installation failed"

**原因:** デバイスのiOSバージョンが古い、またはアプリがデバイスと互換性がない

**解決策:**
1. デバイスのiOSバージョンを確認（最低iOS 18.0が必要）
2. Xcode の Deployment Target 設定を確認
3. デバイスを再起動して再試行

### アプリが起動しない

**原因:** エンタイトルメントの設定が正しくない可能性

**解決策:**
1. Xcodeのコンソールでエラーメッセージを確認
2. デバイス本体: 設定 > 一般 > VPNとデバイス管理 でデベロッパを信頼
3. エンタイトルメントファイル（OOMBoundary.entitlements）の内容を確認

### Provisioning Profileが選択できない

**原因:** ProfileがXcodeに正しくインストールされていない

**解決策:**
1. `~/Library/MobileDevice/Provisioning Profiles/` を確認
2. `.mobileprovision` ファイルを再度ダブルクリック
3. Xcode を再起動
4. Xcode の `Preferences` > `Accounts` > 自分のApple IDを選択 > `Download Manual Profiles` をクリック

---

## 参考情報

### Code Signing Flags の読み方

Distribution署名されたアプリの Code Signing Flags は、以下のような値になることが期待されます:

```
Full Mode:  0x3A00300D (CS_MEMINT_ENABLED を含む)
Soft Mode:  0x32003005 (CS_MEMINT_ENABLED なし)
```

### 主要なフラグ:
- `CS_VALID (0x00000001)`: コード署名が有効
- `CS_HARD (0x00000100)`: Hardened Runtime有効
- `CS_KILL (0x00000200)`: 違反時にプロセスを終了
- `CS_MEMINT_ENABLED (0x20000000)`: メモリ整合性保護が有効

### Distribution vs Development 署名の違い

| 項目 | Development | Distribution (Ad-Hoc) |
|------|-------------|----------------------|
| 目的 | 開発中のテスト | 本番相当のテスト |
| デバイス登録 | 不要（開発者のデバイス） | 必要（UDIDを登録） |
| メモリ保護 | 緩い（デバッグ優先） | 厳格（本番相当） |
| 有効期限 | 短い | 長い |
| 配布範囲 | 開発者のみ | 登録デバイスのみ |

---

## まとめ

このガイドに従うことで:
1. ✅ Ad-Hoc配布用のIPAファイルを作成できます
2. ✅ Distribution署名でFull ModeとSoft Modeをテストできます  
3. ✅ 本番環境に近い状態でメモリ保護機能の違いを検証できます

Development署名では確認できなかった挙動の違いが、Distribution署名では明確になる可能性があります。

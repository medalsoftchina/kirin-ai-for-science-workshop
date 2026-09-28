# Day2 Lab 0: Terraform で Azure AI Foundry 環境を構築する

このラボでは、Terraform と検証済みの AVM (Azure Verified Modules) パターンモジュール
[`Azure/avm-ptn-aiml-ai-foundry/azurerm`](https://registry.terraform.io/modules/Azure/avm-ptn-aiml-ai-foundry/azurerm/0.11.3)
(バージョン 0.11.3) を使って、Azure AI Foundry の環境をまるごとデプロイします。

## 作成されるもの

| リソース                             | 内容                                                                                                                                                                   |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| リソースグループ                     | `rg-kirinws`                                                                                                                                                         |
| AI Foundry アカウント + プロジェクト | プロジェクト名:`kirin-rnd-lab`                                                                                                                                       |
| モデルデプロイ × 4                  | `gpt-6-luna` (GS 50, 主力・ポータル用) / `gpt-5.6-terra` (GS 100, 比較用) / `gpt-4.1` (GS 50, Lab 3 Agent Service 用) / `text-embedding-3-large` (Standard 50) |
| Azure AI Search                      | Basic SKU / レプリカ 1 (モジュールが新規作成)                                                                                                                          |
| Storage アカウント                   | LRS (モジュールが新規作成)                                                                                                                                             |
| Key Vault                            | モジュールが新規作成                                                                                                                                                   |
| Cosmos DB                            | エージェントのスレッド状態保存用 (モジュールが新規作成)                                                                                                                |

リージョンは **東日本 (japaneast)** です。

---

## 前提条件

> **ローカルにツールをインストールできない場合 (社内ポリシー等):**
> Azure Cloud Shell でも同じ手順で実行できます → **[CLOUDSHELL.md](CLOUDSHELL.md)**

以下が済んでいることを確認してください。

> **ツールがまだ入っていない方へ:** リポジトリのセットアップスクリプトで一括インストールできます（詳細は [setup/README.md](../setup/README.md)）。
>
> - Mac: `bash setup/setup_env.sh`
> - Windows: `powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1`

1. **Terraform 1.12 以上** がインストールされていること

   ```bash
   terraform version
   ```
2. **Azure CLI** がインストールされていること

   ```bash
   az version
   ```
3. Azure にログインし、使うサブスクリプションを選択していること

   ```bash
   # Azure にログイン (ブラウザが開きます)
   az login

   # 使用するサブスクリプションを指定
   az account set --subscription "<サブスクリプションID>"

   # 正しいサブスクリプションが選ばれているか確認
   az account show
   ```

---

## 手順

### 1. 変数ファイル (terraform.tfvars) を作る

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` をエディタで開き、次の 2 点を確認・編集します。

- `base_name` … 他の受講者と重複する場合は変更 (3〜7文字の小文字英数字)
- `tags.owner` … **必ず自分の名前に書き換えてください** (`"your-name"` のままにしない)

### 2. 初期化 (init)

モジュールとプロバイダーをダウンロードします。最初の 1 回だけ必要です。

```bash
terraform init
```

### 3. 実行計画の確認 (plan)

何が作られるかを事前に確認します。

```bash
terraform plan
```

最後に **`Plan: 20 to add, 0 to change, 0 to destroy.`** のように表示されれば OK です
(約 20 個のリソース。前後する場合がありますが問題ありません)。

### 4. デプロイ (apply)

```bash
terraform apply
```

確認プロンプトが出たら `yes` と入力します。
モデルデプロイや依存リソースの作成を含むため、**完了まで 10〜20 分程度** かかります。

### 5. 結果の確認

```bash
terraform output
```

以下の 5 つが表示されます。

- `ai_foundry_project_endpoint` … `https://<アカウント名>.services.ai.azure.com/api/projects/kirin-rnd-lab` 形式のエンドポイント (後のラボで SDK から接続する際に使います)
- `ai_foundry_project_name`
- `ai_search_endpoint`
- `storage_account_name`
- `resource_group_name`

あわせてポータルでも確認してみましょう。

- [Azure ポータル](https://portal.azure.com) → リソースグループ **rg-kirinws** を開き、AI Foundry / AI Search / Storage / Key Vault / Cosmos DB があることを確認
- [Azure AI Foundry ポータル](https://ai.azure.com) → プロジェクト **kirin-rnd-lab** を開き、「モデル + エンドポイント」に **4 つのモデルデプロイ** (gpt-6-luna / gpt-5.6-terra / gpt-4.1 / text-embedding-3-large) があることを確認

---

## ⚠️ 片付け (重要!)

**ラボが終わったら必ず削除してください。**

Azure AI Search (Basic SKU) は **デプロイされているだけで約 $75/月** かかります。
使わなくなった環境を放置すると課金が続くので、ハンズオン終了後に以下を実行してください。

```bash
terraform destroy
```

確認プロンプトで `yes` と入力すると、作ったリソースがすべて削除されます。

補足: Key Vault は Azure の仕様上、削除しても通常は「ソフト削除」状態が残りますが、
この構成では destroy 時に **完全削除 (パージ)** する設定
(`purge_soft_delete_on_destroy = true`) を有効にしているため、
同じ名前で何度でも作り直せます。

---

## トラブルシューティング

- **`az login` していない / サブスクリプションが違う** → 前提条件の手順 3 をやり直してください。
- **409 RequestConflict「Another operation is being performed on the parent resource」が出た** → Azure 側でモデルデプロイが直列処理されているための一時的な競合です。慌てず **もう一度 `terraform apply` を実行**すれば続きから作成されます（2026-09-28 の実環境テストで確認済み。複数モデルの場合、数回の再実行で完了します）。
- **なぜ `gpt-4.1` もデプロイされるのか** → Lab 3 で使う Agent Service が、2026-09-28 時点で gpt-6 / 5.6 系プレビューモデルの run を処理できないためです（実測: `top_p` 非対応 / server_error）。Lab 1・2 のポータル操作は gpt-6-luna、Lab 3 の Agent は gpt-4.1、という使い分けです。
- **モデルデプロイでクォータ (割り当て) エラーが出た** → サブスクリプションの TPM クォータ不足の可能性があります。講師に相談してください。
- **名前の重複エラー (Storage / Key Vault など)** → `terraform.tfvars` の `base_name` を別の値 (3〜7文字の小文字英数字) に変えて `apply` し直してください。

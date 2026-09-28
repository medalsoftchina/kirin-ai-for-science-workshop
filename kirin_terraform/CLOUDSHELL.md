# Cloud Shell で Lab 0 を実行する手順（社内ポリシーでローカル az login が制限される方向け）

> **このドキュメントの対象:** 会社のポリシーで PC からの `az login`（デバイスコード
> フロー）が制限され、ローカルで Terraform を実行できない方。
> **結論: Azure Cloud Shell を使えば、このリポジトリの Terraform はそのまま動きます。**
> Cloud Shell はブラウザ上のターミナルで、**認証は自動**（デバイスコード不要）、
> Terraform / Git / tmux / エディタ（`code`）がプリインストールされています
> （2026-09-28 に Microsoft Learn で確認）。

## 0. なぜ動くのか（技術メモ）

| 懸念 | 実際 |
|---|---|
| 認証 | Cloud Shell はログイン済みユーザーの資格情報を自動で Terraform (azurerm / azapi プロバイダー) に引き渡します。追加ログインは不要です |
| Terraform | プリインストール済み。万が一バージョンが古い（< 1.12）場合は、管理者権限不要で最新版を `$HOME/bin` に入れられます（下記 2） |
| AVM モジュール | `terraform init` が registry.terraform.io から取得します。Cloud Shell からの外向き通信で問題なく動作します |
| セッション切断 | apply は 15〜25 分かかります。**tmux 内で実行すれば**、切断しても処理は継続します（tmux はプリインストール済み） |
| ファイルの永続化 | ストレージアカウントをアタッチすると `$HOME`（clouddrive）が永続化され、tfstate も残ります |

## 1. Cloud Shell を開く

1. [Azure ポータル](https://portal.azure.com) にログインします。
2. 画面右上の **Cloud Shell アイコン**（`>_`）をクリックします。
3. 初回はストレージの設定を聞かれます。**「ストレージアカウントを作成」**を選んでください（tfstate を永続化するため）。
4. 左上のシェルが **Bash** になっていることを確認します（PowerShell でも可ですが、本手順は Bash です）。
5. サブスクリプションを確認します:
   ```bash
   az account show
   # 違っていれば: az account set --subscription "<サブスクリプションID>"
   ```

## 2. Terraform のバージョン確認（1.12 以上必須）

```bash
terraform version
```

**1.12 未満だった場合**のみ、以下で最新版をユーザーのホームに入れます（root 不要）:

```bash
mkdir -p ~/bin
TFV=1.16.4
curl -sSL "https://releases.hashicorp.com/terraform/${TFV}/terraform_${TFV}_linux_amd64.zip" -o /tmp/tf.zip
unzip -o /tmp/tf.zip -d ~/bin && rm /tmp/tf.zip
export PATH="$HOME/bin:$PATH"
terraform version   # 1.12 以上になったことを確認
```

## 3. リソースプロバイダーの登録（初めて使うサブスクリプションの場合）

```bash
for ns in Microsoft.CognitiveServices Microsoft.Search Microsoft.Storage \
          Microsoft.KeyVault Microsoft.DocumentDB Microsoft.Insights; do
  az provider register --namespace "$ns"
done
# 登録はバックグラウンドで進みます。気にせず次へ進んで構いません
```

## 4. コードの取得と tfvars の設定

```bash
git clone https://github.com/medalsoftchina/kirin-ai-for-science-workshop workshop
cd workshop/kirin_terraform
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars   # Cloud Shell 内蔵エディタで base_name と owner を編集して保存
```

> ZIP で配布された場合は、Cloud Shell 上部の「ファイルのアップロード」から ZIP を
> 上げて `unzip` してください。

## 5. tmux 内でデプロイ（切断対策）

```bash
tmux new -s lab0
# tmux の中で:
terraform init
terraform plan    # 「22 to add」前後であることを確認
terraform apply   # yes。15〜25 分。409 RequestConflict が出たら再実行で OK
```

> **途中でブラウザを閉じても大丈夫です。** 再接続したら `tmux attach -t lab0` で戻れます
> （tmux を使わない場合、無操作 20 分でセッションが切れ apply が中断される可能性が
> あります）。

## 6. 確認

```bash
terraform output
# 5 つの値 (ai_foundry_project_endpoint など) を記録シートに転記
```

その後、ポータルで `rg-kirinws`、ai.azure.com でプロジェクト `kirin-rnd-lab` と
4 つのモデルデプロイを確認します（詳しくは [README.md](README.md)）。

## 7. クリーンアップ（必須）

演習終了時に、**同じ Cloud Shell（同じ $HOME = 同じ tfstate）から**実行します:

```bash
cd ~/workshop/kirin_terraform
terraform destroy   # yes
```

> ⚠️ tfstate は Cloud Shell のホームに保存されています。**別のマシンや別の場所から
> destroy すると state が見つからず残骸が残ります。** 必ず同じ Cloud Shell から実行し、
> 最後にポータルで rg-kirinws が消えたことを目視確認してください。
> AI Search Basic は作成時点から課金されます（約 $75/月）。

## トラブルシューティング

- **`terraform: command not found`** → 手順 2 の PATH 設定をやり直してください（新しいシェルでは `export PATH="$HOME/bin:$PATH"` が必要です）。
- **409 RequestConflict** → モデルデプロイが直列処理されている一時的な競合です。`terraform apply` を再実行すれば続きから作成されます（複数モデルの場合、数回の再実行で完了します。2026-09-28 実測済み）。
- **モデルデプロイでクォータエラー** → サブスクリプションの TPM クォータ不足です。講師に相談してください。
- **レジストリへ接続できない (init 失敗)** → 社内ポリシーで Terraform Registry が制限されている可能性があります。講師に相談してください（モジュールをローカルに vendoring する代替案があります）。

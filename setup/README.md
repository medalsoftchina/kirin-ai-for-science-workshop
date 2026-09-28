# セットアップスクリプト (Day2 環境準備)

ワークショップ当日 (2026-09-29) に必要なツールを一発でインストールするスクリプトです。

- **macOS**: `setup_env.sh` (Homebrew を使用。Homebrew 自体も自動で入ります)
- **Windows**: `setup_env.ps1` (winget を使用)

どちらも**何度実行しても安全**です。すでにインストール済みのツールはスキップし、
最後に全ツールのバージョンチェックリストを表示します。

## インストールされるもの

| ツール | 要件 |
|---|---|
| Azure CLI | 最新 |
| Terraform | **1.12 以上 2.0 未満** (古い場合は警告のみ。勝手に上書きしません) |
| Git | 最新 |
| Python | 3.10 以上 (Lab 3 で使用) |
| VS Code | 任意 (下記のフラグを付けた場合のみ) |

## 実行方法

**所要時間の目安: 10〜15 分** (ネットワーク速度によります)

### macOS

```bash
bash setup/setup_env.sh

# VS Code も入れたい場合
bash setup/setup_env.sh --with-vscode
```

### Windows

PowerShell を開いて、リポジトリのフォルダで以下を実行します。

```powershell
powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1

# VS Code も入れたい場合
powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1 -WithVSCode
```

※ 実行ポリシーでブロックされた場合は、必ず上記のとおり
`-ExecutionPolicy Bypass` を付けて起動してください。

## 実行後の共通手順

スクリプト完了後、Azure にログインしてサブスクリプションを選択します
(サブスクリプション ID は当日の座席カードに記載)。

```bash
az login
az account set --subscription "<サブスクリプションID>"
az account show   # 選択結果を目視で確認
```

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `brew: command not found` (実行後も) | ターミナルを開き直してください。それでも駄目なら `.zprofile` に `eval "$(/opt/homebrew/bin/brew shellenv)"` を追記 (Intel Mac は `/usr/local/bin/brew`) |
| `winget が見つかりません` | Microsoft Store で「アプリ インストーラー」(App Installer) をインストールするか、Windows Update を最新にしてから再実行 |
| `Terraform が古い` と警告が出る | スクリプトは既存 Terraform を上書きしません。Mac: `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`、Windows: `winget upgrade --id HashiCorp.Terraform -e` |
| 社内プロキシでダウンロードに失敗する | プロキシ設定 (`HTTPS_PROXY` 環境変数) を確認するか、社内ネットワーク管理者に相談。当日 13:00-13:15 のセットアップ時間に講師へお声がけください |
| Windows で「管理者権限が必要」と出る | UAC の確認に「はい」と答えてください。権限がない場合は管理者に相談 (winget は可能な範囲でユーザー scope にフォールバックします) |


---

## ローカルにインストールできない場合

社内ポリシーでローカルへのインストールや `az login`（デバイスコード）が制限されている場合は、
**Azure Cloud Shell** でも Lab 0 を実行できます（認証自動・Terraform プリインストール）。
手順: [../kirin_terraform/CLOUDSHELL.md](../kirin_terraform/CLOUDSHELL.md)

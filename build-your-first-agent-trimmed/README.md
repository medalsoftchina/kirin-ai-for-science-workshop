# Day2 Lab 3: はじめてのエージェント (Build your first agent — 抜粋版)

Microsoft のワークショップ「build-your-first-agent-with-azure-ai-agent-service」を
このトレーニング向けに**抜粋・簡略化**したハンズオンです。

> **本サンプルは Day2 では講師が実演します。** 受講者の皆さまは当日は観察・質問のみで
> 構いません。後日ご自身の環境でお試しください（下記セットアップ手順で再現できます）。

Azure AI Foundry の Agent Service に接続し、**Code Interpreter** ツールを持つ
エージェントを作成して、ダミーのオミックスデータ (SQLite) を解析させます。
エージェントが**自分で pandas / matplotlib のコードを書いて実行し**、
グラフ画像 (PNG) を生成する様子を観察するのがこのラボの目的です。

## 前提条件

- Python 3.9 以降
- Azure CLI で `az login` 済みであること
- Azure AI Foundry プロジェクトのエンドポイントとモデルのデプロイ名
  (講師から配布される情報を使います)

## セットアップ

**推奨: ワンステップスクリプト**を使ってください。仮想環境の作成・依存インストール・
`.env` の雛形作成・`omics.db` の構築まで一括で行います。

```bash
# 1. リポジトリをクローンして移動
git clone <このリポジトリのURL>
cd build-your-first-agent-trimmed

# 2. セットアップスクリプトを実行
bash setup.sh        # Mac / Linux
```

```powershell
# Windows の方 (PowerShell)
powershell -ExecutionPolicy Bypass -File setup.ps1
```

スクリプトが終わったら `.env` をエディタで開き、`PROJECT_ENDPOINT` と
`MODEL_DEPLOYMENT_NAME` を記入してください。

<details>
<summary>手動でセットアップする場合 (スクリプトが使えない場合のフォールバック)</summary>

```bash
# 1. (任意) 仮想環境を作成
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# 2. 依存パッケージをインストール
pip install -r src/workshop/requirements.txt

# 3. 環境変数ファイルを作成して値を記入
cp .env.sample .env
# .env をエディタで開き、PROJECT_ENDPOINT と MODEL_DEPLOYMENT_NAME を記入

# 4. ダミーCSVから SQLite データベース (omics.db) を作成
python build_omics_db.py
```

</details>

## 実行手順

```bash
# 手順1: ダミーCSVから SQLite データベース (omics.db) を作成
python build_omics_db.py
# → variants テーブル / phenotype_records テーブルの件数が表示されます

# 手順2: エージェントを実行 (講師と一緒にコードを読みながら)
python src/workshop/main.py
```

## 観察ポイント

- エージェントが指示を解釈し、**自分で Python コードを生成**します
  (pandas でテーブル結合 → Pathogenic 変異の遺伝子ごとの平均 allele_freq 計算
  → matplotlib で上位10件の横棒グラフ作成)。
- コードは Foundry 側の **Code Interpreter** (サンドボックス) で実行されます。
- 最後に生成されたグラフ (PNG) が `./output/` にダウンロードされます。
- ターミナルにはエージェントの日本語の回答テキストが表示されます。

> **補足 (.txt へのアップロードについて):** Code Interpreter は `.db` 拡張子の
> ファイルを直接受け付けません。そのため `main.py` は `omics.db` を `omics_db.txt`
> にコピーしてからアップロードします (中身は SQLite のまま)。エージェントには
> 「拡張子は .txt だが sqlite3.connect で開ける」と指示しています。
> 実案件で同じ制約に当たったときの回避策として覚えておいてください
> (2026-09-28 に実環境で検証済み)。

## データについて

`data/omics_variants.csv` は乱数 (seed 固定) で生成した**ダミーデータ**です。
実験データではありません。列の意味:

| 列 | 意味 |
|---|---|
| variant_id | 変異の一意ID (VAR-0001 など) |
| gene | 遺伝子名 (BRCA1, TP53, EGFR など全8種) |
| clinical_significance | 臨床的意義 (Pathogenic / Likely pathogenic / Benign / VUS) |
| phenotype_annotation | 表現型アノテーション |
| sample_id | サンプルID (SAMPLE-001 など) |
| allele_freq | アレル頻度 (0.0001〜0.5) |
| batch | 測定バッチ (batch1〜batch3) |

## 後片付け

- スクリプトは最後にエージェントを自動削除します。
- アップロードしたファイルやスレッドは課金対象になりにくいですが、
  気になる場合は Foundry ポータルから削除してください。

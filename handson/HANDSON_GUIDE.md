# ハンズオンガイド — Microsoft Azure AI for Science ワークショップ Day 2

**日時:** 2026-09-29（火）13:00–18:00
**対象:** キリン中央研究所の皆さま（Azure 初心者歓迎）
**テーマ:** Azure 環境構築からエージェント開発まで — オミックス研究のための agentic AI 基盤を、自分たちの手でデプロイする

本ガイドは Day 2 ハンズオンの手順書です。各 Lab の詳細手順はリンク先の README を参照しつつ、ここでは流れとチェックポイントを確認します。分からなくなったら、その場で講師・助教にお声がけください。

---

## 0. 事前準備

### 0-1. 必要なツール

**推奨: セットアップスクリプトで一括インストール**してください。何度実行しても安全で、最後に全ツールのバージョンチェックリストを表示します（詳細・トラブルシューティングは [setup/README.md](../setup/README.md)）。

```bash
# Mac の方（Homebrew がなくても自動で入ります）
bash setup/setup_env.sh
```

```powershell
# Windows の方（PowerShell で実行）
powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1
```

所要時間の目安は 10〜15 分です。スクリプトを使わず手動で入れる場合は、以下のツールがインストールされていることをご確認ください。

| ツール | 要件 | 確認コマンド |
|---|---|---|
| Azure CLI | 最新推奨 | `az version` |
| Terraform | **1.12 以上、2.0 未満** | `terraform version` |
| Python | **不要**（Lab 3 は講師実演のため） | — |
| Git | 配布リポジトリの取得（clone）に使用 | `git --version` |

> **重要:** Terraform が 1.12 未満の場合、`terraform init` が必ず失敗します。バージョンが古い方は、開始前に講師までお知らせください。

> **当日の時間確保:** 13:00–13:15 は環境セットアップ＆トラブル対応の時間として確保しています。**事前にセットアップが完了していない方は、この時間に上記スクリプトでセットアップ**してください（講師・助教がサポートします）。

> **社内ポリシーでローカルの `az login` / インストールが制限される方:**
> Azure Cloud Shell（ブラウザ上のターミナル・認証自動）で Lab 0 を実行できます。
> 手順は **[../kirin_terraform/CLOUDSHELL.md](../kirin_terraform/CLOUDSHELL.md)** を参照してください。

### 0-2. Azure サブスクリプションと権限

- 本日はキリン様側でご準備いただいた Azure サブスクリプションを使用します。
- ご自身のアカウントに **Contributor 以上**のロールが付与されていることをご確認ください（権限が不足している場合は、当日オーナー権限をお持ちの方がポータルで付与します）。
- **Lab 2 で Blob にファイルをアップロードする方へ:** Contributor は管理平面の権限のため、Blob データの読み書きには別途データ平面のロール **「ストレージ BLOB データ共同作成者」（Storage Blob Data Contributor）** が必要です。サブスクリプションの共同作成者（共同管理者）の方は両方を含むため追加不要です。それ以外の方は講師が当日付与します。
- 使用する**サブスクリプション ID は当日の座席カードに記載**しています。`az account set` の際に使用しますので、お手元にご用意ください。

### 0-3. GitHub リポジトリの取得

ハンズオンで使うコードと公開データ（乳酸菌論文 PDF・ClinVar サブセット）は、GitHub リポジトリで配布します。**リポジトリの URL は当日ご案内します。**

```bash
# Git で clone する場合
git clone https://github.com/medalsoftchina/kirin-ai-for-science-workshop
```

Git が使えない場合は、GitHub の画面から ZIP ダウンロードして展開していただいても構いません。

### 0-4. 当日の環境確認コマンド

席についたら、まず以下を実行してログインと対象サブスクリプションを確認してください。

```bash
# Azure にログイン（ブラウザが自動で開きます）
az login

# 対象サブスクリプションを選択（座席カード記載の ID を使用）
az account set --subscription "<サブスクリプションID>"

# 選択結果を目視で確認（JSON の "name" 行が自分のサブスクリプション名か）
az account show

# Terraform のバージョンを確認（v1.12.x 以上であること）
terraform version
```

> `az account show` の確認は「誤ったサブスクリプションにデプロイしてしまう」事故を防ぐ最後の砦です。必ず目視でご確認ください。ブラウザが開かない場合は `az login --use-device-code` をお試しください。

### 0-5. 注意事項

- **コスト:** Azure AI Search（Basic SKU）は**作成した時点で課金が始まります（約 $75/月）**。使わなくても課金が続きますので、**終了時に必ず `terraform destroy` で削除**します。Cosmos DB も RU 課金が継続します。
- **データ:** 本日は**公開データまたはダミーデータのみ**を使用します。社内の機密データ・個人情報は絶対にアップロードしないでください。
- デプロイには 10〜20 分かかります。待ち時間は講師の解説にあてますので、気長にお待ちください。

---

## Lab 0: 環境構築（Terraform × AVM）13:15–13:50

Terraform と Microsoft 公式の AVM（Azure Verified Modules）パターンモジュール `avm-ptn-aiml-ai-foundry` v0.11.3 で、AI Foundry・AI Search・Storage・Key Vault・Cosmos DB をコード一発でデプロイします。

**詳細手順はこちら → [kirin_terraform/README.md](../kirin_terraform/README.md)**

流れは 4 ステップです。

1. **ツール確認** … `terraform version` / `az login` / `az account show`
2. **設定** … `cp terraform.tfvars.example terraform.tfvars` → `tags.owner` を自分の名前に
3. **デプロイ** … `terraform init` → `terraform plan` → `terraform apply`（10〜20 分）
4. **確認** … `terraform output` とポータルで目視確認

### チェックポイント

- [ ] `terraform plan` の末尾に **`Plan: 20 to add, ...`**（約 20 個のリソース）と表示された
- [ ] `terraform output` で **5 つの出力値**（`ai_foundry_project_endpoint` / `ai_foundry_project_name` / `ai_search_endpoint` / `storage_account_name` / `resource_group_name`）を確認し、[記録シート](templates/00-record-sheet.md) に転記した
- [ ] [Azure ポータル](https://portal.azure.com) でリソースグループ **rg-kirinws** を開き、Foundry / Search / Storage / Key Vault / Cosmos DB が並んでいることを確認した
- [ ] [AI Foundry ポータル](https://ai.azure.com) でプロジェクト **kirin-rnd-lab** を開き、「モデル + エンドポイント」に **3 つのモデル**（gpt-6-luna / gpt-5.6-terra / text-embedding-3-large）があることを確認した

---

## Lab 1: Foundry ポータル体験 13:50–14:30

コードは書きません。ブラウザだけで、モデルカタログ・チャットプレイグラウンド・エージェント作成を体験します。始める前に [ai.azure.com](https://ai.azure.com) をアドレスバーに直接入力して開き、プロジェクト **kirin-rnd-lab** を選択してください。

**詳細なクリック手順はこちら → [lab1-foundry-portal.md](lab1-foundry-portal.md)**

### 1-1. モデルカタログ探索

左メニュー「モデル カタログ」を開き、OpenAI 以外のモデル（Meta Llama / Mistral / Cohere / DeepSeek など）を眺めます。モデルカードの「ベンチマーク」タブで品質・速度・コストを比較できます。

**課題:** 次の 2 つのユースケースごとに、候補モデルを **2 つずつ**選び、理由とともに[記録シート](templates/00-record-sheet.md)に記録してください。

- ユースケース A: **論文要約**
- ユースケース B: **変異アノテーション解釈**

> 迷ったら左上のプロジェクト名を確認してください。別プロジェクトにいるとデプロイ済みモデルが見えません。

### 1-2. Chat Playground

1. 左メニュー「プレイグラウンド」→「チャットのプレイグラウンド」を開きます。
2. 上部のデプロイ選択で **gpt-6-luna** を選びます。
3. システムメッセージに **「あなたはオミックス研究を支援するアシスタントです」** と入力し、**「変更を適用」**をクリックします（クリックを忘れると反映されません）。
4. チャット欄に **「メタゲノム解析の前処理ステップを教えてください」** と入力して送信します。
5. 右パネルの **Temperature を 0.2 → 1.0** に変えて再送信し、回答の再現性・揺らぎを比較します。
6. （余裕があれば）**Compare 機能**で gpt-5.6-terra と並べて比較してみましょう。

観察した内容は演習②の評価カードに転記します。

### 1-3. 初めての Agent 作成

1. 左メニュー「エージェント」→「＋ 新しいエージェント」をクリックします。
2. 名前に **omics-assistant** と入力し、デプロイで gpt-6-luna を選択します。
3. 指示（Instructions）に「あなたはオミックス研究を支援するアシスタントです。実験データの解釈を手伝います」と入力します。
4. 「ツール」セクションを開き、追加できるツールの一覧（Code Interpreter / File Search など）を**見るだけ**確認します（今日はここでは設定しません。Lab 3 で Code Interpreter を実際に使います）。
5. 右上「プレイグラウンドで試す」から同じ質問を送り、チャットとの違い（指示を保存できる・ツールを持たせられる）を確認します。

---

## Lab 2: RAG 構築（Foundry IQ）14:45–15:30

Foundry ポータルのナレッジベース機能（Foundry IQ）で、最もシンプルな RAG を構築します。ポータル操作のみ・コードは書きません。

**詳細なクリック手順はこちら → [lab2-foundry-iq.md](lab2-foundry-iq.md)**

### 手順

1. Foundry ポータル（ai.azure.com）→ プロジェクト **kirin-rnd-lab** を開きます。
2. **ナレッジベース → 新規作成**をクリックし、名前に **omics-kb** と入力します。
3. **ナレッジソースに Blob**（講師配布の文書フォルダ）を接続します。
4. モデルに **gpt-4.1**（Lab 0 でデプロイ済み）を選択し、作成を実行します。**gpt-6-luna / gpt-5.6-terra はナレッジベースのクエリプランニングに未対応のため選択肢に表示されません**（対応モデル: gpt-4o / 4.1 / 5 系。[公式一覧](https://learn.microsoft.com/ja-jp/azure/search/agentic-retrieval-how-to-create-knowledge-base)）。
5. リポジトリの **`data/omics`** にある **2 つの論文 PDF**（*Lactiplantibacillus plantarum* の耐酸性に関するオープンアクセス論文）と **clinvar_subset.csv**（8 遺伝子 × 20 変異の ClinVar サブセット）を Blob の文書フォルダにアップロードします（ポータルからドラッグ＆ドロップ可）。あわせて **`data/omics/papers/`** にある**キリンの研究方向に関するオミックス論文 10 篇**もアップロードし、検索対象を広げてみましょう。
6. ナレッジベースで**インデックスを再実行**し、文書が**チャンク化・ベクトル化**されて登録される様子をログ・ステータスで確認します。

> **加工の裏側:** Document Intelligence（Foundry Tools のひとつ）が文書を**レイアウト保持**で加工してから格納します。表や段落構造を保ったままテキスト化されるため、論文 PDF の検索精度が向上します。

### 体験クエリ（日本語のまま入力してください）

ナレッジベースに接続したエージェント（またはプレイグラウンド）で、次の 2 問を試します。

1. **「Lactiplantibacillus plantarum の耐酸性機構について、主要な遺伝子・経路を教えてください」**
2. **「ClinVar データで pathogenic と分類される変異は、遺伝子ごとにどのくらいの分布ですか」**

### 確認ポイント

- [ ] 回答内の**引用をクリック**し、元文書の該当箇所が開くことを確認した（RAG の肝です）
- [ ] **ハルシネーションテスト:** 文書にない内容（データに存在しない遺伝子名など）を質問し、「資料に情報がない」と答えることを確認した
- [ ] **取得件数などのパラメータを変更**し、同じ質問を投げて回答の違いを比較した（取得数を増やすと網羅性↑・ノイズも↑。研究用途では引用の確実性が鍵になります）

結果は[記録シート](templates/00-record-sheet.md)（引用確認 Yes/No）に記録してください。

---

## Lab 3: はじめての Agent 開発（Code Interpreter）15:40–16:20

Azure AI Agent Service の **Code Interpreter** を持つエージェントが、オミックス風データ（変異–表型注釈）の集計・グラフ描画を自律的に行う様子を観察します。**この Lab は講師実演（デモンストレーション）です。** 講師が会前にセットアップした環境で実行し、画面共有で解説します。皆さまは観察と質問だけで構いません。Python 環境も不要です。

**詳細手順はこちら → [build-your-first-agent-trimmed/README.md](../build-your-first-agent-trimmed/README.md)**

### デモ環境について（講師が会前に準備済み）

講師は以下を会前に実施済みです（後日ご自身で再現する場合の手順でもあります）。

```bash
# 1. リポジトリを clone してワンステップスクリプトを実行
#    （venv 作成・依存インストール・.env 雛形・omics.db 構築まで一括）
git clone https://github.com/medalsoftchina/kirin-ai-for-science-workshop
cd build-your-first-agent-trimmed
bash setup.sh        # Windows は setup.ps1

# 2. .env を設定（Lab 0 の terraform output の値を使います）
# PROJECT_ENDPOINT = ai_foundry_project_endpoint の値
# MODEL_DEPLOYMENT_NAME = gpt-4.1  # ※ Agent Service 用 (下記「モデルについて」参照)

# 3. エージェントを実行
python src/workshop/main.py
```

### モデルについて（なぜ Lab 2・3 は gpt-4.1 なのか）

Lab 1 では最新プレビューの **gpt-6-luna** を使いますが、Lab 2 のナレッジベース
（Foundry IQ のクエリプランニング）は gpt-4o / 4.1 / 5 系のみ対応のため
**gpt-4.1** を使い、Lab 3 の Agent Service でも **gpt-4.1**（最新 GA）を使います。
2026-09-28 時点の実測で、プレビュー系（gpt-6 / 5.6 系）はチャット API では動く
ものの Agent Service の実行が失敗することを確認しています。
「プレビューモデルは全機能に対応しているとは限らない」
― これも Evaluate の視点です。

### 観察ポイント

- エージェントが指示を解釈し、**自分で pandas / matplotlib のコードを書く**こと
- 生成されたコードが Foundry 側の Code Interpreter（サンドボックス）で実行され、**SQLite（variants / phenotype_records テーブル）を参照**して集計すること
- 最後に **PNG のグラフ**が `./output/` に出力されること

> **ふりかえり:** エージェントが生成したコードは、必ず人がレビューします。正しさの検証が研究用途の前提です。観察メモは[記録シート](templates/00-record-sheet.md)にご記入ください。

### 後日ご自身で試す方へ

本 Lab のコードとデータは GitHub リポジトリでお持ち帰りいただけます。ご自身の環境で再現する場合は、[build-your-first-agent-trimmed/README.md](../build-your-first-agent-trimmed/README.md) の手順に沿って `setup.sh`（Windows は `setup.ps1`）を実行し、`.env` に Lab 0 でメモした接続情報を設定してください。

---

## 演習 16:20–17:10（①②はその場で実施・③は説明のみ）

Lab の体験を、4 つの成果物（テンプレート）に仕上げます。テンプレートは `handson/templates/` にあり、GitHub リポジトリからそのままお持ち帰りいただけます。

### 演習① サービスマップ（15 分・その場で実施）

ご自身の研究テーマを 1 つ選び、研究データフローの各プロセスに Azure サービスを対応付けます。

→ **[templates/01-service-map.md](templates/01-service-map.md)** に記入してください。

### 演習② 研究 AI 評価カード（15 分・その場で実施）

今日体験した Agent / RAG（Lab 2 または Lab 3）から 1 ユースケースを選び、5 つの観点で評価し、**Go / 条件付き Go / No-Go** の判定と理由を記入します。

→ **[templates/02-ai-evaluation-card.md](templates/02-ai-evaluation-card.md)** に記入してください。

### 演習③ Readiness Sheet ＋ バックログ（持ち帰り可・16:50–17:10 に説明のみ）

組織・データ・人材など 6 軸で現状を 1〜5 で自己評価し、ギャップを改善・検証バックログに落とします。**持ち帰りテンプレート**ですので、部内で後日完成させていただいて構いません。

→ **[templates/03-readiness-sheet.md](templates/03-readiness-sheet.md)** と **[templates/04-backlog.md](templates/04-backlog.md)**

> 時間がない場合は、演習③の説明を省略する場合があります。その場合もテンプレートはお持ち帰りいただけます。

---

## オプション: GraphRAG ゲノム解析デモ（講師実演・30 分）

時間に余裕がある場合のみ、講師が事前構築した GraphRAG インデックス（遺伝子–変異–表型の関係グラフ）を使ったデモを行います。了解レベル・実操作はありません。Global Search（全体俯瞰）と Local Search（特定遺伝子の近傍探索）の違いを、ベクトル RAG（Lab 2）との比較でご覧いただきます。

**詳細はこちら → [graphrag_demo/README.md](../graphrag_demo/README.md)**

---

## セキュリティチェック

ハンズオン中、および本番導入時にもそのまま使える 4 つの約束事です。

1. **公開データ・ダミーデータのみを使用する。** ゲノムデータは個人情報保護法上の「個人識別符号」＝要配慮個人情報です。実データで試す際は匿名化・社内承認が前提です。
2. **個人情報・機密データをアップロードしない。** ポータル・プレイグラウンド・Blob への投入データは、本日配布した公開データに限定してください。
3. **共有アカウントは使わず、自分の Entra ID でログインする。** 操作の記録（監査）が個人に紐づくことが、安全な運用の前提です。
4. **終了時にリソース削除を確認する。** 次の「クリーンアップ」の手順に従い、全員で残留がないことを確認します。

## クリーンアップ（17:10–17:30）

**本日いちばん大事な約束事です。** AI Search（Basic）は使わなくても課金が続きますので、その場で全員一緒に削除し、残留がないことを確認してからお帰りください。

```bash
cd kirin_terraform
terraform destroy   # 確認プロンプトに yes と入力
```

### 削除の確認（全員で実施）

- [ ] [Azure ポータル](https://portal.azure.com) で **rg-kirinws が消えている**ことを、ご自身の画面で目視確認した
- [ ] Lab 2 でポータルから手動作成した**ナレッジベース（omics-kb）などの残骸がない**ことを確認した（あればその場で削除）
- [ ] Key Vault などが残っている場合はポータルで手動パージした（本構成は `purge_soft_delete_on_destroy=true` 設定済みですが、念のため確認）
- [ ] [記録シート](templates/00-record-sheet.md)のクリーンアップ欄に**「destroy 完了・残留なし」**とチェックを入れた

> 検証のために環境を残したい場合は、継続課金であることを必ず担当者と共有してください。Terraform コードがあれば、いつでも同じ環境を再作成できます。

---

## 参考リンク（Microsoft Discovery 公式）

Microsoft が公開している完成形の研究 AI プラットフォーム **Microsoft Discovery**（MIT ライセンス）の公式リソースです。本ワークショップで自社構築した構成（Foundry + AI Search + エージェント）が、製品としてどうパッケージ化されているかを見る参考にしてください。

- [github.com/microsoft/discovery](https://github.com/microsoft/discovery) … 公式リポジトリ。Discovery アプリのダウンロードとエージェントカタログがここにあります。
- [15 分クイックスタート](https://github.com/microsoft/discovery/blob/main/docs/discovery-app/quickstart.md) … アプリを最短で動かす手順書（**GitHub Copilot サブスクリプションが必要**です）。
- [公式ハウツー動画一覧](https://github.com/microsoft/discovery/blob/main/docs/how-to-videos/README.md) … 機能ごとの短い操作動画。英語ですが画面を追うだけで雰囲気が掴めます。
- [MS Learn: Microsoft Discovery ドキュメント（日本語）](https://learn.microsoft.com/ja-jp/azure/microsoft-discovery/) … 公式の概念・チュートリアル文書。

> **GraphRAG との関係:** Discovery の知識ベース機能 **Bookshelf** は、公式に
> 「GraphRAG-based knowledge base」と明記されています。Day 2 オプションの
> GraphRAG デモ（上記「オプション: GraphRAG ゲノム解析デモ」）は、まさに
> この製品内部と同系の技術を自社構築で体験する内容になっています。

---

> 講師・運営向けの会前チェックリストは社内資料のため、配布リポジトリには含まれていません。

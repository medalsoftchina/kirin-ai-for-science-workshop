# オプション: GraphRAG ゲノム解析デモ（講師実演）

Day 2 のオプションモジュール（スライド S24、講師実演・了解レベル・目安 30 分）です。
参加者の皆さまの実操作はありません。時間に余裕がある場合のみ実施します。

> **参考:** Microsoft Discovery の知識ベース機能 **Bookshelf** は、公式に
> 「GraphRAG-based knowledge base」と明記されています（[公式クイックスタート](https://github.com/microsoft/discovery/blob/main/docs/discovery-app/quickstart.md) 参照）。
> 本デモは、その製品内部と同系の技術の**自社構築版**に相当します。

## このデモについて

ベクトル RAG（Lab 2）が「文書の中の局所的な事実」を探すのに対し、**GraphRAG** は
LLM で遺伝子・変異・表現型の**関係グラフ**を抽出し、コーパス全体の俯瞰や
多段の関連探索を可能にします。

- **Global Search:** コーパス全体への俯瞰的な質問
- **Local Search:** 特定の遺伝子・エンティティの近傍探索

デモでは、このリポジトリの `reference/` に含まれる**既存の GraphRAG パイプライン**
（`reference/src/graphrag` / `reference/src/query`）をそのまま使用します。講師が
事前構築したインデックスに対してクエリを実行する様子をご覧いただきます。

## コーパス

2026-09-28 の実測インデックスは **`data/omics`** を使用しています
（`scripts/build_omics_graphrag_corpus.py` で 3 文書に変換）。

- **`data/omics`** … Lab 2 と同じ乳酸菌（*L. plantarum*）耐酸性論文 PDF × 2 ＋
  ClinVar サブセット（8 遺伝子 × 20 変異）← 本デモで使用
- **`reference/data/sample_biomedical`** … 腫瘍学系のサンプル文献 8 篇
  （別コーパスとして利用可能）

## バージョンについて（重要）

`graphrag` ライブラリは **2.x に固定**します（`reference/requirements.txt` に
pin 済み）。

```
graphrag>=2.7,<3.0
```

3.x 系は本パイプラインの `settings.yaml`・CLI 呼び出しと互換性がないため、
**3.x には対応していません**。

## インデックスの構築（会前に講師が実施）

Azure OpenAI の設定（`reference/src/graphrag/settings.yaml`、エンドポイントと
API キー）が必須です。インデックス構築は LLM によるエンティティ・関係の全抽出を伴うため、
**時間と Azure OpenAI の呼び出し費用がかかります。会前に必ず構築を完了させます**
（当日の現場では構築しません）。

**2026-09-28 実測完了**（macOS / graphrag 2.7.2 / chat: `gpt-4.1` /
embedding: `text-embedding-3-large`）。以下は検証済みの正確な手順です。

```bash
# 0) Python 3.12 が必要（graphrag 2.x は >=3.10,<3.13。3.14 ではインストール不可）
brew install python@3.12   # 未導入の場合

# 1) venv 作成と依存インストール（リポジトリ直下から）
/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv reference/.venv
reference/.venv/bin/pip install --upgrade pip
reference/.venv/bin/pip install "graphrag>=2.7,<3.0" pandas pyarrow lancedb \
    python-dotenv tiktoken pymupdf

# 2) 認証情報（reference/.env、gitignore 済み・コミット厳禁）
#    AZURE_OPENAI_API_KEY=...   （az cognitiveservices account keys list で取得）
#    AZURE_OPENAI_ENDPOINT=https://<account>.cognitiveservices.azure.com/
#    GRAPHRAG_API_KEY=<同上のキー>

# 3) コーパス構築（以降は reference/ をカレントディレクトリとして実行）
cd reference
.venv/bin/python scripts/build_omics_graphrag_corpus.py
#    → data/omics の耐酸性 PDF x2 をテキスト化 + clinvar_subset.csv を
#      遺伝子別要約に変換し、data/graphrag/input/*.txt に出力（計 3 文書）

# 4) インデックス構築（settings: src/graphrag/settings.yaml。実測 約56分/3文書）
.venv/bin/python -m src.graphrag.run_index --root data/graphrag
```

実行結果（2026-09-28）: documents 3 / entities 1,965 / relationships 2,550 /
communities 317 / community_reports 317。成果物は
`reference/data/graphrag/output/*.parquet`（gitignore 済み）。

> **再デプロイ時の注意:** Terraform 環境を destroy → 再作成すると
> エンドポイント名と API キーが変わります。その場合は `reference/.env` を
> 更新してから手順 4 を再実行し、**インデックスを会前に再構築**してください。
> （キャッシュは `data/graphrag/cache` に残るため、キー以外同じ設定なら
> 再構築は速くなります。）

当日のクエリ実行結果の見本は `graphrag_demo/sample_outputs.md` にあります
（ライブ実行できない場合の fallback 資料）。

## デモクエリ（スライド S24 に対応）

引き続き `reference/` ディレクトリで実行します。両クエリとも 2026-09-28 に
実測済み（出力は `graphrag_demo/sample_outputs.md` 参照）。

```bash
# Global Search: 全体俯瞰（実測 約5〜6分）
.venv/bin/python -m src.query.run_query --root data/graphrag --method global \
  --query "耐酸性表型に関連する遺伝子群を概観して"

# Local Search: 特定遺伝子の近傍探索（実測 約45秒）
.venv/bin/python -m src.query.run_query --root data/graphrag --method local \
  --query "gadB に関連する表型は？"
```

## ベクトル RAG との比較（講義用の観点）

| 観点 | ベクトル RAG（Lab 2） | GraphRAG |
|---|---|---|
| 得意な質問 | 文書内の局所的事実 | 関係性の俯瞰・多段の関連探索 |
| インデックスコスト | 低い（埋め込みのみ） | 高い（LLM による抽出） |
| 研究用途の例 | 論文の引用つき QA | 遺伝子–疾患ネットワークの探索 |

## ボーナス: グラフの可視化

`reference/` には簡易 Web UI（`reference/app.py`）があり、抽出されたグラフをブラウザで
眺めることができます。時間があればお見せします。

```bash
cd reference
uvicorn app:app
```

## 出典に関する注意

元ネタの [microsoft/genomicsnotebook](https://github.com/microsoft/genomicsnotebook) は
**アーカイブ済み**で、ノートブック内のライブラリがバージョン固定されておらず、
そのままでは動作しません。そのため本デモでは、**このリポジトリ独自のパイプライン**
（graphrag 2.x 固定＋ Azure OpenAI 設定済み＋インデックス事前構築）を使用します。
アーカイブ済みリポジトリを業務利用する際は、必ず「フォーク＋バージョン固定＋
事前検証」を行ってください。

---

> 講師向けの会前チェックリスト（索引の事前構築・fallback 録画など）は社内資料のため、
> 配布リポジトリには含まれていません。

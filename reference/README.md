# reference/ - GraphRAG パイプライン参考実装

このディレクトリは、ワークショップ Day 2 のオプションモジュール
**「GraphRAG ゲノム解析デモ」(スライド S24、講師実演)** で使う、
Microsoft GraphRAG の参考実装です。受講者の皆さまは当日この中身を実行する必要は
ありません。お持ち帰りいただき、自社構築の参考コードとしてご覧ください。

> Microsoft Discovery のナレッジベース (Bookshelf) は公式に
> **「GraphRAG-based knowledge base」** と明記されています。
> このパイプラインは、その製品内部と同系の技術の自社構築版に相当します。

## 構成

```
src/graphrag/          GraphRAG インデックス構築 (settings.yaml, run_index.py,
                       コミュニティ要約の抽出 extract_summaries.py)
src/query/run_query.py Global / Local / Drift / Basic 検索 CLI
scripts/
  build_omics_graphrag_corpus.py   data/omics (乳酸菌論文 PDF + ClinVar) から
                                   GraphRAG 入力テキストを生成
  prepare_sample_data.py           data/sample_biomedical (腫瘍学 8 篇) から生成
data/
  graphrag/            GraphRAG 作業ディレクトリ (settings.yaml と prompts/ を同梱。
                       input/output/cache/lancedb は gitignore)
  sample_biomedical/   デモ用サンプル文献 (腫瘍学 8 篇)
requirements.txt       依存関係 (graphrag は 2.x 固定: >=2.7,<3.0)
.env.example           環境変数のテンプレート
```

## クイックスタート

すべて `reference/` をカレントディレクトリとして実行します。
**graphrag 2.x は Python 3.10〜3.12 が必要です** (3.13 以降では動きません)。

```bash
cd reference

python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env   # Azure OpenAI のエンドポイント・キー・デプロイ名を記入

# 1. コーパス生成 (ワークショップと同じオミックス版)
python scripts/build_omics_graphrag_corpus.py

# 2. インデックス構築 (Azure OpenAI の呼び出し費用と時間がかかります。
#    小さめのコーパスでも 30〜60 分程度。デプロイの TPM を大きめにすると速くなります)
python -m src.graphrag.run_index --root data/graphrag --force-settings

# 3. 検索
python -m src.query.run_query --root data/graphrag --method global \
    --query "耐酸性表型に関連する遺伝子群を概観して"
python -m src.query.run_query --root data/graphrag --method local \
    --query "gadB に関連する表型は？"
```

実際の出力例は [`../graphrag_demo/sample_outputs.md`](../graphrag_demo/sample_outputs.md)
にあります (2026-09-28 実測: entities 1,965 / relationships 2,550 / communities 317)。

## 注意点

- **graphrag は 2.x 固定**です (`>=2.7,<3.0`)。3.x とは settings.yaml の schema が
  非互換のため、アップグレードしないでください。
- インデックス構築は LLM 呼び出しが多く、デプロイの TPM が小さいと 429 (レート制限) で
  遅くなります。指数バックオフで自動リトライしますが、時間に余裕をもって実行してください。
- コーパスを変えた場合はインデックスの再構築が必要です (コミュニティは自動更新されません)。
- エンドポイントやキーを変更した場合は `.env` を更新してから再構築してください。

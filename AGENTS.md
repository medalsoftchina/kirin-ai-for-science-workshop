# AGENTS.md - リポジトリ規約

このファイルは、本リポジトリで作業する人 (および AI コーディングエージェント) 向けの
規約です。**実際のコードと一致していること**を常に保ってください。コードと矛盾したら、
先にこのファイルを現実に合わせてからコードを直します。

## 1. このリポジトリについて

- 2026-09-28/29 の「Microsoft Azure AI for Science」ワークショップ
  (キリン中央研究所向け) のハンズオン資材です。
- Day 2 (ハンズオン) の各 Lab と、スライド (Deck) の記述が対応しています。
  Deck 側で明示されているインターフェース (後述) を勝手に変えないでください。

## 2. 構成

```
kirin_terraform/                 Lab 0: AVM モジュールで Foundry 環境をデプロイ
                                 (gpt-6-luna / gpt-5.6-terra / gpt-4.1 /
                                 text-embedding-3-large の 4 モデル +
                                 AI Search Basic + Storage + Key Vault + Cosmos DB)
build-your-first-agent-trimmed/  Lab 3: Agent + Code Interpreter サンプル
data/omics/                      Lab 2 用公開データ (出典は SOURCE.md)
handson/                         受講者向けガイド・手順書・演習テンプレート
graphrag_demo/                   オプション GraphRAG デモの手順と実測結果
reference/                       GraphRAG パイプライン参考実装
setup/                           環境セットアップスクリプト (.sh / .ps1)
```

## 3. ルール

1. **ドキュメントはすべて日本語で。** コードコメント・README・ガイドを問いません。
2. **公開データまたはダミーデータのみ**を置くこと。顧客データ・機密情報・
   `.env`・実際のリソース名/エンドポイント/キーをコミットしてはいけません。
3. **モデルバージョンの口径**: 主力 `gpt-6-luna` (2026-09-22)、比較用
   `gpt-5.6-terra` (2026-07-09)、Agent Service (Lab 3) 用 `gpt-4.1` (2025-04-14)、
   埋め込み `text-embedding-3-large`。リージョンは japaneast。
   ※ gpt-6 / 5.6 系プレビューモデルは Agent Service と非互換 (2026-09-28 実測)
   なので、Lab 3 では GA モデルを使います。
4. **graphrag は 2.x 固定** (`reference/requirements.txt` で `>=2.7,<3.0`)。
   3.x とは settings.yaml の schema が非互換です。
5. **コスト管理**: AI Search Basic は作成時点から課金されます (約 $75/月)。
   すべての手順書に `terraform destroy` のクリーンアップを残してください。
6. **Deck との整合**: `kirin_terraform` の 5 つの output 名、Lab 3 の `.env` の
   キー名 (`PROJECT_ENDPOINT` / `MODEL_DEPLOYMENT_NAME`) は Deck 上の表記と
   一致させること。変える場合は Deck も同時に直してください。
7. **受講者向けスクリプトは Windows / macOS 両対応** (`.sh` と `.ps1` のペア、
   または単一スクリプトで OS 自動判定)。出力メッセージは日本語で。

## 4. 検証コマンド

```bash
# Lab 3 のローカル部分 (build-your-first-agent-trimmed/ で)
python build_omics_db.py        # variants / phenotype_records が各 300 件

# kirin_terraform/ で (terraform があれば)
terraform init -backend=false && terraform validate

# GraphRAG デモ (reference/ で。要 .env の Azure OpenAI 設定)
python scripts/build_omics_graphrag_corpus.py
python -m src.graphrag.run_index --root data/graphrag --force-settings
python -m src.query.run_query --root data/graphrag --method local \
    --query "gadB に関連する表型は？"
```

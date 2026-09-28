# Microsoft Azure AI for Science ワークショップ - ハンズオンリポジトリ

キリン中央研究所 × Microsoft × Medalsoft「Azure R&D Discovery Platform」ワークショップ
(2026/09/28-29) のハンズオン用リポジトリです。

- **Day 1 (9/28)**: 講義中心 - Azure R&D 基盤、研究 AI / Agent、ガバナンス
- **Day 2 (9/29, 13:00-18:00)**: ハンズオン中心 - 本リポジトリを使って実際に手を動かします

> 本ワークショップは Microsoft Discovery の「導入」ではなく、Discovery を完成形の参照として、
> **Azure のサービス (Foundry / AI Search 等) を組み合わせた自社構築**を学ぶものです。

## 事前準備 (当日までに)

1. Azure CLI / Terraform (>= 1.12) / Git / VS Code が使える PC
   - まとめてインストールするスクリプトがあります → **[setup/README.md](setup/README.md)**
   - 社内ポリシーでローカルにインストール・az login できない方は、ブラウザ上の
     **Azure Cloud Shell** でも実行できます → **[kirin_terraform/CLOUDSHELL.md](kirin_terraform/CLOUDSHELL.md)**
2. Azure サブスクリプションへの Contributor 以上の権限 (サブスクリプション ID は当日の座席カード)
3. 本リポジトリの clone (または ZIP ダウンロード)
4. 詳細は **[handson/HANDSON_GUIDE.md](handson/HANDSON_GUIDE.md)「0. 事前準備」** を参照

## Day 2 の進行 (13:00-18:00)

| 時間 | 内容 | 使うもの |
|---|---|---|
| 13:15-13:50 | **Lab 0** 環境構築 (Terraform × AVM) | [`kirin_terraform/`](kirin_terraform/) |
| 13:50-14:30 | **Lab 1** Foundry ポータル体験 | [handson/HANDSON_GUIDE.md](handson/HANDSON_GUIDE.md) |
| 14:45-15:30 | **Lab 2** RAG 構築 (Foundry IQ) | [`data/omics/`](data/omics/) |
| 15:40-16:20 | **Lab 3** エージェント (講師実演) | [`build-your-first-agent-trimmed/`](build-your-first-agent-trimmed/) |
| 16:20-17:10 | **演習** サービスマップ / AI 評価カード / Readiness | [`handson/templates/`](handson/templates/) |
| 17:10-17:30 | **クリーンアップ** (terraform destroy) | [`kirin_terraform/`](kirin_terraform/) |

## ディレクトリ案内

| パス | 内容 |
|---|---|
| [`kirin_terraform/`](kirin_terraform/) | Lab 0: Azure AI Foundry 環境を Terraform (AVM) でデプロイ |
| [`build-your-first-agent-trimmed/`](build-your-first-agent-trimmed/) | Lab 3: Agent + Code Interpreter のサンプルコード (講師実演・お持ち帰り用) |
| [`data/omics/`](data/omics/) | Lab 2: 公開オミックスデータ (乳酸菌論文 PDF x2 + ClinVar サブセット + キリン研究領域の論文 10 篇) |
| [`handson/`](handson/) | ハンズオンガイド・クリック手順書・演習テンプレート (4 つの成果物) |
| [`graphrag_demo/`](graphrag_demo/) | オプション: GraphRAG ゲノム解析デモ (講師実演) の手順と実測結果 |
| [`reference/`](reference/) | GraphRAG パイプラインの参考実装 (自社構築の参考コード) |
| [`setup/`](setup/) | Windows / macOS 用の環境セットアップスクリプト |

## クリーンアップ (必須)

AI Search Basic は**作成した時点で課金が始まります (約 $75/月)**。
演習が終わったら必ずリソースを削除してください:

```bash
cd kirin_terraform
terraform destroy
```

詳細: [handson/HANDSON_GUIDE.md](handson/HANDSON_GUIDE.md)「クリーンアップ」

## 参考リンク (Microsoft Discovery 公式)

- [microsoft/discovery](https://github.com/microsoft/discovery) - Discovery App ダウンロード・Agent カタログ
- [15 分クイックスタート](https://github.com/microsoft/discovery/blob/main/docs/discovery-app/quickstart.md) - Bookshelf (GraphRAG ベースのナレッジベース) を体験
- [Microsoft Learn - Microsoft Discovery](https://learn.microsoft.com/ja-jp/azure/microsoft-discovery/) - クラウド版の公式ドキュメント

# -*- coding: utf-8 -*-
# ============================================================
# Day2 Lab 3: はじめてのエージェント (Build your first agent)
#
# Azure AI Foundry の Agent Service に接続し、
# Code Interpreter ツールを持つエージェントを作成して、
# SQLite データベース (omics.db) を解析させるサンプルです。
#
# 実行前に:
#   1. `python build_omics_db.py` で omics.db を作成しておく
#   2. `.env` に PROJECT_ENDPOINT / MODEL_DEPLOYMENT_NAME を設定
#   3. `az login` 済みであること (DefaultAzureCredential を使用)
# ============================================================

import os
import shutil
from pathlib import Path

from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.agents import AgentsClient
from azure.ai.agents.models import (
    CodeInterpreterTool,
    FilePurpose,
    ListSortOrder,
    MessageImageFileContent,
    MessageTextContent,
    MessageTextFilePathAnnotation,
)

# ============================================================
# 【STEP 1】環境変数の読み込み
#   .env に書いた接続情報を読み込みます。
#   PROJECT_ENDPOINT = Foundry プロジェクトのエンドポイント
#   MODEL_DEPLOYMENT_NAME = モデルのデプロイ名 (例: gpt-4.1 ― Agent Service 互換の GA モデル)
# ============================================================
load_dotenv()
PROJECT_ENDPOINT = os.environ["PROJECT_ENDPOINT"]
MODEL_DEPLOYMENT_NAME = os.environ["MODEL_DEPLOYMENT_NAME"]

# このファイル (src/workshop/main.py) から見た omics.db の場所
DB_PATH = Path(__file__).resolve().parents[2] / "omics.db"
OUTPUT_DIR = Path("./output")

# ============================================================
# 【STEP 2】AgentsClient の作成
#   DefaultAzureCredential は az login した資格情報を使います。
#   エンドポイント形式:
#   https://<foundry名>.services.ai.azure.com/api/projects/kirin-rnd-lab
# ============================================================
agents_client = AgentsClient(
    endpoint=PROJECT_ENDPOINT,
    credential=DefaultAzureCredential(),
)

with agents_client:
    # ========================================================
    # 【STEP 3】SQLite ファイルのアップロード
    #   Code Interpreter が読めるように omics.db を
    #   Foundry 側にアップロードします。
    #   ※ Code Interpreter は .db 拡張子を受け付けないため、
    #     .txt 拡張子にコピーしてからアップロードします
    #     (中身は SQLite のまま。接続時のファイル名に注意)。
    # ========================================================
    if not DB_PATH.exists():
        raise SystemExit(
            "omics.db が見つかりません。先に `python build_omics_db.py` を実行してください。"
        )
    UPLOAD_PATH = DB_PATH.with_name("omics_db.txt")
    shutil.copy(DB_PATH, UPLOAD_PATH)
    file = agents_client.files.upload_and_poll(
        file_path=str(UPLOAD_PATH), purpose=FilePurpose.AGENTS
    )
    print(f"アップロード完了: {file.id}")

    # ========================================================
    # 【STEP 4】エージェントの作成
    #   CodeInterpreterTool にファイルIDを渡すと、
    #   エージェントがそのファイルを Python で解析できます。
    # ========================================================
    code_interpreter = CodeInterpreterTool(file_ids=[file.id])
    agent = agents_client.create_agent(
        model=MODEL_DEPLOYMENT_NAME,
        name="omics-analysis-agent",
        instructions=(
            "あなたはオミックス研究を支援するアシスタントです。"
            "添付ファイル (omics_db.txt) は SQLite データベースです。"
            "拡張子は .txt ですが中身は SQLite 形式なので、"
            "Python の sqlite3 で接続して解析してください。"
        ),
        tools=code_interpreter.definitions,
        tool_resources=code_interpreter.resources,
    )
    print(f"エージェント作成: {agent.id}")

    # ========================================================
    # 【STEP 5】スレッドとメッセージの作成
    #   スレッドは会話の入れ物です。
    #   解析してほしい内容を日本語で指示します。
    # ========================================================
    thread = agents_client.threads.create()
    agents_client.messages.create(
        thread_id=thread.id,
        role="user",
        content=(
            "添付の SQLite データベース (omics_db.txt、拡張子は .txt ですが "
            "sqlite3.connect で開けます) を解析してください。\n"
            "1. variants テーブルと phenotype_records テーブルを "
            "variant_id で結合してください。\n"
            "2. clinical_significance が 'Pathogenic' の変異について、"
            "遺伝子 (gene) ごとの allele_freq の平均を計算してください。\n"
            "3. 平均 allele_freq が高い上位10遺伝子の横棒グラフを作成し、"
            "PNG 画像として保存してください。"
        ),
    )

    # ========================================================
    # 【STEP 6】実行 (Run)
    #   create_and_process は完了まで自動で待ちます。
    #   エージェントは自分で pandas / matplotlib のコードを
    #   書いて Code Interpreter 上で実行します。
    # ========================================================
    run = agents_client.runs.create_and_process(
        thread_id=thread.id, agent_id=agent.id
    )
    print(f"実行完了: status={run.status}")
    if run.status == "failed":
        print(f"エラー詳細: {run.last_error}")

    # ========================================================
    # 【STEP 7】結果の表示と画像のダウンロード
    #   エージェントの回答テキストを表示し、
    #   生成されたファイル (PNG) を ./output/ に保存します。
    #   PNG は「sandbox:/mnt/data/...」リンク (file_path アノテーション)
    #   か、インライン画像 (MessageImageFileContent) として返ります。
    # ========================================================
    OUTPUT_DIR.mkdir(exist_ok=True)
    messages = agents_client.messages.list(
        thread_id=thread.id, order=ListSortOrder.ASCENDING
    )
    for msg in messages:
        for content in msg.content:
            if isinstance(content, MessageTextContent):
                print(f"\n[{msg.role}] {content.text.value}")
                for ann in content.text.annotations or []:
                    if isinstance(ann, MessageTextFilePathAnnotation):
                        file_id = ann.file_path.file_id
                        out_name = Path(ann.text).name or f"{file_id}.png"
                        agents_client.files.save(
                            file_id=file_id,
                            file_name=out_name,
                            target_dir=OUTPUT_DIR,
                        )
                        print(f"\nファイルを保存しました: {OUTPUT_DIR / out_name}")
            elif isinstance(content, MessageImageFileContent):
                file_id = content.image_file.file_id
                out_name = f"{file_id}.png"
                agents_client.files.save(
                    file_id=file_id,
                    file_name=out_name,
                    target_dir=OUTPUT_DIR,
                )
                print(f"\n画像を保存しました: {OUTPUT_DIR / out_name}")

    # ========================================================
    # 【STEP 8】後片付け
    #   課金とリソース整理のためエージェントを削除します。
    # ========================================================
    agents_client.delete_agent(agent.id)
    print("\nエージェントを削除しました。おつかれさまでした!")

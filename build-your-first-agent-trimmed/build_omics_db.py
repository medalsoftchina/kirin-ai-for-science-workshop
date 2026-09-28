# -*- coding: utf-8 -*-
# ============================================================
# Day2 Lab 3 準備スクリプト: ダミーのオミックスCSVから
# SQLite データベース (omics.db) を作成します。
#
# 使い方: python build_omics_db.py
# 再実行してもOK (既存テーブルは削除して作り直します)。
# ============================================================

import csv
import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
CSV_PATH = BASE_DIR / "data" / "omics_variants.csv"
DB_PATH = BASE_DIR / "omics.db"


def main() -> None:
    if not CSV_PATH.exists():
        raise SystemExit(f"CSVファイルが見つかりません: {CSV_PATH}")

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # --- 既存テーブルを削除 (冪等性のため) ---
    cur.execute("DROP TABLE IF EXISTS phenotype_records")
    cur.execute("DROP TABLE IF EXISTS variants")

    # --- variants テーブル: 変異の基本情報 ---
    cur.execute(
        """
        CREATE TABLE variants (
            variant_id TEXT PRIMARY KEY,
            gene TEXT,
            clinical_significance TEXT,
            allele_freq REAL,
            sample_id TEXT,
            batch TEXT
        )
        """
    )

    # --- phenotype_records テーブル: 表現型アノテーション ---
    cur.execute(
        """
        CREATE TABLE phenotype_records (
            id INTEGER PRIMARY KEY,
            variant_id TEXT REFERENCES variants(variant_id),
            phenotype_annotation TEXT,
            sample_id TEXT,
            batch TEXT
        )
        """
    )

    # --- CSV を1行ずつ読み込んで2テーブルに振り分ける ---
    n_variants = 0
    n_phenotypes = 0
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            cur.execute(
                "INSERT INTO variants VALUES (?, ?, ?, ?, ?, ?)",
                (
                    row["variant_id"],
                    row["gene"],
                    row["clinical_significance"],
                    float(row["allele_freq"]),
                    row["sample_id"],
                    row["batch"],
                ),
            )
            n_variants += 1
            cur.execute(
                "INSERT INTO phenotype_records "
                "(variant_id, phenotype_annotation, sample_id, batch) "
                "VALUES (?, ?, ?, ?)",
                (
                    row["variant_id"],
                    row["phenotype_annotation"],
                    row["sample_id"],
                    row["batch"],
                ),
            )
            n_phenotypes += 1

    conn.commit()
    conn.close()

    print(f"データベースを作成しました: {DB_PATH}")
    print(f"variants テーブル: {n_variants} 件")
    print(f"phenotype_records テーブル: {n_phenotypes} 件")


if __name__ == "__main__":
    main()

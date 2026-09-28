"""
build_omics_graphrag_corpus.py
Day2 S24 GraphRAG デモ用のコーパスを構築する。

内容:
    1. data/omics/plantarum_acid_resistance_1.pdf / _2.pdf を pymupdf で
       テキスト抽出し、reference/data/graphrag/input/ へ .txt として出力。
    2. data/omics/clinvar_subset.csv を遺伝子ごとに集計し、
       臨床意義別の変異数を含む可読テキスト clinvar_summary.txt を出力。

実行 (reference/ をカレントディレクトリとして):
    python scripts/build_omics_graphrag_corpus.py
"""
from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path

import fitz  # pymupdf

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]  # repo ルート (reference/ の一つ上)
OMICS_DIR = REPO_ROOT / "data" / "omics"
INPUT_DIR = HERE.parent / "data" / "graphrag" / "input"

MAIN_PDFS = [
    "plantarum_acid_resistance_1.pdf",
    "plantarum_acid_resistance_2.pdf",
]


def extract_pdfs() -> list[Path]:
    written = []
    for name in MAIN_PDFS:
        src = OMICS_DIR / name
        if not src.exists():
            raise SystemExit(f"PDF not found: {src}")
        doc = fitz.open(src)
        text = "\n\n".join(page.get_text() for page in doc)
        doc.close()
        out = INPUT_DIR / (src.stem + ".txt")
        out.write_text(text, encoding="utf-8")
        written.append(out)
        print(f"  - {out.name}: {len(text):,} chars from {name}")
    return written


def summarize_clinvar() -> Path:
    src = OMICS_DIR / "clinvar_subset.csv"
    if not src.exists():
        raise SystemExit(f"CSV not found: {src}")

    by_gene: dict[str, list[dict]] = defaultdict(list)
    with src.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            by_gene[row["gene"]].append(row)

    lines = [
        "ClinVar subset summary (8 genes x 20 variants)",
        f"Source: {src}",
        "",
    ]
    for gene in sorted(by_gene):
        rows = by_gene[gene]
        counts = Counter(r["clinical_significance"] for r in rows)
        lines.append(f"## {gene} ({len(rows)} variants)")
        for sig, n in counts.most_common():
            lines.append(f"  - {sig}: {n}")
        lines.append("  Variants:")
        for r in rows:
            lines.append(
                f"    * {r['variant_name']} | {r['clinical_significance']} | {r['condition']}"
            )
        lines.append("")

    out = INPUT_DIR / "clinvar_summary.txt"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"  - {out.name}: {len(by_gene)} genes summarized")
    return out


def main() -> None:
    INPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Building GraphRAG input corpus into {INPUT_DIR}")
    extract_pdfs()
    summarize_clinvar()
    print("Done.")


if __name__ == "__main__":
    main()

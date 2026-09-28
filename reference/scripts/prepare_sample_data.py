"""
scripts/prepare_sample_data.py
Converts data/sample_biomedical/sample_articles.json into individual text files
for GraphRAG indexing, and generates metadata.csv.
"""
import csv
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SAMPLE_JSON = REPO_ROOT / "data" / "sample_biomedical" / "sample_articles.json"
OUT_DIR = REPO_ROOT / "data" / "sample_biomedical" / "input"
GRAPHRAG_INPUT = REPO_ROOT / "data" / "graphrag" / "input"
META_CSV = REPO_ROOT / "data" / "sample_biomedical" / "metadata.csv"


def prepare() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    GRAPHRAG_INPUT.mkdir(parents=True, exist_ok=True)

    with open(SAMPLE_JSON, "r", encoding="utf-8") as f:
        articles = json.load(f)

    print(f"Loaded {len(articles)} sample biomedical articles.")

    csv_rows = []
    for art in articles:
        doc_id = art["id"]
        title = art["title"]
        doi = art["doi"]
        category = art["category"]
        entities = ", ".join(art.get("entities", []))
        abstract = art["abstract"]
        content = art["content"]

        text_body = f"""Title: {title}
DOI: {doi}
Category: {category}
Key Biomedical Entities: {entities}

Abstract:
{abstract}

Clinical Details & Mechanism:
{content}
"""
        # 1. Write to sample input
        file_path = OUT_DIR / f"{doc_id}.txt"
        file_path.write_text(text_body, encoding="utf-8")

        # 2. Copy to graphrag input for immediate indexing
        gr_path = GRAPHRAG_INPUT / f"{doc_id}.txt"
        gr_path.write_text(text_body, encoding="utf-8")

        csv_rows.append({
            "id": doc_id,
            "title": title,
            "doi": doi,
            "category": category,
            "entities": entities,
        })

    with open(META_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["id", "title", "doi", "category", "entities"])
        writer.writeheader()
        writer.writerows(csv_rows)

    print(f"Staged {len(articles)} text files into:\n  - {OUT_DIR}\n  - {GRAPHRAG_INPUT}")
    print(f"Generated metadata CSV at: {META_CSV}")


if __name__ == "__main__":
    prepare()

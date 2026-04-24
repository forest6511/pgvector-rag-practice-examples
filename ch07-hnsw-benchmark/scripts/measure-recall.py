#!/usr/bin/env python3
"""ch07-hnsw-benchmark/scripts/measure-recall.py

ground-truth.sql で出力した eval/gt.csv と、
HNSW index 経由で取得した top-k 結果を比較して recall@10 を計算する。

使い方:
    python scripts/measure-recall.py --ef 40 --k 10
"""
from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path

import psycopg

DSN = os.environ.get("DSN", "postgresql://rag:ragpass@localhost:5432/ragdb")


def load_gt(path: Path) -> dict[int, list[int]]:
    gt: dict[int, list[int]] = {}
    with path.open() as f:
        reader = csv.reader(f)
        next(reader)  # header
        for row in reader:
            qid = int(row[0])
            # PostgreSQL array_agg は "{1,2,3}" 形式の文字列
            ids = [int(x) for x in row[1].strip("{}").split(",")]
            gt[qid] = ids
    return gt


def measure(ef: int, k: int, gt: dict[int, list[int]]) -> float:
    hits = 0
    total = 0
    with psycopg.connect(DSN) as conn:
        conn.execute(f"SET hnsw.ef_search = {ef}")
        with conn.cursor() as cur:
            for qid, gt_ids in gt.items():
                cur.execute(
                    """
                    SELECT id FROM items
                    ORDER BY embedding <-> (SELECT embedding FROM items WHERE id = %s)
                    LIMIT %s
                    """,
                    (qid, k),
                )
                hnsw_ids = {r[0] for r in cur.fetchall()}
                hits += len(hnsw_ids & set(gt_ids[:k]))
                total += k
    return hits / total


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--ef", type=int, default=40)
    p.add_argument("--k", type=int, default=10)
    p.add_argument("--gt", default="eval/gt.csv")
    args = p.parse_args()

    gt = load_gt(Path(args.gt))
    recall = measure(args.ef, args.k, gt)
    print(f"ef_search={args.ef} k={args.k} recall@{args.k}={recall:.4f}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# ch08-ivfflat-benchmark/scripts/measure-recall.py
# Ch07 版とほぼ同じ。ivfflat.probes をセッションで設定して recall@10 を計算する。
# 使い方:
#   python scripts/measure-recall.py --probes 10 > results/probes-10.txt

from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path

import psycopg


def load_gt(path: Path) -> dict[int, list[int]]:
    gt: dict[int, list[int]] = {}
    with path.open() as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            qid = int(row[0])
            ids = [int(x) for x in row[1].strip("{}").split(",")]
            gt[qid] = ids
    return gt


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--probes", type=int, default=1)
    ap.add_argument("--k", type=int, default=10)
    ap.add_argument("--gt", type=Path, default=Path("eval/gt.csv"))
    args = ap.parse_args()

    dsn = os.environ.get(
        "PG_DSN", "host=localhost user=rag password=ragpass dbname=ragdb"
    )
    gt = load_gt(args.gt)

    hits = 0
    total = 0
    with psycopg.connect(dsn) as conn, conn.cursor() as cur:
        cur.execute(f"SET ivfflat.probes = {args.probes}")
        for qid, gt_ids in gt.items():
            cur.execute(
                """
                SELECT id FROM items
                ORDER BY embedding <-> (
                  SELECT embedding FROM items WHERE id = %s LIMIT 1
                )
                LIMIT %s
                """,
                (qid, args.k),
            )
            got = {row[0] for row in cur.fetchall()}
            hits += len(got & set(gt_ids[: args.k]))
            total += args.k

    recall = hits / total if total else 0.0
    print(f"probes={args.probes} k={args.k} recall@{args.k}={recall:.4f}")


if __name__ == "__main__":
    main()

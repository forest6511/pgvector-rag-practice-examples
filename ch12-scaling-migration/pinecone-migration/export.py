"""Pinecone から ID リスト経由で fetch して CSV 出力"""
from pinecone import Pinecone
import csv
import json
import time

pc = Pinecone(api_key="YOUR_KEY")
idx = pc.Index("my-index")

BATCH = 100  # fetch 1 回あたりの ID 数

with open("pinecone_export.csv", "w") as f:
    writer = csv.writer(f)
    writer.writerow(["id", "embedding", "metadata"])

    for batch in chunked(all_ids, BATCH):
        resp = idx.fetch(ids=batch, namespace="default")
        for vid, v in resp.vectors.items():
            writer.writerow([
                vid,
                "[" + ",".join(str(x) for x in v.values) + "]",
                json.dumps(v.metadata) if v.metadata else "{}",
            ])
        time.sleep(0.1)  # rate limit 配慮

# 実運用では `all_ids` はアプリ側の DB から事前に取得したリストを使い、
# `chunked` は itertools.islice などで実装する。

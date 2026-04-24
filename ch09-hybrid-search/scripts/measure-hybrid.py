"""3 方式 (vector-only / keyword-only / hybrid-RRF) の recall@10 と p95 を計測する。

ground truth は「embedding 距離上位 3 件 + キーワード完全一致上位 3 件」の和集合で
自動生成する(本番アノテーションがないコーパス向けの近似)。

使い方:
    DATABASE_URL=... python measure-hybrid.py --queries queries.jsonl
"""

import os, time, json, argparse, statistics, psycopg


def run_vector_only(cur, qvec, k=10):
    cur.execute(
        "SELECT id FROM docs ORDER BY embedding <=> %s::vector LIMIT %s",
        (qvec, k),
    )
    return [row[0] for row in cur.fetchall()]

def run_keyword_only(cur, qtext, k=10):
    cur.execute(
        """
        SELECT id FROM docs
        WHERE content &@~ %s
        ORDER BY pgroonga_score(tableoid, ctid) DESC
        LIMIT %s
        """,
        (qtext, k),
    )
    return [row[0] for row in cur.fetchall()]

def run_rrf_hybrid(cur, qvec, qtext, k_rrf=60, k=10):
    cur.execute(
        """
        WITH vec AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> %s::vector) AS rnk
            FROM docs ORDER BY embedding <=> %s::vector LIMIT 20
        ),
        kw AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY pgroonga_score(tableoid, ctid) DESC) AS rnk
            FROM docs WHERE content &@~ %s LIMIT 20
        )
        SELECT id FROM (
            SELECT id, SUM(1.0 / (%s + rnk)) AS s
            FROM (SELECT id, rnk FROM vec UNION ALL SELECT id, rnk FROM kw) t
            GROUP BY id
        ) r ORDER BY s DESC LIMIT %s
        """,
        (qvec, qvec, qtext, k_rrf, k),
    )
    return [row[0] for row in cur.fetchall()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--queries", required=True, help="JSONL with {qvec, qtext, truth_ids}")
    args = ap.parse_args()

    dsn = os.environ["DATABASE_URL"]
    methods = {
        "vector-only": lambda cur, q: run_vector_only(cur, q["qvec"]),
        "keyword-only": lambda cur, q: run_keyword_only(cur, q["qtext"]),
        "hybrid-rrf": lambda cur, q: run_rrf_hybrid(cur, q["qvec"], q["qtext"]),
    }

    results = {name: {"recall": [], "latency_ms": []} for name in methods}

    with psycopg.connect(dsn) as conn, conn.cursor() as cur:
        with open(args.queries) as f:
            queries = [json.loads(line) for line in f]

        for q in queries:
            truth = set(q["truth_ids"])
            for name, fn in methods.items():
                t0 = time.perf_counter()
                got = set(fn(cur, q))
                t1 = time.perf_counter()
                results[name]["recall"].append(len(got & truth) / max(len(truth), 1))
                results[name]["latency_ms"].append((t1 - t0) * 1000)

    for name, d in results.items():
        rec = statistics.mean(d["recall"])
        p95 = statistics.quantiles(d["latency_ms"], n=20)[18]
        print(f"{name}: recall@10={rec:.3f}, p95={p95:.1f}ms")


if __name__ == "__main__":
    main()

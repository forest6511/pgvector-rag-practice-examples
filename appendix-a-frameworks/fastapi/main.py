import os

import asyncpg
from fastapi import FastAPI
from pgvector.asyncpg import register_vector
from pydantic import BaseModel

from embedder import embed

app  = FastAPI()
pool: asyncpg.Pool | None = None


@app.on_event("startup")
async def startup() -> None:
    global pool
    dsn  = os.environ.get(
        "DATABASE_URL",
        "postgresql://rag:ragpass@localhost:5432/ragdb",
    )
    pool = await asyncpg.create_pool(dsn, init=register_vector)


@app.on_event("shutdown")
async def shutdown() -> None:
    if pool is not None:
        await pool.close()


class DocIn(BaseModel):
    title: str
    body:  str


@app.post("/docs")
async def create_doc(doc: DocIn):
    vec = embed(f"{doc.title}\n{doc.body}")
    async with pool.acquire() as conn:
        row_id = await conn.fetchval(
            """
            INSERT INTO docs (title, body, embedding)
            VALUES ($1, $2, $3)
            RETURNING id
            """,
            doc.title, doc.body, vec,
        )
    return {"ok": True, "id": row_id}


@app.get("/search")
async def search(q: str):
    vec = embed(q)
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, title
            FROM   docs
            ORDER  BY embedding <=> $1
            LIMIT  10
            """,
            vec,
        )
    return {"hits": [dict(r) for r in rows]}

import { NextRequest, NextResponse } from "next/server";
import { sql } from "drizzle-orm";
import { db } from "@/db";
import { embed } from "@/lib/embedder";
import pgvector from "pgvector/utils";

export async function GET(req: NextRequest) {
  const q   = req.nextUrl.searchParams.get("q") ?? "";
  const vec = await embed(q);
  const lit = pgvector.toSql(vec);

  const result = await db.execute(
    sql`SELECT id, title FROM docs
        ORDER BY embedding <=> ${lit}::vector
        LIMIT 10`,
  );

  return NextResponse.json({ hits: result.rows });
}

import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { docs } from "@/db/schema";
import { embed } from "@/lib/embedder";

export async function POST(req: NextRequest) {
  const payload = await req.json();
  const vec     = await embed(`${payload.title}\n${payload.body}`);

  const [row] = await db.insert(docs).values({
    title:     payload.title,
    body:      payload.body,
    embedding: vec,
  }).returning({ id: docs.id });

  return NextResponse.json({ ok: true, id: row.id.toString() });
}

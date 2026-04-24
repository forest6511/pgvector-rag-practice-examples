/**
 * Ch05: TypeScript / Node.js で OpenAI Embeddings API を呼び出す例。
 *
 * Drizzle ORM や Prisma から pgvector に INSERT する前段の埋め込み生成。
 */
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function embedSmall(texts: string[]): Promise<number[][]> {
  const res = await client.embeddings.create({
    model: "text-embedding-3-small",
    input: texts,
  });
  return res.data.map((d) => d.embedding);
}

export async function embedSmallReduced(
  texts: string[],
  dimensions: number,
): Promise<number[][]> {
  const res = await client.embeddings.create({
    model: "text-embedding-3-small",
    input: texts,
    dimensions,
  });
  return res.data.map((d) => d.embedding);
}

if (require.main === module) {
  (async () => {
    const vecs = await embedSmall([
      "pgvector は PostgreSQL 拡張です",
      "Next.js から呼び出せます",
    ]);
    console.log("default dim:", vecs[0].length);
    const reduced = await embedSmallReduced(["同じ文章"], 768);
    console.log("reduced dim:", reduced[0].length);
  })();
}

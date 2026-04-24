import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const MODEL  = "text-embedding-3-small";

export async function embed(text: string): Promise<number[]> {
  const resp = await client.embeddings.create({ model: MODEL, input: text });
  return resp.data[0].embedding;
}

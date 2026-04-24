import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";

const pool = new Pool({
  connectionString:
    process.env.DATABASE_URL
    ?? "postgresql://rag:ragpass@localhost:5432/ragdb",
});

export const db = drizzle(pool);

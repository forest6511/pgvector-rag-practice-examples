import type { Config } from "drizzle-kit";

export default {
  schema: "./db/schema.ts",
  out:    "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL
      ?? "postgresql://rag:ragpass@localhost:5432/ragdb",
  },
} satisfies Config;

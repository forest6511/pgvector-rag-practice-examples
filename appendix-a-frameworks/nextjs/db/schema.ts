import { pgTable, bigserial, text, timestamp, vector } from "drizzle-orm/pg-core";

export const docs = pgTable("docs", {
  id:        bigserial("id", { mode: "bigint" }).primaryKey(),
  title:     text("title").notNull(),
  body:      text("body").notNull(),
  embedding: vector("embedding", { dimensions: 1536 }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
});

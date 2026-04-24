# Ch05: Ruby(ruby-openai)で OpenAI Embeddings API を呼び出す例。
# Rails から ActiveRecord + neighbor gem で pgvector にインサートする前段。

require "openai"

client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))

def embed_small(client, texts)
  response = client.embeddings(
    parameters: {
      model: "text-embedding-3-small",
      input: texts,
    },
  )
  response.dig("data").map { |d| d["embedding"] }
end

if $PROGRAM_NAME == __FILE__
  sample = ["pgvector は PostgreSQL 拡張です", "Rails から neighbor で検索"]
  vecs = embed_small(client, sample)
  puts "default dim: #{vecs.first.length}"
end

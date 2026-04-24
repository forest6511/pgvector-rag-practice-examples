require "openai"

class Embedder
  MODEL = "text-embedding-3-small"

  def initialize(api_key: ENV.fetch("OPENAI_API_KEY"))
    @client = OpenAI::Client.new(access_token: api_key)
  end

  def embed(text)
    resp = @client.embeddings(parameters: { model: MODEL, input: text })
    resp.dig("data", 0, "embedding")
  end
end

import os
from openai import OpenAI

_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
_MODEL  = "text-embedding-3-small"


def embed(text: str) -> list[float]:
    resp = _client.embeddings.create(model=_MODEL, input=text)
    return resp.data[0].embedding

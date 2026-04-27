import os
from functools import lru_cache

from openai import OpenAI

_MODEL = "text-embedding-3-small"


@lru_cache(maxsize=1)
def _client() -> OpenAI:
    return OpenAI(api_key=os.environ["OPENAI_API_KEY"])


def embed(text: str) -> list[float]:
    resp = _client().embeddings.create(model=_MODEL, input=text)
    return resp.data[0].embedding

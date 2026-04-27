"""クエリと検索結果から OpenAI chat.completions で回答を生成する。"""
from functools import lru_cache

from openai import OpenAI


@lru_cache(maxsize=1)
def _client() -> OpenAI:
    return OpenAI()


CHAT_MODEL = "gpt-4o-mini"


def build_messages(query: str, hits: list[dict]) -> list[dict]:
    context = "\n\n".join(
        f"[{h['id']}] {h['title']}\n{h['body']}" for h in hits[:5]
    )
    return [
        {
            "role": "system",
            "content": (
                "以下の抜粋だけを使って質問に答えてください。"
                "抜粋にない情報は「わかりません」と答えてください。"
                "回答には引用元の [id] を必ず付けてください。"
            ),
        },
        {
            "role": "user",
            "content": f"質問: {query}\n\n抜粋:\n{context}",
        },
    ]


def generate(query: str, hits: list[dict]) -> str:
    resp = _client().chat.completions.create(
        model=CHAT_MODEL,
        messages=build_messages(query, hits),
        temperature=0.2,
    )
    return resp.choices[0].message.content

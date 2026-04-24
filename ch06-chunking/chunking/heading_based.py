"""Ch06: Markdown の見出し構造ベースの分割。

見出しをまたがないことで意味的まとまりを保つ。
見出しパスを section メタデータとして保存するのが定石。
"""

from __future__ import annotations

import re
from dataclasses import dataclass


HEADING_RE = re.compile(r"^(#{1,6})\s+(.+)$", re.MULTILINE)


def split_by_headings(markdown: str) -> list[HeadingChunk]:
    """Markdown 見出し(# ~ ######)で区切り、見出しパスを付与。"""
    positions: list[tuple[int, int, str]] = []
    for match in HEADING_RE.finditer(markdown):
        level = len(match.group(1))
        title = match.group(2).strip()
        positions.append((match.start(), level, title))
    positions.append((len(markdown), 0, ""))

    chunks: list[HeadingChunk] = []
    path_stack: list[tuple[int, str]] = []
    for i, (pos, level, title) in enumerate(positions[:-1]):
        while path_stack and path_stack[-1][0] >= level:
            path_stack.pop()
        path_stack.append((level, title))
        section_path = [t for _, t in path_stack]
        next_pos = positions[i + 1][0]
        content = markdown[pos:next_pos].strip()
        if content:
            chunks.append(HeadingChunk(section_path=section_path, content=content))
    return chunks


@dataclass
class HeadingChunk:
    section_path: list[str]
    content: str


if __name__ == "__main__":
    md = """# pgvector 入門

## インストール

Docker で pgvector を起動します。

## 基本操作

### ベクトル型

vector(1536) で 1536 次元を保持。
"""
    for c in split_by_headings(md):
        print(c.section_path, "->", c.content[:30].replace("\n", " "))

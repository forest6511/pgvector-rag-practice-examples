"""Ch06: HTML からのテキスト抽出(BeautifulSoup + readability-lxml)。

readability でノイズ(ヘッダー・サイドバー・広告)を除去 →
BeautifulSoup で残った本文を整形。
"""

from __future__ import annotations

from bs4 import BeautifulSoup
from readability import Document


def extract_main_text(html: str) -> str:
    """readability で本文抽出 + BeautifulSoup で整形。"""
    doc = Document(html)
    main_html = doc.summary()
    soup = BeautifulSoup(main_html, "html.parser")
    return soup.get_text(separator="\n").strip()


if __name__ == "__main__":
    sample = """<html><body>
    <header>nav</header>
    <article><h1>タイトル</h1><p>本文です。pgvector の解説。</p></article>
    <footer>copyright</footer>
    </body></html>"""
    print(extract_main_text(sample))

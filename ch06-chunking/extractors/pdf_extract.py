"""Ch06: PDF からのテキスト抽出(pdfplumber)。

テーブルは extract_tables() で row-column 構造のまま取れる。
縦書き・複雑 layout は抽出精度が落ちるため、unstructured ライブラリが代替候補。
"""

from __future__ import annotations

import pdfplumber


def extract_text(pdf_path: str) -> list[str]:
    """各ページのテキストを list で返す。空ページはスキップ。"""
    pages_text: list[str] = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                pages_text.append(text)
    return pages_text


def extract_tables(pdf_path: str) -> list[list[list[str]]]:
    """各ページのテーブルを抽出。戻り値は page -> table -> row -> cell。"""
    all_tables: list[list[list[str]]] = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            for table in page.extract_tables():
                all_tables.append(table)
    return all_tables


if __name__ == "__main__":
    import sys
    path = sys.argv[1] if len(sys.argv) > 1 else "sample.pdf"
    pages = extract_text(path)
    print(f"{len(pages)} pages extracted")
    if pages:
        print(f"first page: {pages[0][:200]}...")

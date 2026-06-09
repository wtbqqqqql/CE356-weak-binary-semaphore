from __future__ import annotations

import sys
from pathlib import Path

from pypdf import PdfReader


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: extract_pdf.py <pdf-path> [max-pages]", file=sys.stderr)
        return 1

    pdf_path = Path(sys.argv[1])
    max_pages = int(sys.argv[2]) if len(sys.argv) > 2 else 5

    reader = PdfReader(str(pdf_path))
    print(f"PAGES {len(reader.pages)}")
    for index, page in enumerate(reader.pages[:max_pages], start=1):
        print(f"\n--- PAGE {index} ---\n")
        text = page.extract_text() or ""
        print(text[:4000])

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

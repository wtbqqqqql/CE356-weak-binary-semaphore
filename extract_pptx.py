from __future__ import annotations

import sys
from pathlib import Path
import zipfile
import xml.etree.ElementTree as ET


NS = {
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
}


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: extract_pptx.py <pptx-path>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    with zipfile.ZipFile(path) as zf:
        slide_names = sorted(
            name
            for name in zf.namelist()
            if name.startswith("ppt/slides/slide") and name.endswith(".xml")
        )
        print(f"SLIDES {len(slide_names)}")
        for idx, slide_name in enumerate(slide_names, start=1):
            root = ET.fromstring(zf.read(slide_name))
            texts = [
                "".join(node.itertext()).strip()
                for node in root.findall(".//a:t", NS)
            ]
            texts = [text for text in texts if text]
            print(f"\n--- SLIDE {idx} ---")
            for text in texts:
                print(text[:1000])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

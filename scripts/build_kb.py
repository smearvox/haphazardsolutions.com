#!/usr/bin/env python3
"""
Knowledge-base builder for Haphazard Solutions.

Bursts each PDF in kb/ to text (via poppler's pdftotext), parses the whitepaper
template, and writes _data/kb.json — the data source the Jekyll /knowledge/ page
loops over. Each record's `keywords` holds the paper's full body text, so the
page's client-side filter searches the entire text of every paper (no search
index or build service needed at this scale — revisit with Pagefind if the
corpus grows into the dozens and page weight starts to bite).

Stdlib only, plus the `pdftotext` binary. Run inside the project venv:

    .venv/Scripts/python.exe scripts/build_kb.py        # Windows
    .venv/bin/python scripts/build_kb.py                # POSIX

Re-run and commit _data/kb.json whenever the kb/ corpus changes.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KB_DIR = ROOT / "kb"
DATA_OUT = ROOT / "_data" / "kb.json"
DOC_TYPE = "RESEARCH PAPER"
DOC_TYPE_SLUG = "research"


def extract_text(pdf: Path) -> str:
    result = subprocess.run(
        ["pdftotext", "-enc", "UTF-8", "-q", str(pdf), "-"],
        capture_output=True, text=True, encoding="utf-8",
    )
    return result.stdout or ""


def parse(text: str) -> dict:
    nonempty = [ln.strip() for ln in text.splitlines() if ln.strip()]

    def find(pred, default=None):
        return next((i for i, ln in enumerate(nonempty) if pred(ln)), default)

    hs_idx = find(lambda l: l.lower() == "haphazard solutions", -1)
    email_idx = find(lambda l: l.lower().startswith("e-mail") or "@" in l)
    abs_idx = find(lambda l: l.lower() == "abstract")

    title = ""
    if hs_idx >= 0 and email_idx:
        title = " ".join(nonempty[hs_idx + 1:email_idx - 1]).strip()

    license_line = next(
        (l for l in nonempty if "licensed under" in l.lower() or "cc by" in l.lower()), ""
    )
    year = year_of(license_line)

    abstract = ""
    if abs_idx is not None:
        chunk = []
        for ln in nonempty[abs_idx + 1:]:
            if ln.lower() in ("introduction", "keywords"):
                break
            if len(ln) < 30 and ln.split(" ")[0].rstrip(".").isdigit():
                break
            chunk.append(ln)
            if len(" ".join(chunk)) > 900:
                break
        abstract = " ".join(chunk).strip()

    return {"title": title, "year": year, "abstract": abstract}


def first_sentence(text: str, limit: int = 240) -> str:
    """A one-line summary for the document row."""
    m = re.search(r"(.+?[.!?])(?:\s|$)", text)
    s = (m.group(1) if m else text).strip()
    if len(s) > limit:
        s = s[:limit].rsplit(" ", 1)[0].rstrip(",;:") + "…"
    return s


def human_size(n: int) -> str:
    return f"{n / 1_048_576:.1f} MB" if n >= 1_048_576 else f"{round(n / 1024)} KB"


def collapse(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip().lower()


def year_of(license_line: str) -> str:
    m = re.search(r"(?:19|20)\d{2}", license_line)
    return m.group(0) if m else ""


def main() -> int:
    pdfs = sorted(KB_DIR.glob("*.pdf"))
    if not pdfs:
        print(f"No PDFs found in {KB_DIR}", file=sys.stderr)
        return 1

    records = []
    for i, pdf in enumerate(pdfs, start=1):
        text = extract_text(pdf)
        if not text.strip():
            print(f"[skip] {pdf.name}: no extractable text (scanned?)", file=sys.stderr)
            continue
        meta = parse(text)
        pages = text.count("\x0c") or (text.count("\n\n") // 20 + 1)
        rec = {
            "id": f"HS-KB-{i:03d}",
            "type": DOC_TYPE,
            "type_slug": DOC_TYPE_SLUG,
            "title": meta["title"],
            "abstract": first_sentence(meta["abstract"]),
            "year": meta["year"],
            "pages": pages,
            "size": human_size(pdf.stat().st_size),
            "pdf": pdf.name,
            "keywords": collapse(text),
        }
        records.append(rec)
        print(f"{rec['id']}  {rec['pages']:>3} pp  {rec['size']:>7}  {rec['title']}")

    DATA_OUT.parent.mkdir(parents=True, exist_ok=True)
    DATA_OUT.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
    total_kw = sum(len(r["keywords"]) for r in records)
    print(f"\nWrote {DATA_OUT.relative_to(ROOT)} — {len(records)} docs, "
          f"{total_kw:,} chars of searchable full text.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

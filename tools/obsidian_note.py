"""Crea obsidian/KeepGoing - Versioni.md: un'unica nota con il README di ogni versione.

Fonti:
  - CHANGELOG.md            → data, riassunto e novità di ogni versione ("## vX.Y.Z — AAAA-MM-GG")
  - docs/versions/vX.Y.Z.md → copia del README di quella versione

Uso: python3 tools/obsidian_note.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "obsidian" / "KeepGoing - Versioni.md"
SECTION = re.compile(r"^## (v\d+\.\d+\.\d+) — (\d{4}-\d{2}-\d{2})\s*$", re.MULTILINE)


def read_changelog() -> list[dict]:
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    matches = list(SECTION.finditer(text))
    versions = []
    for i, match in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[match.end():end].strip()
        summary, _, changes = body.partition("\n\n")
        versions.append(
            {"version": match[1], "date": match[2], "summary": summary.strip(), "changes": changes.strip()}
        )
    return sorted(versions, key=lambda v: tuple(int(n) for n in v["version"][1:].split(".")), reverse=True)


def adapt_readme(markdown: str, levels: int) -> str:
    """Abbassa i titoli (# → ###) e toglie i link a file del repository, fuori dai blocchi di codice."""
    out, in_code = [], False
    for line in markdown.splitlines():
        if line.lstrip().startswith("```"):
            in_code = not in_code
        elif not in_code:
            if heading := re.match(r"^(#{1,6}) (.*)", line):
                line = "#" * min(6, len(heading[1]) + levels) + " " + heading[2]
            # In Obsidian i link relativi (es. config.toml) non portano da nessuna parte.
            line = re.sub(r"\[([^\]]+)\]\((?!https?://|#)[^)]+\)", r"\1", line)
        out.append(line)
    return "\n".join(out)


def build_note(versions: list[dict]) -> str:
    latest = versions[0]
    lines = [
        "---",
        "tags: [keepgoing, progetto, readme]",
        "aliases: [KeepGoing versioni, KeepGoing README]",
        f"versione_attuale: {latest['version']}",
        f"aggiornato: {latest['date']}",
        "---",
        "",
        "# KeepGoing — Versioni",
        "",
        "> [!info] Come usare questa nota",
        "> Ogni sezione contiene le novità e il README completo di una versione di KeepGoing,",
        "> l'app che monitora i prezzi dei voli e manda notifiche sull'iPhone. La più recente è in alto.",
        "> Generata da `tools/obsidian_note.py`: non modificarla a mano nel repository.",
        "",
        "| Versione | Data | In breve |",
        "|---|---|---|",
    ]
    for v in versions:
        lines.append(f"| [[#{v['version']}]] | {v['date']} | {v['summary']} |")
    for v in versions:
        readme_path = ROOT / "docs" / "versions" / f"{v['version']}.md"
        lines += ["", "---", "", f"## {v['version']}", "", f"**Data:** {v['date']}  ", f"**In breve:** {v['summary']}", ""]
        if v["changes"]:
            lines += ["### Novità", "", v["changes"], ""]
        if readme_path.is_file():
            readme = readme_path.read_text(encoding="utf-8").strip()
            lines += ["### README", "", adapt_readme(readme, 3), ""]
        else:
            lines += [f"> [!warning] Manca `docs/versions/{v['version']}.md`", ""]
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    versions = read_changelog()
    if not versions:
        raise SystemExit("Nessuna versione trovata in CHANGELOG.md")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(build_note(versions), encoding="utf-8")
    print(f"Scritto {OUTPUT.relative_to(ROOT)} (versioni: {len(versions)})")


if __name__ == "__main__":
    main()

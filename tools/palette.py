#!/usr/bin/env python3
"""The color picker's back end (SUPER+comma → Colors): read and edit tokens.toml.

    palette.py dump              the palette as JSON: swatches, role tables, checks
    palette.py check EDITS       what EDITS would do to the contrast checks (writes nothing)
    palette.py save EDITS        write EDITS into tokens.toml, regenerate (gen.py),
                                 and redeploy the colors (install.sh --colors-only)

`save` also leaves its result in ~/.cache/cozy-archive/palette-saved.json: the
redeploy rewrites Quickshell's Tokens.qml, Quickshell reloads, and the picker
that asked is gone by the time the save finishes. The reloaded picker reads it.

EDITS is JSON: {"swatch": {"gel": "#6A4DA4"},
                "ref":    {"roles.light": {"accent": "pink"}}}
`swatch` repaints a swatch everywhere it's used; `ref` points one role (in
roles, terminal, web, editor or syntax) at another swatch.

tokens.toml stays the one source of truth: an edit rewrites only the value on
its own line, so comments, alignment and order survive, and git shows exactly
what the picker changed. The checks are contrast.py's own rules, so the picker,
`make check` and the pre-commit hook can't disagree.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

import contrast
from tokens import REPO, TOKENS, Tokens, parse

# The role tables the picker may repoint: name → swatch (or "#hex").
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "cozy-archive"
REF_TABLES = ("roles", "terminal", "web", "editor", "syntax")
MODES = ("light", "dark")
HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")
HEADER = re.compile(r"^\s*\[([^\]]+)\]\s*(#.*)?$")
ENTRY = re.compile(r'^(\s*)([A-Za-z_][A-Za-z0-9_]*)(\s*=\s*)"([^"]*)"(.*)$')


def entries(text: str):
    """(section, key, value, comment, line index) for every `key = "value"` line."""
    section = ""
    for i, line in enumerate(text.splitlines()):
        if m := HEADER.match(line):
            section = m.group(1).strip()
        elif m := ENTRY.match(line):
            comment = m.group(5).strip()
            yield section, m.group(2), m.group(4), comment[1:].strip() if comment.startswith("#") else "", i


def apply_edits(text: str, edits: dict) -> str:
    """tokens.toml with EDITS applied, each on its own line, everything else as it was."""
    swatches = edits.get("swatch", {})
    refs = edits.get("ref", {})
    for name, value in swatches.items():
        if not HEX.match(value):
            raise ValueError(f"swatch.{name}: {value!r} isn't #RRGGBB")
    for section in refs:
        if section.split(".")[0] not in REF_TABLES:
            raise ValueError(f"{section}: the picker only repoints {', '.join(REF_TABLES)}")
    lines = text.splitlines(keepends=True)
    seen: set[tuple[str, str]] = set()
    for section, key, _value, _note, i in entries(text):
        new = None
        if section == "swatch" and key in swatches:
            new = swatches[key].upper()
        elif section in refs and key in refs[section]:
            new = refs[section][key]
        if new is None:
            continue
        m = ENTRY.match(lines[i].rstrip("\n"))
        end = "\n" if lines[i].endswith("\n") else ""
        head = f'{m.group(1)}{m.group(2)}{m.group(3)}"{new}"'
        tail = m.group(5)
        if tail.strip().startswith("#"):         # keep the comment in its column
            column = len(lines[i].rstrip("\n")) - len(tail.lstrip())
            tail = " " * max(1, column - len(head)) + tail.lstrip()
        lines[i] = head + tail + end
        seen.add((section, key))
    wanted = {("swatch", k) for k in swatches} | {(s, k) for s, ks in refs.items() for k in ks}
    if missing := wanted - seen:
        raise ValueError("not in tokens.toml: " + ", ".join(f"{s}.{k}" for s, k in sorted(missing)))
    return "".join(lines)


def results(t: Tokens) -> list[dict]:
    out = []
    for title, rules, colors in contrast.sections(t):
        for r in contrast.measure(rules, colors):
            rule = r.rule
            if isinstance(r, contrast.StepResult):
                out.append({
                    "where": title, "kind": "step", "value": round(r.step, 3), "min": rule.minimum,
                    "ok": r.ok, "fg": rule.upper, "bg": rule.lower, "why": rule.why,
                    "fgHex": colors[rule.upper], "bgHex": colors[rule.lower],
                })
            else:
                out.append({
                    "where": title, "kind": "contrast", "value": round(r.ratio, 2), "min": rule.minimum,
                    "ok": r.ok, "fg": rule.fg, "bg": rule.bg, "why": rule.why,
                    "fgHex": r.fg_hex, "bgHex": r.bg_hex,
                })
    return out


def dump(text: str) -> dict:
    t = parse(text)
    swatches, tables, uses = [], {}, {}
    for section, key, value, note, _ in entries(text):
        if section == "swatch":
            swatches.append({"name": key, "hex": value.upper(), "note": note})
            uses.setdefault(key, [])
        elif section.split(".")[0] in REF_TABLES and section.count(".") == 1:
            kind, mode = section.split(".")
            hex_ = getattr(t, kind)[mode][key]
            tables.setdefault(section, []).append({"key": key, "ref": value, "hex": hex_, "note": note})
            if value in uses or not value.startswith("#"):
                uses.setdefault(value, []).append(f"{section}.{key}")
    return {"mode": t.mode, "swatches": swatches, "tables": tables, "uses": uses, "checks": results(t)}


def probe(text: str, edits: dict) -> dict:
    """The same edits, but every target painted a color nothing else uses, so
    any check whose colors move under it is a check that involves the target."""
    def unused(t: Tokens) -> str:
        taken = set(t.swatch.values())
        return next(h for h in (f"#0{i:X}0{i:X}0{i:X}" for i in range(1, 16)) if h not in taken)

    t = parse(text)
    sentinel = unused(t)
    swatch = {k: sentinel for k in edits.get("swatch", {})}
    # A role is probed by giving it the literal sentinel hex (tokens allow "#RRGGBB").
    ref = {sec: {k: sentinel for k in keys} for sec, keys in edits.get("ref", {}).items()}
    return {"swatch": swatch, "ref": ref}


def check(text: str, edits: dict) -> dict:
    """Every check that involves what EDITS touches, before and after, plus any
    check that fails after it. EDITS that change nothing (a swatch set to its
    own color) show what the target is involved in."""
    before = results(parse(text))
    after = results(parse(apply_edits(text, edits)))
    probed = results(parse(apply_edits(text, probe(text, edits))))
    out = []
    for a, b, p in zip(after, before, probed):
        involved = (p["fgHex"], p["bgHex"]) != (b["fgHex"], b["bgHex"])
        changed = (a["fgHex"], a["bgHex"]) != (b["fgHex"], b["bgHex"])
        if involved or changed or not a["ok"]:
            out.append({**a, "was": b["value"], "involved": involved})
    # Failures first, then the tightest margins: what's closest to breaking.
    out.sort(key=lambda r: (r["ok"], r["value"] / r["min"]))
    return {
        "affected": out,
        "failing": sum(not a["ok"] for a in after),
        "total": len(after),
    }


def save(text: str, edits: dict) -> dict:
    new = apply_edits(text, edits)
    parse(new)                                  # never write a file the tools can't read
    TOKENS.write_text(new)
    gen = subprocess.run([sys.executable, str(REPO / "tools" / "gen.py")], capture_output=True, text=True)
    if gen.returncode:
        why = (gen.stderr.strip() or "gen.py failed").splitlines()[-1]
        return {"ok": False, "error": f"Saved in tokens.toml, but gen.py failed: {why}"}
    # Deploy the regenerated colors, keeping the day/night the menu has chosen.
    deploy = subprocess.run(
        [str(REPO / "install.sh"), "--colors-only"],
        capture_output=True, text=True, env={**os.environ, "COZY_KEEP_MODE": "1"},
    )
    if deploy.returncode:
        # tokens.toml and the generated files are already written: say so.
        why = (deploy.stderr.strip() or deploy.stdout.strip() or "install.sh failed").splitlines()[-1]
        return {"ok": False, "error": f"Saved in tokens.toml, but not deployed ({why}). Run ./install.sh --colors-only."}
    summary = check(new, {})
    return {"ok": True, "failing": summary["failing"], "total": summary["total"]}


def main(argv: list[str]) -> int:
    text = TOKENS.read_text()
    try:
        if argv[:1] == ["dump"]:
            out = dump(text)
        elif argv[:1] in (["check"], ["save"]) and len(argv) == 2:
            edits = json.loads(argv[1])
            out = check(text, edits) if argv[0] == "check" else save(text, edits)
        else:
            print(__doc__, file=sys.stderr)
            return 2
    except (ValueError, KeyError) as e:          # bad edits, or tokens that don't parse
        out = {"ok": False, "error": ("Not saved: " if argv[:1] == ["save"] else "") + str(e)}
    print(json.dumps(out))
    if argv[:1] == ["save"]:
        CACHE.mkdir(parents=True, exist_ok=True)
        tmp = CACHE / "palette-saved.json.tmp"
        tmp.write_text(json.dumps({**out, "at": int(time.time()), "edits": argv[1]}) + "\n")
        tmp.replace(CACHE / "palette-saved.json")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

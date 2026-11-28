"""yazi (the file browser on SUPER+E): a theme and a code-preview tmTheme per mode.

Everything is built from the [editor] and [syntax] roles, and only from pairs
contrast.py already checks there: text, textMuted and textFaint on background,
textMuted on surface, text on selection, onAccentSolid on accentSolid, and every
syntax color on background. kitty's background is the editor's (parchment /
umber), so "on background" holds inside the terminal too.

The look is text first: no icon font. Each entry gets a one-character marker
(`/` a directory, `@` a link, `*` an executable, `!` a broken link), the
status bar's separators are plain spaces, and borders are box-drawing lines.
"""

from __future__ import annotations

from xml.sax.saxutils import escape

from tokens import Tokens

HEADER = "GENERATED from tokens.toml by tools/gen.py — edit tokens.toml, then run `make`."


def _value(v: object) -> str:
    return "true" if v is True else "false" if v is False else '"' + str(v) + '"'


def _style(**kw: object) -> str:
    """A TOML inline table. A trailing underscore escapes a Python keyword (is_, if_)."""
    return "{ " + ", ".join(f"{k.rstrip('_')} = {_value(v)}" for k, v in kw.items()) + " }" if kw else "{}"


def theme(t: Tokens, mode: str) -> str:
    e, s = t.editor[mode], t.syntax[mode]
    solid = _style(fg=e["onAccentSolid"], bg=e["accentSolid"], bold=True)
    quiet = _style(fg=e["textMuted"], bg=e["surface"])
    border = _style(fg=e["border"])
    title = _style(fg=e["text"], bold=True)
    hover = _style(fg=e["text"], bg=e["selection"])

    def marker(color: str) -> str:
        return _style(fg=color, bg=color)

    sections = {
        "mgr": {
            "cwd": _style(fg=s["keyword"], bold=True),
            "find_keyword": _style(fg=s["number"], bold=True, underline=True),
            "find_position": _style(fg=s["keyword"], bold=True),
            "symlink_target": _style(fg=e["textFaint"], italic=True),
            "marker_copied": marker(e["success"]),
            "marker_cut": marker(e["error"]),
            "marker_marked": marker(e["info"]),
            "marker_selected": marker(e["accentSolid"]),
            "count_copied": solid,
            "count_cut": solid,
            "count_selected": solid,
            "border_symbol": '"│"',
            "border_style": border,
            "syntect_theme": f'"~/.config/yazi/syntax-{mode}.tmTheme"',
        },
        "tabs": {
            "active": solid,
            "inactive": quiet,
            "sep_inner": '{ open = "[", close = "]" }',
            "sep_outer": '{ open = "", close = "" }',
        },
        # The mode tag says NOR / SEL / UNS itself, so one plate does for all three.
        "mode": {
            "normal_main": solid, "normal_alt": quiet,
            "select_main": solid, "select_alt": quiet,
            "unset_main": solid, "unset_alt": quiet,
        },
        "indicator": {
            "parent": hover,
            "current": hover,
            "preview": _style(underline=True),
            "padding": '{ open = " ", close = " " }',
        },
        "status": {
            "overall": _style(fg=e["textMuted"]),
            "sep_left": '{ open = "", close = " " }',
            "sep_right": '{ open = " ", close = "" }',
            "perm_type": _style(fg=s["keyword"]),
            "perm_read": _style(fg=s["string"]),
            "perm_write": _style(fg=s["number"]),
            "perm_exec": _style(fg=s["tag"]),
            "perm_sep": _style(fg=e["textFaint"]),
            "progress_label": _style(fg=e["text"], bold=True),
            "progress_normal": _style(fg=e["accentSolid"], bg=e["surface"]),
            "progress_error": _style(fg=e["error"], bg=e["surface"]),
        },
        "which": {
            "cols": "3",
            "mask": _style(bg=e["surface"]),
            "cand": _style(fg=s["keyword"], bold=True),
            "rest": _style(fg=e["textMuted"]),
            "desc": _style(fg=e["text"]),
            "separator": '" → "',
            "separator_style": _style(fg=e["textMuted"]),
        },
        "confirm": {
            "border": border, "title": title, "body": _style(fg=e["text"]), "list": _style(fg=e["text"]),
            "btn_yes": solid, "btn_no": quiet,
            "btn_labels": '[ " [Y]es ", " (N)o " ]',
        },
        "spot": {"border": border, "title": title, "tbl_col": _style(fg=s["keyword"]), "tbl_cell": _style(fg=e["text"])},
        "notify": {
            "title_info": _style(fg=e["info"], bold=True),
            "title_warn": _style(fg=e["warning"], bold=True),
            "title_error": _style(fg=e["error"], bold=True),
        },
        "pick": {"border": border, "active": solid, "inactive": _style(fg=e["text"])},
        "input": {"border": border, "title": title, "value": _style(fg=e["text"]), "selected": hover},
        "cmp": {
            "border": border, "active": solid, "inactive": _style(fg=e["text"]),
            "icon_file": '"  "', "icon_folder": '"/ "', "icon_command": '"> "',
        },
        "tasks": {"border": border, "title": title, "hovered": hover},
        "help": {"border": border, "chord": _style(fg=s["keyword"], bold=True),
                 "action": _style(fg=e["text"]), "hovered": hover},
    }

    # Names, colored by what they are. First match wins.
    rules = [
        _style(url="*", is_="orphan", fg=e["error"], crossed=True),
        _style(url="*", is_="link", fg=s["function"], italic=True),
        _style(url="*/", fg=s["keyword"], bold=True),
        _style(url="*", is_="exec", fg=s["string"]),
        _style(mime="image/*", fg=s["type"]),
        _style(mime="{audio,video}/*", fg=s["tag"]),
        _style(mime="application/{zip,gzip,x-tar,x-bzip*,x-7z-compressed,x-xz,zstd,x-rar}", fg=s["number"]),
        _style(mime="application/{pdf,epub+zip,msword,vnd.*}", fg=s["property"]),
        _style(url="*", fg=e["text"]),
    ]

    # Plain text markers instead of an icon font. These lists replace yazi's
    # presets outright; conds are tried last, in order.
    conds = [
        _style(if_="orphan", text="!", fg=e["error"]),
        _style(if_="link", text="@", fg=s["function"]),
        _style(if_="dir", text="/", fg=s["keyword"]),
        _style(if_="exec", text="*", fg=s["string"]),
        _style(if_="!dir", text=" "),
    ]

    out = [
        f"# {HEADER}",
        f"# yazi theme, editor.{mode} + syntax.{mode}. ~/.config/yazi/theme.toml is a",
        "# link to this file or its other-mode twin (apply.py switches it).",
        "",
    ]
    for name, keys in sections.items():
        out.append(f"[{name}]")
        width = max(map(len, keys))
        out += [f"{k.ljust(width)} = {v}" for k, v in keys.items()]
        out.append("")
    out += ["[filetype]", "rules = [", *(f"    {r}," for r in rules), "]", ""]
    out += ["[icon]", "globs = []", "dirs  = []", "files = []", "exts  = []",
            "conds = [", *(f"    {c}," for c in conds), "]", ""]
    return "\n".join(out)


def tmtheme(t: Tokens, mode: str) -> str:
    """The code previewer's colors (syntect reads TextMate themes)."""
    e, s = t.editor[mode], t.syntax[mode]
    scopes = [
        ("Comment", "comment, punctuation.definition.comment", s["comment"], "italic"),
        ("Keyword", "keyword, storage, keyword.control", s["keyword"], ""),
        ("String", "string, punctuation.definition.string", s["string"], ""),
        ("Number", "constant.numeric", s["number"], ""),
        ("Constant", "constant, constant.language, support.constant", s["constant"], ""),
        ("Function", "entity.name.function, support.function, meta.function-call", s["function"], ""),
        ("Type", "entity.name.type, storage.type, support.type, entity.name.class, support.class", s["type"], ""),
        ("Tag", "entity.name.tag, markup.heading", s["tag"], ""),
        ("Attribute", "entity.other.attribute-name", s["attribute"], ""),
        ("Property", "variable.other.member, variable.other.property, support.variable.property, meta.object-literal.key", s["property"], ""),
        ("Variable", "variable, variable.parameter", s["variable"], ""),
        ("Operator", "keyword.operator", s["operator"], ""),
        ("Punctuation", "punctuation", s["punctuation"], ""),
        ("Invalid", "invalid", e["error"], ""),
    ]

    def entry(name: str, scope: str, fg: str, style: str) -> str:
        font = f"\n\t\t\t\t<key>fontStyle</key>\n\t\t\t\t<string>{style}</string>" if style else ""
        return (
            f"\t\t<dict>\n\t\t\t<key>name</key>\n\t\t\t<string>{name}</string>\n"
            f"\t\t\t<key>scope</key>\n\t\t\t<string>{escape(scope)}</string>\n"
            f"\t\t\t<key>settings</key>\n\t\t\t<dict>\n\t\t\t\t<key>foreground</key>\n"
            f"\t\t\t\t<string>{fg}</string>{font}\n\t\t\t</dict>\n\t\t</dict>\n"
        )

    globals_ = {
        "background": e["background"], "foreground": e["text"], "caret": e["cursor"],
        "selection": e["selection"], "lineHighlight": e["lineHighlight"],
    }
    g = "".join(f"\t\t\t\t<key>{k}</key>\n\t\t\t\t<string>{v}</string>\n" for k, v in globals_.items())
    name = "Cozy Archive " + ("Day" if mode == "light" else "Night")
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        f"<!-- {HEADER} -->\n"
        '<plist version="1.0">\n<dict>\n'
        f"\t<key>name</key>\n\t<string>{name}</string>\n"
        "\t<key>settings</key>\n\t<array>\n"
        f"\t\t<dict>\n\t\t\t<key>settings</key>\n\t\t\t<dict>\n{g}\t\t\t</dict>\n\t\t</dict>\n"
        + "".join(entry(*row) for row in scopes)
        + "\t</array>\n</dict>\n</plist>\n"
    )

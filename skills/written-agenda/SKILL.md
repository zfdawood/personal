---
name: written-agenda
description: >
  Draft a written agenda for one of Z. Dawood's meetings, in his voice and his personal brand, from
  whatever the meeting covers: a doc, a demo, a repo, a card, a past call. Builds an HTML page with
  five to eight one-line items he can screen-share, each folding out into the detail behind it.
  Triggers on "agenda for <meeting>", "draft agendas for today", "/written-agenda", "what should
  I put up for the <x> meeting". NOT the factory's client-call priorities recap
  (/factory-kit:agenda), and NOT post-call notes.
---

# Written agenda

He puts a written agenda up at the start of a meeting so people can follow on the page as
well as by ear. The page has two layers:

- **The list**: 5 to 8 one-line items, all collapsed when the page opens. This is what's on screen
  and what he points at ("item 3"). It must fit on one screen.
- **The fold-outs**: under each item, the detail he'd otherwise say out loud or look up mid-call.
  Facts, figures, tables, the exact open questions, where things live. Someone who missed the
  meeting should be able to expand everything and follow it.

## 1. Pin down the meeting

For each meeting you need three things. Ask only for what you can't find yourself:

- **What it covers**: a doc link, a repo/path, a demo, a card, or "the weekly <x> call".
- **Who's in the room**: internal only, or a client too? This decides what's safe to put on the page.
- **His role**: presenting, running it, or attending. An agenda for a meeting he only attends is
  usually just two or three things he wants to raise.

Several meetings in one ask: build each one separately, and gather each one's material in parallel.

## 2. Read the material, not a summary of it

- **A Claude Doc** (claude.ai/artifact link): load the docs skill, then read the whole tab.
  Long docs come back as a file. Strip the markup and read all of it. The agenda follows the
  doc's own sections, and a "questions to settle" or "decisions" section becomes the closing items.
- **A demo of code**: the README, `git log` for the area since the last time it was shown, and
  the routes/screens list. Look for open questions the code or prototypes already list (side
  panels, TODO tables, "questions for <client>"). Those are the best agenda items. Code in the
  other WSL distro: `wsl.exe -d Ubuntu --cd <path> -- bash -lc '...'`. Run it from `/mnt/c` so the
  current directory resolves, and copy files over with `tar` before parsing them locally.
- **A recurring meeting**: the last one or two Fireflies transcripts of that meeting (the full text,
  not the summary) for anything promised or left open, plus the project's Slack channel since then.
  Drop anything already resolved there. Something the client said is fine for now is NOT open.
- **A client call on a factory project**: /factory-kit:agenda's sources are a good checklist (board,
  discovery channel, transcripts), but open the cards themselves. It only reads titles.
- Check Slack for context on the meeting itself ("I'll present this Monday", who's coming).

## 3. Write it

Read `~/.claude/projects/-home-zfdawood-work-chr-eyeonit/memory/dawood-writing-style.md` first.

**The one-liners** (the `summary` of each item) are in his voice:
- `<topic> - <the point or the question>`. The topic is a few lowercase words he says out loud.
  The rest is what people read. Questions end in `?`.
- Lowercase, plain words, spaced hyphen ( - ), never an em dash. "I'd like to settle X" is his
  phrasing for a goal.
- Lead with what's being shown or covered, and end with decisions/questions and then
  `next steps`. Group several open questions by area into one item.
- At most one number per line, rounded, and only when it carries the point.

**The fold-outs** are plain and specific: short sentences, real figures, names, file paths. Use
- a short paragraph or a few bullets,
- a ledger table when items are compared on the same columns,
- `class="ask"` on a question that needs an answer in the room (purple),
- `class="said"` for a quote (purple italic), `class="hl"` for the one result that matters,
- `<h4>` to split a long fold-out, and `<p class="from">` for where it came from (a path or source).
No em dashes here either.

**Presentation aids live in the agenda** (he asked, 11/16): anything you'd otherwise switch
tabs to show goes in that item's fold-out, so the agenda is the only thing on screen.
`aids.py` (next to this file) returns HTML to paste into a fold-out:
- `aids.flow(steps, caption, base=…)`: boxes left to right, for a process or how something moves.
  A `base` bar runs under every step.
- `aids.bar(segments, caption)`: one stacked bar, for parts of a whole (e.g. 40 / 50 / 20 of 111 builds).
- `aids.screenshot(png, alt, caption)`: an embedded image. For a demo, screenshot the thing being
  shown: headless Firefox works (`firefox.exe --headless --no-remote --profile <tmp> --window-size=W,H
  --screenshot <out.png> <file:// or http:// url>`).
Diagrams use only the page's CSS variables, so they follow dark mode. Take the steps, stages and
numbers from the material (the prototype's own stages, the doc's own figures), never invented ones.
Look at the screenshot before captioning it, and caption what it actually shows.
Another agent may be adding aids to an agenda. If he says so, don't re-render that one.

 nothing internal on the page, folded or not (costs, staffing, internal
opinions from Slack, other clients). Frame open items as questions to them, never as what they owe.

## 4. Build the page in his brand

Agendas are the **business variant**: "it should be all business" (11/16). They keep the palette,
mono headings, cut corners and the hard shadow, and drop the decoration: no desk wallpaper, no
day/night switch, no paper grain, margin rule or bevel, and no handwriting (the date is plain text
and item numbers are mono, in purple). `template.html` does all of this. Don't add any of it back
per agenda, and don't carry these cuts into the brand itself or the site.

The look is the `personal-brand` skill; its stylesheet is generated into `~/work/personal/web/brand.css`
(this skill lives in that repo too, under `skills/`, linked into `~/.claude/skills`). Don't restyle
it per agenda, and fix the look there, not here. This skill adds only the agenda layout:
- `template.html`: a full HTML document. It inlines `brand.css` without the desk wallpaper, draws
  the bevel, adds the agenda list styles, and has the Expand all script. No `theme.js`: agendas
  have no wallpaper and no day/night switch (he asked, 11/16). They follow the system's mode.
- `render.py`: wraps a body file in the template.

1. Write the body to `~/agendas/src/<YYYY-MM-DD>-<slug>.html`. Copy the structure of an existing
   one there: two comment lines (`title:`, `footer:`), then the header strip (`.readout`:
   `agenda / <kind: demo, all-hands, sync…> / <YYYY-MM-DD> / <b>N items</b>`, no day/night
   switch), `h1` (the meeting name, lowercase), byline (`<span class="when">Mon 11/16</span>`, the
   name Z. Dawood, a link to the material), lede (one sentence on what the meeting should leave
   with), the bar (just `button.chip.toggle-all`), and `ol.agenda` of `details`. No kicker: the
   strip already says what it is.
2. `python3 -I ~/.claude/skills/written-agenda/render.py <body> ~/agendas/<same name>.html`
3. Copy it to `/mnt/c/Users/dawoo/Downloads/` so he can open it in his Windows browser.

They're local HTML files for viewing and throwing away, NOT published artifacts or Claude Docs.
Publish one only if he asks.

The `title` comment is the page's name: the meeting's name in title case ("Fresh by SpinXpress
Demo"), not "Agenda: ...".

## 5. Deliver

- Give each file as a clickable link he can open in Firefox, as a markdown link to the file URL:
  `[<Page name>](file:///C:/Users/dawoo/Downloads/<name>.html)`. Then add a line on what it was built
  from. If he asks you to open them, run
  `"/mnt/c/Program Files/Mozilla Firefox/firefox.exe" 'C:\Users\dawoo\Downloads\<name>.html'`.
- List anything you assumed (who's attending, what's in scope) as one short line per assumption.
- Don't post, send or schedule anything. If he asks you to post the link somewhere, show the message
  first.

## Feedback log

He is tuning this skill. When he corrects a draft or the look, add the correction here as one
dated line, then fold it into the rules above once it's clearly a pattern. Brand corrections go into
`template.html` directly, and get a line here too.

- 2026-11-16: first version, as plain text in chat. Drafts for the DevHawk Directions all-hands and
  the Fresh by SpinXpress demo.
- 2026-11-16: switched to HTML pages in his personal brand (cozy-archive + the wins handout), with
  much more detail in collapsible fold-outs. Keep the factory /agenda skill separate.
- 2026-11-16: local HTML files in Downloads, not artifacts ("meant purely for viewing and more
  disposable"). Wider page, mono item topics, purple/pink accents. The brand split out into
  the `personal-brand` skill.
- 2026-11-16: agendas get neither the desk wallpaper nor the day/night script. Plain desk color,
  system dark mode only.
- 2026-11-16: the look was "slightly too much for the agenda, which really should be all business".
  Business variant: no grain, margin rule, bevel or script font (date plain, numbers mono). The header
  strip replaces the kicker and the bar's count. Agenda only, not the brand.
- 2026-11-16: diagrams and other presentation aids live in the agenda's fold-outs (aids.py).

.PHONY: gen check preview hooks install colors fonts greeter site skills zed vscode

# Regenerate every app's colors from tokens.toml.
gen:
	@python3 tools/gen.py

# Generated files match tokens.toml, and every text color passes WCAG contrast.
check:
	@python3 tools/gen.py --check
	@python3 tools/contrast.py
	@# QML reads `property … onFoo` as a signal handler and the property comes back
	@# empty (Theme.onAccentSolid drew black text). Keep "on" off property names.
	@! grep -rnE 'property +[A-Za-z<>]+ +on[A-Z]' configs/quickshell || { echo "QML property named on<Capital> (see above): rename it" >&2; exit 1; }

# Truecolor samples of both terminal palettes, each on its own background.
preview:
	@python3 tools/contrast.py --preview

# Use the versioned hooks in .githooks/ (pre-commit runs `make check`).
hooks:
	@git config core.hooksPath .githooks
	@echo "git hooks enabled: .githooks/"

# Full install: every config dir (existing ones are backed up first), plus the
# editor themes for whichever editors are installed (Arch's Zed is `zeditor`).
install: gen
	@./install.sh
	@if command -v zed >/dev/null 2>&1 || command -v zeditor >/dev/null 2>&1; then $(MAKE) --no-print-directory zed; fi
	@if command -v code >/dev/null 2>&1; then $(MAKE) --no-print-directory vscode; fi

# Fetch the brand's fonts (tokens.toml [type]) into ~/.local/share/fonts.
fonts:
	@./install.sh --fonts

# The boot greeter: the lock screen's login card, shown by greetd (needs sudo;
# see install.sh --greeter). Re-run after changing tokens or the cards.
greeter: gen
	@./install.sh --greeter

# Regenerate and redeploy only the generated color files, then reload running
# apps (and repaint the wallpaper) — the quick path after editing a color in
# tokens.toml. Day/night itself is switched from the settings menu, SUPER+comma.
colors: gen
	@./install.sh --colors-only

# ── The brand outside the desktop ──────────────────────────────────────────
# web/ is generated with everything else by `make` and read in place: the site
# (site/) builds from it and the skills (skills/) point at it, so nothing is
# copied. The editor themes are copied into each editor (`make install` does
# this for the editors it finds; `make zed` / `make vscode` do one). Override a
# path on the command line, e.g.
# `make zed ZED_THEMES=/mnt/c/Users/me/AppData/Roaming/Zed/themes`.
ZED_THEMES  ?= $(HOME)/.config/zed/themes
VSCODE_EXT  ?= $(HOME)/.vscode/extensions/zdawood.cozy-archive-theme-0.1.0
SKILLS      ?= $(HOME)/.claude/skills

# Build zdawood.dev into site/dist and serve it at http://localhost:8000.
site: gen
	@cd site && { test -d node_modules || npm ci; } && npm start

# Link the Claude Code skills (personal-brand, written-agenda) into ~/.claude/skills.
skills:
	@mkdir -p $(SKILLS)
	@for s in skills/*/; do s=$${s%/}; n=$${s#skills/}; \
		if test -e $(SKILLS)/$$n && ! test -L $(SKILLS)/$$n; then echo "$(SKILLS)/$$n exists and isn't a link, skipped"; \
		else ln -sfn "$(CURDIR)/$$s" $(SKILLS)/$$n && echo "skill: $(SKILLS)/$$n -> $$s"; fi; done

zed: gen
	@mkdir -p $(ZED_THEMES)
	@cp editors/zed/cozy-archive.json $(ZED_THEMES)/
	@echo "Zed: $(ZED_THEMES)/cozy-archive.json (theme selector: Cozy Archive Day / Night)"

vscode: gen
	@mkdir -p $(VSCODE_EXT)
	@cp -r editors/vscode/. $(VSCODE_EXT)/
	@echo "VS Code: $(VSCODE_EXT) (reload, then Preferences: Color Theme)"

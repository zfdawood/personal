.PHONY: gen check preview hooks install colors site skills zed vscode

# Regenerate every app's colors from tokens.toml.
gen:
	@python3 tools/gen.py

# Generated files match tokens.toml, and every text color passes WCAG contrast.
check:
	@python3 tools/gen.py --check
	@python3 tools/contrast.py

# Truecolor samples of both terminal palettes, each on its own background.
preview:
	@python3 tools/contrast.py --preview

# Use the versioned hooks in .githooks/ (pre-commit runs `make check`).
hooks:
	@git config core.hooksPath .githooks
	@echo "git hooks enabled: .githooks/"

# Full install: every config dir (existing ones are backed up first).
install: gen
	@./install.sh

# Regenerate and redeploy only the generated color files, then reload running
# apps (and repaint the wallpaper) — the quick path after editing a color in
# tokens.toml. Day/night itself is switched from the settings menu, SUPER+comma.
colors: gen
	@./install.sh --colors-only

# ── The brand outside the desktop ──────────────────────────────────────────
# web/ is generated with everything else by `make` and read in place: the site
# (site/) builds from it and the skills (skills/) point at it, so nothing is
# copied. The editor themes do need installing into each editor. Override a
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

.PHONY: gen check preview hooks install colors export zed vscode

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
# web/ and editors/ are generated with everything else by `make`. These copy
# them to where they're used. Override a path on the command line, e.g.
# `make zed ZED_THEMES=/mnt/c/Users/me/AppData/Roaming/Zed/themes`.
BRAND_SKILL ?= $(HOME)/.claude/skills/personal-brand
SITE        ?= $(HOME)/work/site
ZED_THEMES  ?= $(HOME)/.config/zed/themes
VSCODE_EXT  ?= $(HOME)/.vscode/extensions/zdawood.cozy-archive-theme-0.1.0

# The brand skill (agendas and other pages) and the zdawood.dev site.
export: gen
	@test -d $(BRAND_SKILL) || { echo "no brand skill at $(BRAND_SKILL)"; exit 1; }
	@mkdir -p $(BRAND_SKILL)/glyphs
	@cp web/brand.css web/theme.js $(BRAND_SKILL)/
	@cp web/glyphs/leaf.svg $(BRAND_SKILL)/glyphs/
	@echo "brand skill: $(BRAND_SKILL)"
	@if test -d $(SITE); then \
		cp web/brand.css web/theme.js $(SITE)/public/ && cp web/Brand.elm $(SITE)/src/ && echo "site: $(SITE)"; \
	else echo "no site at $(SITE), skipped"; fi

zed: gen
	@mkdir -p $(ZED_THEMES)
	@cp editors/zed/cozy-archive.json $(ZED_THEMES)/
	@echo "Zed: $(ZED_THEMES)/cozy-archive.json (theme selector: Cozy Archive Day / Night)"

vscode: gen
	@mkdir -p $(VSCODE_EXT)
	@cp -r editors/vscode/. $(VSCODE_EXT)/
	@echo "VS Code: $(VSCODE_EXT) (reload, then Preferences: Color Theme)"

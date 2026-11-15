.PHONY: gen check preview hooks install colors

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

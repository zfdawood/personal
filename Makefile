.PHONY: gen check preview hooks install

# Regenerate every app's colors from tokens.toml.
gen:
	@python3 tools/gen.py

# Generated files match tokens.toml, and every text color passes WCAG contrast.
check:
	@python3 tools/gen.py --check
	@python3 tools/contrast.py

# Truecolor sample of the terminal palette, rendered on its own background.
preview:
	@python3 tools/contrast.py --preview

# Use the versioned hooks in .githooks/ (pre-commit runs `make check`).
hooks:
	@git config core.hooksPath .githooks
	@echo "git hooks enabled: .githooks/"

install: gen
	@./install.sh

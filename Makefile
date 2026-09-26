.PHONY: check preview hooks install

# WCAG contrast check on the terminal palette (exit 1 on failure).
check:
	@python3 tools/contrast.py

# Truecolor sample of the kitty palette, rendered on its own background.
preview:
	@python3 tools/contrast.py --preview

# Use the versioned hooks in .githooks/ (pre-commit runs `make check`).
hooks:
	@git config core.hooksPath .githooks
	@echo "git hooks enabled: .githooks/"

install:
	@./install.sh

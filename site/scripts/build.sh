#!/usr/bin/env bash
# Build dist/: compile Elm, then copy public/ and the brand's generated web files alongside it.
#
# The brand (brand.css, theme.js, Brand.elm) is not copied into site/: it's read from ../web,
# which `make` in the repo root generates from tokens.toml. Cloudflare clones the whole repo and
# runs this from site/, so ../web is there too.
#
# Elm compiles in a temporary copy of the project, not in the repo. On Cloudflare's build
# machines the compiler failed on its own cache in the repo checkout ("elm-stuff/0.19.1/d.dat:
# openBinaryFile: resource busy (file is locked)") while the same build passed locally, so the
# repo's mount is the suspect. A fresh directory outside it gives elm-stuff a filesystem whose
# file locks behave. The copy keeps the site/ and web/ layout so elm.json's "../web" resolves.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
web="$root/../web"
elm="$root/node_modules/.bin/elm"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/site" "$work/web"
cp -r "$root/elm.json" "$root/src" "$work/site/"
cp "$web/Brand.elm" "$work/web/"
rm -rf "$root/dist"
mkdir -p "$root/dist"
(cd "$work/site" && "$elm" make src/Main.elm --optimize --output="$root/dist/elm.js")
cp -r "$root/public/." "$root/dist/"
cp "$web/brand.css" "$web/theme.js" "$root/dist/"

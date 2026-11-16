#!/usr/bin/env bash
# Build dist/: compile Elm, then copy public/ alongside it.
#
# Elm compiles in a temporary copy of the project, not in the repo. On Cloudflare's build
# machines the compiler failed on its own cache in the repo checkout ("elm-stuff/0.19.1/d.dat:
# openBinaryFile: resource busy (file is locked)") while the same build passed locally, so the
# repo's mount is the suspect. A fresh directory outside it gives elm-stuff a filesystem whose
# file locks behave.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
elm="$root/node_modules/.bin/elm"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp -r "$root/elm.json" "$root/src" "$work/"
rm -rf "$root/dist"
mkdir -p "$root/dist"
(cd "$work" && "$elm" make src/Main.elm --optimize --output="$root/dist/elm.js")
cp -r "$root/public/." "$root/dist/"

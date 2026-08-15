#!/usr/bin/env bash
# Builds the release zip for a GitHub release.
#
# The folder inside the zip is always the addon name (matching the .toc),
# never <addon>-<version> — that's what git's own tag archives do and what
# breaks WoW addon detection on update. Version only appears in the zip's
# *filename*, via git archive --prefix.
set -euo pipefail

cd "$(dirname "$0")"

toc_file="$(find . -maxdepth 1 -name '*.toc' -print -quit)"
if [ -z "$toc_file" ]; then
	echo "No .toc file found in repo root." >&2
	exit 1
fi
addon_name="$(basename "$toc_file" .toc)"

ref="${1:-HEAD}"
version="$(git show "$ref:$toc_file" | grep -m1 '^## Version:' | sed 's/^## Version:[[:space:]]*//')"
if [ -z "$version" ]; then
	echo "Couldn't read ## Version from $toc_file at $ref." >&2
	exit 1
fi

out="${addon_name}-${version}.zip"
git archive --format=zip --worktree-attributes --prefix="${addon_name}/" -o "$out" "$ref"

echo "Wrote $out"
unzip -l "$out" | head -5 || true

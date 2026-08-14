#!/usr/bin/env bash
# Updates vendored Libs/ from their upstream sources.
#
# Only re-fetches files that already exist locally, so new files added
# upstream (or local-only additions) are left alone. LibSimpleFrame-Mod-1.0
# is a hand-patched fork with no upstream fix available and is never touched.
set -euo pipefail

cd "$(dirname "$0")"

# path|upstream_raw_base
# path may be a directory (every file under it is synced) or a single file.
SOURCES=(
	"Libs/LibStub|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/LibStub"
	"Libs/CallbackHandler-1.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/CallbackHandler-1.0"
	"Libs/AceAddon-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceAddon-3.0"
	"Libs/AceBucket-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceBucket-3.0"
	"Libs/AceComm-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceComm-3.0"
	"Libs/AceConfig-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceConfig-3.0"
	"Libs/AceConsole-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceConsole-3.0"
	"Libs/AceDB-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceDB-3.0"
	"Libs/AceDBOptions-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceDBOptions-3.0"
	"Libs/AceEvent-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceEvent-3.0"
	"Libs/AceGUI-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceGUI-3.0"
	"Libs/AceHook-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceHook-3.0"
	"Libs/AceLocale-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceLocale-3.0"
	"Libs/AceSerializer-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceSerializer-3.0"
	"Libs/AceTab-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceTab-3.0"
	"Libs/AceTimer-3.0|https://raw.githubusercontent.com/WoWUIDev/Ace3/master/AceTimer-3.0"
	"Libs/LibDataBroker-1.1|https://raw.githubusercontent.com/tekkub/libdatabroker-1-1/master"
	"Libs/LibDBIcon-1.0|https://raw.githubusercontent.com/wowace-clone/LibDBIcon-1.0/main/LibDBIcon-1.0"
	# Only the files HereBeDragons' own repo actually contains; the vendored
	# LibStub/CallbackHandler-1.0 subfolders under Libs/HereBeDragons are
	# leftovers from an old external-libs fetch, not part of that repo, and
	# CHANGELOG.md isn't published there either, so none of those are synced.
	"Libs/HereBeDragons/HereBeDragons-2.0.lua|https://raw.githubusercontent.com/Nevcairiel/HereBeDragons/master/HereBeDragons-2.0.lua"
	"Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua|https://raw.githubusercontent.com/Nevcairiel/HereBeDragons/master/HereBeDragons-Pins-2.0.lua"
	"Libs/HereBeDragons/HereBeDragons-Migrate.lua|https://raw.githubusercontent.com/Nevcairiel/HereBeDragons/master/HereBeDragons-Migrate.lua"
	"Libs/HereBeDragons/HereBeDragons.toc|https://raw.githubusercontent.com/Nevcairiel/HereBeDragons/master/HereBeDragons.toc"
)

changed=0
failed=0

sync_one() {
	local file="$1" url="$2" tmp
	tmp="$(mktemp)"

	if ! curl -sf --max-time 15 -o "$tmp" "$url"; then
		echo "FAILED  $file  (couldn't fetch $url)" >&2
		failed=$((failed + 1))
		rm -f "$tmp"
		return
	fi

	if cmp -s "$tmp" "$file"; then
		rm -f "$tmp"
	else
		mv "$tmp" "$file"
		echo "UPDATED $file"
		changed=$((changed + 1))
	fi
}

for entry in "${SOURCES[@]}"; do
	path="${entry%%|*}"
	url_part="${entry#*|}"

	if [ -d "$path" ]; then
		while IFS= read -r -d '' file; do
			rel="${file#"$path"/}"
			sync_one "$file" "$url_part/$rel"
		done < <(find "$path" -type f -print0)
	else
		sync_one "$path" "$url_part"
	fi
done

echo
echo "$changed file(s) updated, $failed fetch failure(s)."
if [ "$changed" -gt 0 ]; then
	echo "Review with: git diff -- Libs"
fi

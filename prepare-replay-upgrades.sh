#!/bin/bash

# The plugin versions this deploy replaces, read from the previous build commit, for the
# post-push replay (handle-replay-upgrades.sh): its baseline where the site has no record
# yet, as on its first run. Written as base64 JSON of plugin folder => {from, to}: the Version
# header before and after, so the site only trusts it where it runs "to" (rsync may skip a folder).
# Only when this build was committed: otherwise HEAD~1 is an earlier deploy's build.

rm -f "${RUNNER_TEMP}/replay-previous"
if [ ! -s "$MANIFEST_RAW" ] || ! git -C "$BUILT" rev-parse -q --verify HEAD~1 >/dev/null; then
    exit 0
fi

# A plugin main file's Version header at a commit, as WordPress reads it (first 8 KB).
version_at() {
    git -C "$BUILT" show "$1:$2" 2>/dev/null | head -c 8192 | grep -m1 -iE '^([[:space:]]*<\?php)?[[:space:]/*#@]*Version:' | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*(\*\/|\?>).*$//; s/[[:space:]]*$//'
}

# Each changed plugin folder: the path down to the folder under wp-content/plugins (or a top-level
# plugins/ in a wp-content repo), not a "plugins" folder some theme or plugin ships.
git -C "$BUILT" diff --name-only HEAD~1 HEAD \
    | awk -F/ '{ for ( i = 1; i < NF - 1; i++ ) if ( $i == "plugins" && ( i == 1 || $(i - 1) == "wp-content" ) ) { p = $1; for ( j = 2; j <= i + 1; j++ ) p = p "/" $j; print p; next } }' \
    | sort -u \
    | while read -r dir; do
        # Its main file: the top-level PHP file with a "Plugin Name" header, as WordPress finds it, trying
        # <folder>/<folder>.php first (a folder may hold more than one header file).
        { echo "$dir/${dir##*/}.php"; git -C "$BUILT" ls-tree --full-tree --name-only HEAD~1 "$dir/" | grep '\.php$'; } | awk '!seen[$0]++' | while read -r file; do
            git -C "$BUILT" show "HEAD~1:$file" | head -c 8192 | grep -qiE '^([[:space:]]*<\?php)?[[:space:]/*#@]*Plugin Name:' || continue
            from=$(version_at HEAD~1 "$file")
            to=$(version_at HEAD "$file")
            [ -n "$from" ] && [ -n "$to" ] && jq -n --arg folder "${dir##*/}" --arg from "$from" --arg to "$to" '{ ($folder): { from: $from, to: $to } }'
            break
        done
    done \
    | jq -sc 'add // {}' | base64 -w0 > "${RUNNER_TEMP}/replay-previous"

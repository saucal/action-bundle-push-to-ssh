#!/bin/bash

# Post-push hook: rsync swapped plugin files without WordPress's upgrader, so fire the
# "plugin updated" hook the way wp-admin's "Update now" does for every plugin whose version
# changed (serviceapp-client's `wp saucal replay_upgrades`), then run the plugins' database
# updates. Sites without those commands skip them. Never fails the deploy: the files are
# already live. Database updates left pending go to the deploy's Slack thread. Runs after the cache
# flush (10-), so cached pages pointing at replaced assets don't wait for it.
# shortcut: assumes PHP serves the new files (opcache revalidating timestamps); on a host that never
# revalidates, the site and this replay run old code until its opcache is reset.

export SSH_AUTH_SOCK=/tmp/ssh_agent.sock

# $SSH_COMMAND is defined in main.js of saucal/action-deploy-ssh
remote() { eval "$SSH_COMMAND 'cd ${REMOTE_ROOT} && $1'"; }

# Runs a `wp saucal` command the site's client has. Skipped where WP-CLI can't work on a WordPress
# install (no `wp`, not WordPress, run as root: `wp core version` reads files only) or the client lacks
# the command; but has-command also fails when WordPress can't load, a failure (checked with a read-only
# `wp option get`, which hosts don't disable the way some do `eval`).
# It prints SAUCAL_HOOK_RAN first, so a shell that couldn't run it at all is told apart below.
saucal() { echo "echo SAUCAL_HOOK_RAN; if ! command -v wp >/dev/null || ! wp core version >/dev/null 2>&1; then :; elif wp cli has-command \"saucal $1\"; then wp saucal $1${2:+ $2}; elif ! wp option get home >/dev/null; then echo \"WP-CLI could not load the site.\" >&2; exit 1; fi"; }

# The versions this deploy replaced (prepare-replay-upgrades.sh), base64: safe inside the quoting.
previous=$(cat "${RUNNER_TEMP}/replay-previous" 2>/dev/null)
remote "$(saucal replay_upgrades "${previous:+--previous=$previous}")" > >(grep -v '^SAUCAL_HOOK_RAN$') \
    || echo "::warning title=Plugin update replay::Replaying plugin updates failed, see above."

output=$(remote "$(saucal update_plugin_databases)" 2>&1)
status=$?
echo "${output//SAUCAL_HOOK_RAN$'\n'/}"
if [ $status -ne 0 ] && [[ "$output" != *SAUCAL_HOOK_RAN* ]]; then
    # The account couldn't run commands at all (restricted key, non-POSIX shell): nothing for the site to fix.
    echo "::warning title=Database updates not checked::The remote shell could not run the check, see above."
elif [ $status -ne 0 ]; then
    echo "::warning title=Database updates pending::Plugin database updates are pending or could not be checked, see above."
    printf 'Plugin database updates are pending or could not be checked after this deploy. Run them from wp-admin.\n\n%s\n' "${output//SAUCAL_HOOK_RAN$'\n'/}" > "${RUNNER_TEMP}/db-updates-pending.txt"
fi

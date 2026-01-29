#!/bin/bash

echo "Running prepare-cache-flush.sh"

if [ "${INPUT_FLUSH_CACHE}" == 'false' ]; then
    echo "Skipping cache flush" # We shouldn't be here if its false, but just in case.
    exit 0
fi

echo "::group::Preparing Cache Flush"

echo "$INPUT_FLUSH_CACHE" > "${RUNNER_TEMP}/INPUT_FLUSH_CACHE"
echo "$INPUT_FLUSH_CACHE_EXTRA_PARAMS" > "${RUNNER_TEMP}/INPUT_FLUSH_CACHE_EXTRA_PARAMS"

## Hook into the hook system for ssh deployment
HOOK_PATH="${RUNNER_TEMP}/.saucal/ssh-deploy/post"
mkdir -p "${HOOK_PATH}"
ln -s "${GITHUB_ACTION_PATH}/handle-cache-flush.sh" "${HOOK_PATH}/10-handle-cache-flush.sh"
chmod +x "${HOOK_PATH}/10-handle-cache-flush.sh"

echo "Hooked handle-cache-flush.sh to ${HOOK_PATH}/10-handle-cache-flush.sh"

echo "::endgroup::"


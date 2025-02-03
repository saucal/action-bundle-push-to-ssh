#!/bin/bash

POSITIONAL_ARGS=()
INPUT_FLUSH_CACHE=""
INPUT_FLUSH_CACHE_EXTRA_PARAMS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --flush-cache)
            INPUT_FLUSH_CACHE="$2"
            shift # past argument
            shift # past argument
            ;;
        --flush-cache-extra-params)
            INPUT_FLUSH_CACHE_EXTRA_PARAMS="$2"
            shift # past argument
            shift # past argument
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo "::group::Flushing cache"

if [ "${INPUT_FLUSH_CACHE}" == 'auto' ] || [ "${INPUT_FLUSH_CACHE}" == 'default' ]; then
    echo ::warning title=Flush cache::No Generic way to flush cache. Exiting.
    exit 0;
fi

exitcode=0

if [[ "${INPUT_FLUSH_CACHE}" == *"convesio"* ]]; then
    notice "Running command: " curl -s -f -I -X POST "${INPUT_FLUSH_CACHE_EXTRA_PARAMS}"
    curl -s -f -I -X POST "${INPUT_FLUSH_CACHE_EXTRA_PARAMS}" || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"kinsta"* ]]; then
    notice 'Flushing Kinsta cache'
    rcli kinstZ cache purge || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wpe"* ]]; then
    notice 'Flushing WPE cache'
    rcli cdn-cache flush || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"objectcache"* ]]; then
    notice 'Flushing object cache'
    rcli cache flush || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wprocket"* ]]; then
    notice 'Flushing WP Rocket cache'
    rcli rocket clean --confirm || exitcode=$?
fi

if [ $exitcode -ne 0 ]; then
    echo ""
    echo "::warning title:Flush cache failed::Failed to flush cache"
else
    echo "Flushed cache"
fi

echo "::endgroup::"

exit 0 # Prevent the script from failing the workflow.

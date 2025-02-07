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

if [ "${INPUT_FLUSH_CACHE}" == 'false' ]; then
    echo "Skipping cache flush" # We shouldn't be here if its false, but just in case.
    exit 0
fi

echo "::group::Flushing cache"

if [ "${INPUT_FLUSH_CACHE}" == 'default' ]; then
    INPUT_FLUSH_CACHE="auto"
fi

exitcode=0

if [[ "${INPUT_FLUSH_CACHE}" == *"convesio"* ]]; then
    notice "Running command: " curl -s -f -I -X POST "${INPUT_FLUSH_CACHE_EXTRA_PARAMS}"
    curl -s -f -I -X POST "${INPUT_FLUSH_CACHE_EXTRA_PARAMS}" || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"kinsta"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && rcli cli has-command "kinsta cache purge"); then
    notice 'Flushing Kinsta cache'
    rcli kinsta cache purge || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wpe"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && rcli cli has-command "cdn-cache flush"); then
    notice 'Flushing WPE cache'
    rcli cdn-cache flush || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wpe"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && rcli cli has-command "nexcess-mapps cache flush"); then
    notice 'Flushing NEXCESS cache'
    rcli nexcess-mapps cache flush --all || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wprocket"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && rcli cli has-command "rocket clean"); then
    notice 'Flushing WP Rocket cache'
    rcli rocket clean --confirm || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"objectcache"* ]] || [[ "${INPUT_FLUSH_CACHE}" == "auto" ]]; then
    notice 'Flushing object cache'
    rcli cache flush || exitcode=$?
fi

if [ $exitcode -ne 0 ]; then
    echo ""
    echo "::warning title:Flush cache failed::Failed to flush cache"
else
    echo "Flushed cache"
fi

echo "::endgroup::"

exit 0 # Prevent the script from failing the workflow.

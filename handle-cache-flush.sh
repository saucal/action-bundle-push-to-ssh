#!/bin/bash

# Set SSH_AUTH_SOCK to the agent socket
export SSH_AUTH_SOCK=/tmp/ssh_agent.sock

run_command() { 
    local command=$1

    # $SSH_COMMAND is defined in main.js of saucal/action-deploy-ssh
    # TODO: Improve quotes handling & consider maintainability of the logic in long term
    if [ -z "$SSH_COMMAND" ]; then
        echo "SSH_COMMAND is not set. Unable to execute the command remotely."
        return 1
    fi

    # Execute the command remotely
    eval "$SSH_COMMAND '$command'"
    return $?
}

if [ ! -f "${RUNNER_TEMP}/INPUT_FLUSH_CACHE" ]; then
    echo "INPUT_FLUSH_CACHE file does not exist in ${RUNNER_TEMP}."
    exit 0 # Exit with success code
fi

INPUT_FLUSH_CACHE=$(cat "${RUNNER_TEMP}/INPUT_FLUSH_CACHE")
INPUT_FLUSH_CACHE_EXTRA_PARAMS=$(cat "${RUNNER_TEMP}/INPUT_FLUSH_CACHE_EXTRA_PARAMS")

if [ "${INPUT_FLUSH_CACHE}" == 'default' ]; then
    INPUT_FLUSH_CACHE="auto"
fi

exitcode=0

if [[ "${INPUT_FLUSH_CACHE}" == *"convesio"* ]]; then
    echo "Running command: " curl -s -f -I -X POST "${INPUT_FLUSH_CACHE_EXTRA_PARAMS}"
    curl -s -f -I -X POST "${INPUT_FLUSH_CACHE_EXTRA_PARAMS}" || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"kinsta"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && run_command "cd ${REMOTE_ROOT} && wp cli has-command \"kinsta cache purge\""); then
    echo 'Flushing Kinsta cache'
    run_command "cd ${REMOTE_ROOT} && wp kinsta cache purge" || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wpe"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && run_command "cd ${REMOTE_ROOT} && wp cli has-command \"cdn-cache flush\""); then
    echo 'Flushing WPE cache'
    run_command "cd ${REMOTE_ROOT} && wp cdn-cache flush" || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wpe"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && run_command "cd ${REMOTE_ROOT} && wp cli has-command \"nexcess-mapps cache flush\""); then
    echo 'Flushing NEXCESS cache'
    run_command "cd ${REMOTE_ROOT} && wp nexcess-mapps cache flush --all" || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"wprocket"* ]] || ([[ "${INPUT_FLUSH_CACHE}" == "auto" ]] && run_command "cd ${REMOTE_ROOT} && wp cli has-command \"rocket clean\""); then
    echo 'Flushing WP Rocket cache'
    run_command "cd ${REMOTE_ROOT} && wp rocket clean --confirm" || exitcode=$?
fi

if [[ "${INPUT_FLUSH_CACHE}" == *"objectcache"* ]] || [[ "${INPUT_FLUSH_CACHE}" == "auto" ]]; then
    echo 'Flushing object cache'
    run_command "cd ${REMOTE_ROOT} && wp cache flush" || exitcode=$?
fi

if [ $exitcode -ne 0 ]; then
    echo ""
    echo "::warning title:Flush cache failed::Failed to flush cache"
else
    echo "Flushed cache"
fi
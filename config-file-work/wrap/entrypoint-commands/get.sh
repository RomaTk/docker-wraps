#!/bin/bash

function getSpecificData {
    local wrap="$1"

    local entrypoint_commands
    local type
    local key="run.entrypoint.commands"

    if [[ -z "$wrap" ]]; then
        echo "No wrap provided" >&2
        exit 1
    fi

    type=$(echo "$wrap" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" == "null" ]]; then
        exit 0
    fi

    if [[ "$type" != "array" ]]; then
        echo "EntrypointCommands is not an array" >&2
        exit 1
    fi

    entrypoint_commands=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$entrypoint_commands"
    exit 0
}
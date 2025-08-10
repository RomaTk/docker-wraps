#!/bin/bash

function getEntrypoint {
    local wrap="$1"

    local entrypoint
    local type
    local key="run.entrypoint.tool"

    if [[ -z "$wrap" ]]; then
        echo "No wrap provided" >&2
        exit 1
    fi

    type=$(echo "$wrap" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" == "null" ]]; then
        exit 0
    fi

    if [[ "$type" != "string" ]]; then
        echo "Entrypoint is not a string" >&2
        exit 1
    fi

    entrypoint=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$entrypoint"
    exit 0
}
#!/bin/bash

function getInteractive {
    local wrap="$1"

    local is_interactive
    local type
    local key="run.interactive"

    if [[ -z "$wrap" ]]; then
        echo "No wrap provided" >&2
        exit 1
    fi

    type=$(echo "$wrap" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" == "null" ]]; then
        exit 0
    fi

    if [[ "$type" != "boolean" ]]; then
        echo "Interactive is not a boolean" >&2
        exit 1
    fi

    is_interactive=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$is_interactive"
    exit 0
}
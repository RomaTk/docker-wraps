#!/bin/bash

function getSignal {
    local wrap="$1"

    local signal
    local type
    local key="kill.signal"

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
        echo "Signal is not a string" >&2
        exit 1
    fi

    signal=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$signal"
    exit 0
}
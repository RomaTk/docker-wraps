#!/bin/bash

function getTimeout {
    local wrap="$1"

    local timeout
    local type
    local key="stop.timeout"

    if [[ -z "$wrap" ]]; then
        echo "No wrap provided" >&2
        exit 1
    fi

    type=$(echo "$wrap" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" == "null" ]]; then
        exit 0
    fi

    if [[ "$type" != "number" ]]; then
        echo "Timeout is not a number" >&2
        exit 1
    fi

    timeout=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$timeout"
    exit 0
}
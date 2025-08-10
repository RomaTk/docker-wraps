#!/bin/bash

function getContext {
    local wrap="$1"

    local context
    local type
    local key="build.context"

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
        echo "Context is not a string" >&2
        exit 1
    fi

    context=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$context"
    exit 0
}
#!/bin/bash

function getClean {
    local wrap="$1"

    local clean_array
    local type
    local key="clean"

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
        echo "Clean is not an array" >&2
        exit 1
    fi

    clean_array=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$clean_array"
    exit 0
}
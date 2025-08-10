#!/bin/bash

function getSpecificData {
    local wrap="$1"

    local stop_options
    local type
    local key="stop.options"

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
        echo "stopOptions is not an array" >&2
        exit 1
    fi

    stop_options=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$stop_options"
    exit 0
}
#!/bin/bash

function getSpecificData {
    local wrap="$1"

    local run_options
    local type
    local key="run.options"

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
        echo "runOptions is not an array" >&2
        exit 1
    fi

    run_options=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$run_options"
    exit 0
}
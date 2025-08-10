#!/bin/bash

function getAllWrapNames {
    local json_file="$1"

    local type
    local wraps
    local wrap_names

    local key="wraps"

    if [[ -z "$json_file" ]]; then
        echo "No json file provided" >&2
        exit 1
    fi

    wraps=$(jq -r ".$key" "$json_file")
    [ $? -ne 0 ] && echo "Error: $wraps" && exit 1

    if [[ -z "$wraps" ]]; then
        echo "[]"
        exit 0
    fi

    if [[ "$wraps" == "null" ]]; then
        echo "[]"
        exit 0
    fi

    type=$(echo "$wraps" | jq -r "type")
    [ $? -ne 0 ] && echo "Error: $type" && exit 1

    if [[ "$type" != "object" ]]; then
        echo "Wraps is not an object" >&2
        exit 1
    fi

    wrap_names=$(echo "$wraps" | jq  "keys_unsorted")
    [ $? -ne 0 ] && echo "Error: $wrap_names" && exit 1

    type=$(echo "$wrap_names" | jq -r "type")
    [ $? -ne 0 ] && echo "Error: $type" && exit 1

    if [[ "$type" != "array" ]]; then
        echo "wrap_names is not an array" >&2
        exit 1
    fi

    echo "$wrap_names"
    exit 0
}
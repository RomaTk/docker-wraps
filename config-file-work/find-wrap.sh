#!/bin/bash

function findWrap {
    local json_file="$1"
    local wrap_name="$2"

    local type

    local key="wraps"

    if [[ -z "$json_file" ]]; then
        echo "No json file provided" >&2
        exit 1
    fi

    if [[ -z "$wrap_name" ]]; then
        echo "No wrap name provided" >&2
        exit 1
    fi

    type=$(jq -r ".$key | type" "$json_file")
    [ $? -ne 0 ] && echo "Error: $type" && exit 1

    if [[ "$type" != "object" ]]; then
        echo "Wraps is not an object" >&2
        exit 1
    fi

    type=$(jq -r ".$key | .\"$wrap_name\" | type" "$json_file")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" == "null" ]]; then
        exit 0
    fi

    if [[ "$type" != "object" ]]; then
        echo "Wrap is not an object" >&2
        exit 1
    fi

    echo $(jq -r ".$key | .\"$wrap_name\"" "$json_file")
    [ $? -ne 0 ] && exit 1
    
    exit 0
}
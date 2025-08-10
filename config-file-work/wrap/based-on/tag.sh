#!/bin/bash

function getBasedOnTag {
    local based_on="$1"

    local tag
    local type
    local key="tag"

    if [[ -z "$based_on" ]]; then
        echo "No based_on provided" >&2
        exit 1
    fi

    type=$(echo "$based_on" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" != "string" ]]; then
        echo "Tag is not a string" >&2
        exit 1
    fi

    tag=$(echo "$based_on" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$tag"
    exit 0
}
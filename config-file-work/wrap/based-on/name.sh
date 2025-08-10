#!/bin/bash

function getBasedOnName {
    local based_on="$1"

    local name
    local type
    local key="name"

    if [[ -z "$based_on" ]]; then
        echo "No based_on provided" >&2
        exit 1
    fi

    type=$(echo "$based_on" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" != "string" ]]; then
        echo "Name is not a string" >&2
        exit 1
    fi

    name=$(echo "$based_on" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$name"
    exit 0
}
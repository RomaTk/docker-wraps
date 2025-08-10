#!/bin/bash

function getBasedOn {
    local wrap="$1"

    local based_on
    local type
    local key="basedOn"

    if [[ -z "$wrap" ]]; then
        echo "No wrap provided" >&2
        exit 1
    fi

    type=$(echo "$wrap" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" == "null" ]]; then
        exit 0
    fi

    if [[ "$type" != "object" ]]; then
        echo "BasedOn is not an object" >&2
        exit 1
    fi

    based_on=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$based_on"
    exit 0
}
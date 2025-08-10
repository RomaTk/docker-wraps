#!/bin/bash

function getSpecificData {
    local wrap="$1"

    local volumes
    local type
    local key="run.volumes"

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
        echo "volumes is not an array" >&2
        exit 1
    fi

    volumes=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$volumes"
    exit 0
}
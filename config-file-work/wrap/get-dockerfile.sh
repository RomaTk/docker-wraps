#!/bin/bash

function getDockerfile {
    local wrap="$1"

    local dockerfile
    local type
    local key="dockerfile"

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
        echo "Dockerfile is not a string" >&2
        exit 1
    fi

    dockerfile=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$dockerfile"
    exit 0
}
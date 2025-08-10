#!/bin/bash

function getSpecificData {
    local wrap="$1"

    local run_before_build
    local type
    local key="build.run.before"

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
        echo "runBeforeBuild is not an array" >&2
        exit 1
    fi

    run_before_build=$(echo "$wrap" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$run_before_build"
    exit 0
}
#!/bin/bash

function getUniquePrefix {
    local json_file="$1"
    
    local key="uniquePrefix"
    local type

    if [[ -z "$json_file" ]]; then
        echo "No json file provided" >&2
        exit 1
    fi

    type=$(jq -r ".$key | type" "$json_file")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" != "string" ]]; then
        echo "Unique prefix is not a string" >&2
        exit 1
    fi


    echo $(jq -r ".$key" "$json_file")
    [ $? -ne 0 ] && exit 1

    exit 0
}
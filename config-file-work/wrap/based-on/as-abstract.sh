#!/bin/bash

function getAsAbstract {
    local based_on="$1"

    local is_as_abstract
    local type
    local key="asAbstract"

    if [[ -z "$based_on" ]]; then
        echo "No based_on provided" >&2
        exit 1
    fi

    type=$(echo "$based_on" | jq -r ".$key | type")
    [ $? -ne 0 ] && exit 1

    if [[ "$type" != "boolean" && "$type" != "null" ]]; then
        echo "AsAbstract is not a boolean" >&2
        exit 1
    fi

    if [[ "$type" == "null" ]]; then
        echo "false"
        exit 0
    fi

    is_precreate=$(echo "$based_on" | jq -r ".$key")
    [ $? -ne 0 ] && exit 1

    echo "$is_precreate"
    exit 0
}
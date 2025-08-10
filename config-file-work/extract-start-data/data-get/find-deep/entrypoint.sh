#!/bin/bash

function getData {
    local data

    source "$config_dir/wrap/get-entrypoint.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    data=$(getEntrypoint "$wrap")
    [ $? -ne 0 ] && throwError 151 "$data"

    if [[ -z "$data" ]]; then
        exit 2
    else
        echo "$data"
    fi

    exit 0
}

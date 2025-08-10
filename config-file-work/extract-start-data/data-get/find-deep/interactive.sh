#!/bin/bash

function getData {
    local data

    source "$config_dir/wrap/get-interactive.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    data=$(getInteractive "$wrap")
    [ $? -ne 0 ] && throwError 122 "$data"

    if [[ -z "$data" ]]; then
        exit 2
    else
        echo "$data"
    fi

    exit 0
}

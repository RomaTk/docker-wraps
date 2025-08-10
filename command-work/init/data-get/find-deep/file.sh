#!/bin/bash

function getData {
    local data

    source "$config_dir/wrap/get-dockerfile.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    data=$(getDockerfile "$wrap")
    [ $? -ne 0 ] && throwError 120 "$data"

    if [[ -z "$data" ]]; then
        exit 2
    else
        echo "$data"
    fi

    exit 0
}

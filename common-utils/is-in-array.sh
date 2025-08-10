#!/bin/bash

function checkIsInArray {
    local element="$1"
    shift
    local array=("$@")
    local result="false"

    for i in "${array[@]}"; do
        if [[ "$i" == "$element" ]]; then
            result="true"
            break
        fi
    done

    echo $result
    exit 0
}
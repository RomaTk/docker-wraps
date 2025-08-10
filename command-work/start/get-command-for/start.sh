#!/bin/bash

function getCommandForStart {
    local run_command="$1"
    local common_utils_dir="$2"
    local current_dir="$3"
    local container_name="$4"
    
    local full_string=""
    local part_string
    local file_to_source

    file_to_source="$common_utils_dir/extract-docker-option.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"


    part_string=$(checkNotBooleanOption "$run_command" "--attach" "-a")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --attach)"
    full_string="${full_string}${part_string}"

    part_string=$(checkNotBooleanOption "$run_command" "--detach-keys")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --detach-keys)"
    full_string="${full_string}${part_string}"

    part_string=$(checkBooleanOption "$run_command" "--interactive" "-i")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --interactive)"
    full_string="${full_string}${part_string}"

    if [[ -z "$full_string" ]]; then
        echo "docker start \"$container_name\""
        exit 0
    fi

    echo "docker start ${full_string:1} \"$container_name\""
    exit 0
}
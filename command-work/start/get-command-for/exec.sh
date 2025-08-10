#!/bin/bash

function getCommandForExec {
    local run_command="$1"
    local common_utils_dir="$2"
    local current_dir="$3"
    local container_name="$4"
    local cmd="$5"
    
    local full_string=""
    local part_string
    local entrypoint
    local file_to_source

    file_to_source="$common_utils_dir/extract-docker-option.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    entrypoint=$(getEntrypoint "--entrypoint" "$run_command")
    [ $? -ne 0 ] && throwError 158 "$entrypoint (check --entrypoint)"
    if [[ -z "$entrypoint" ]]; then
        throwError 161
    fi

    part_string=$(checkBooleanOption "$run_command" "--detach" "-d")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --detach)"
    full_string="${full_string}${part_string}"

    part_string=$(checkNotBooleanOption "$run_command" "--detach-keys")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --detach-keys)"
    full_string="${full_string}${part_string}"

    part_string=$(checkNotBooleanOption "$run_command" "--env" "-e")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --env)"
    full_string="${full_string}${part_string}"

    part_string=$(checkNotBooleanOption "$run_command" "--env-file")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --env-file)"
    full_string="${full_string}${part_string}"

    part_string=$(checkBooleanOption "$run_command" "--interactive" "-i")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --interactive)"
    full_string="${full_string}${part_string}"

    part_string=$(checkBooleanOption "$run_command" "--privileged")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --privileged)"
    full_string="${full_string}${part_string}"

    part_string=$(checkBooleanOption "$run_command" "--tty" "-t")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --tty)"
    full_string="${full_string}${part_string}"

    part_string=$(checkNotBooleanOption "$run_command" "--user" "-u")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --user)"
    full_string="${full_string}${part_string}"

    part_string=$(checkNotBooleanOption "$run_command" "--workdir" "-w")
    [ $? -ne 0 ] && throwError 158 "$part_string (check --workdir)"
    full_string="${full_string}${part_string}"

    if [[ -z "$full_string" ]]; then
        full_string="docker exec \"$container_name\""
    else
        full_string="docker exec ${full_string:1} \"$container_name\""
    fi

    full_string="$full_string $entrypoint"

    if [[ -z "$cmd" ]]; then
        echo "$full_string"
        exit 0
    fi

    echo "$full_string $cmd"
    exit 0
}

function getEntrypoint {
    local values
    values=$(getAllCommandOptionValues "--entrypoint" "$run_command")
    [ $? -ne 0 ] && throwError 157 "$values"
    
    if [[ -n "$values" ]]; then
        while IFS= read -r val; do
            echo "$val"
            exit 0
        done <<< "$values"
    fi

    exit 0
}
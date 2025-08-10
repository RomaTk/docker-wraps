#!/bin/bash

function main {
    local scripts_dir="$1"
    local file_with_config="$2"
    local command="$3"
    
    local last_action
    local file_to_source
    local exit_code

    file_to_source="$scripts_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    file_to_source="$scripts_dir/install-all-necessary/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    last_action=$(installAllNecessary "$scripts_dir")
    [ $? -ne 0 ] && throwError 112 "$last_action"

    file_to_source="$scripts_dir/command-work/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$last_action"
    
    (
        commandWork "$scripts_dir" "$file_with_config" "$command"
    )
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 113 "Exit code was: $exit_code"

    exit 0
}
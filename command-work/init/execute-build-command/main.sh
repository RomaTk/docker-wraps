#!/bin/bash

function executeBuildCommand {
    local scripts_dir="$1"
    local buildCommand="$2"
    local exit_code
    local file_to_source

    local current_dir="$scripts_dir/command-work/init/execute-build-command"

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    echo "BUILD COMMAND: $buildCommand"
    (eval "$buildCommand")
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 133 "Exit code was: $exit_code"

    exit $exit_code
}
#!/bin/bash

function installAllNecessary {
    local scripts_dir="$1"

    local this_dir="$scripts_dir/install-all-necessary"
    local file_to_source
    local run_file
    local last_action

    file_to_source="$this_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    run_file="$this_dir/docker-install.sh"
    last_action=$(chmod +x "$run_file")
    [ $? -ne 0 ] && throwError 114 "$last_action"
    last_action=$("$run_file")
    [ $? -ne 0 ] && throwError 112 "$last_action"

    run_file="$this_dir/jq-install.sh"
    last_action=$(chmod +x "$run_file")
    [ $? -ne 0 ] && throwError 114 "$last_action"
    last_action=$("$run_file")
    [ $? -ne 0 ] && throwError 113"$last_action"

    exit 0
}
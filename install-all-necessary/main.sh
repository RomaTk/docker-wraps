#!/bin/bash

function installAllNecessary {
    local scripts_dir="$1"

    local this_dir="$scripts_dir/install-all-necessary"
    local file_to_source
    local last_action

    file_to_source="$this_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    file_to_source="$this_dir/docker-install.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi
    (main) >&2
    [ $? -ne 0 ] && throwError 112

    file_to_source="$this_dir/jq-install.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi
    (main) >&2
    [ $? -ne 0 ] && throwError 113

    exit 0
}
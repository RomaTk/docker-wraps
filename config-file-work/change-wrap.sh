#!/bin/bash

function changeWrap {
    local json_file="$1"
    local wrap_name="$2"
    local wrap="$3"

    local type
    local last_action
    local command_to_do
    local new_file_with_config

    local key="wraps"

    if [[ -z "$json_file" ]]; then
        echo "No json file provided" >&2
        exit 1
    fi

    if [[ -z "$wrap_name" ]]; then
        echo "No wrap name provided" >&2
        exit 1
    fi

    type=$(jq -r ".$key | type" "$json_file")
    [ $? -ne 0 ] && echo "Error: $type" && exit 1

    if [[ "$type" != "object" ]]; then
        echo "Wraps is not an object" >&2
        exit 1
    fi

    command_to_do=".$key.\"$wrap_name\" = \$newWrap"

    new_file_with_config="$(mktemp)"
    last_action=$(jq -r --argjson newWrap "$wrap" "$command_to_do" "$json_file" > "$new_file_with_config" && mv "$new_file_with_config" "$json_file")
    if [ $? -ne 0 ]; then
        echo "Error changing wrap $last_action" >&2
        exit 1
    fi

    exit 0
}
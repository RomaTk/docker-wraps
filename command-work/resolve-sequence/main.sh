#!/bin/bash

function resolveSequence {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"
    local new_file_with_config="$5"

    local current_dir="$scripts_dir/command-work/resolve-sequence"
    local config_dir="$scripts_dir/config-file-work"

    local file_to_source
    local sequence
    local last_action

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    if [[ -z "$wrap_name" ]]; then
        throwError 120
    fi

    if [[ -z "$new_file_with_config" ]]; then
        throwError 121
    fi

    file_to_source="$scripts_dir/command-work/get-sequence/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/find-wrap.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/change-wrap.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/name.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    sequence="$(getSequence "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name")"
    [ $? -ne 0 ] && throwError 112 "$sequence"

    last_action="$(cp "$file_with_config" "$new_file_with_config")"
    [ $? -ne 0 ] && throwError 113 "$last_action"

    (changeFileWithSequence "$wrap_name")
    [ $? -ne 0 ] && throwError 119

    exit 0
}

function changeFileWithSequence {
    local initial_wrap_name="$1"
    local item
    local item_with_wrap_name
    local i
    local index_of_item_with_wrap_name
    local wrap_name

    local end_index
    local sequence_length
    local end_index

    sequence_length=$(echo "$sequence" | jq -r 'length')
    [ $? -ne 0 ] && throwError 1 "Failed to get sequence length ${sequence_length}"

    if [[ "$sequence_length" -lt 1 ]]; then
        exit 0
    fi

    end_index=$((sequence_length - 1))
    for ((i=0; i<end_index; i++)); do
        item="$(echo "$sequence" | jq -r ".[$i]")"
        [ $? -ne 0 ] && throwError 1 "Failed to get sequence item at index ${i}"

        index_of_item_with_wrap_name=$((i + 1))
        item_with_wrap_name="$(echo "$sequence" | jq -r ".[$index_of_item_with_wrap_name]")"
        [ $? -ne 0 ] && throwError 1 "Failed to get name from sequence item at index ${index_of_item_with_wrap_name}"

        wrap_name="$(getBasedOnName "$item_with_wrap_name")"
        [ $? -ne 0 ] && throwError 114 "$wrap_name"

        (changeBasedOnInWrap "$item" "$wrap_name")
        [ $? -ne 0 ] && throwError 118
    done

    item="$(echo "$sequence" | jq -r ".[$end_index]")"
    [ $? -ne 0 ] && throwError 1 "Failed to get sequence item at index ${end_index}"

    (changeBasedOnInWrap "$item" "$initial_wrap_name")
    [ $? -ne 0 ] && throwError 118

    exit 0
}


function changeBasedOnInWrap {
    local new_based_on="$1"
    local wrap_name="$2"

    local last_action
    local wrap

    wrap="$(findWrap "$new_file_with_config" "$wrap_name")"
    [ $? -ne 0 ] && throwError 115 "$wrap"

    if [[ -z "$wrap" ]]; then
        throwError 116 "Wrap \"$wrap_name\" not found"
    fi

    wrap="$(echo "$wrap" | jq --argjson newBasedOn "$new_based_on" '.basedOn = $newBasedOn')"
    [ $? -ne 0 ] && throwError 1 "Failed to set new basedOn value"

    echo "$wrap_name"
    echo "$wrap"

    last_action="$(changeWrap "$new_file_with_config" "$wrap_name" "$wrap")"
    [ $? -ne 0 ] && throwError 117 "$last_action"

    exit 0
}
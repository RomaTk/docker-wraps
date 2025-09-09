#!/bin/bash

function getSequence {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"

    local current_dir="$scripts_dir/command-work/get-sequence"
    local config_dir="$scripts_dir/config-file-work"

    local file_to_source

    local sequence

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    file_to_source="$config_dir/find-wrap.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/is-precreate.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/name.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/tag.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    sequence="$(getItemsForSequence "$wrap_name")"
    [ $? -ne 0 ] && throwError 114 "$sequence"

    sequence="$(goThrewSequence "$sequence")"
    [ $? -ne 0 ] && throwError 115 "$sequence"

    sequence="$(sortSequence "$sequence")"
    [ $? -ne 0 ] && throwError 119 "$sequence"

    sequence="$(removeIsAnalysed "$sequence")"
    [ $? -ne 0 ] && throwError 121 "$sequence"

    echo "$sequence"
    exit 0
}

function getItemsForSequence {
    local wrap_name="$1"

    local wrap
    local based_on
    local type

    wrap=$(findWrap "$file_with_config" "$wrap_name")
    [ $? -ne 0 ] && throwError 112 "$wrap"

    based_on=$(getBasedOn "$wrap")
    [ $? -ne 0 ] && throwError 113 "$based_on"

    if [[ -z "$based_on" ]]; then
        echo "[]"
        exit 0
    fi

    type="$(echo "$based_on" | jq -r "type")"
    [ $? -ne 0 ] && throwError 1 "Error: $type"

    if [[ "$type" == "array" ]]; then
        echo "$based_on"
        exit 0
    fi

    echo "[$based_on]"
    exit 0
}

function goThrewSequence {
    local sequence="$1"

    local length
    local item
    local is_precreate
    local name
    local i
    local new_items
    local items_length

    local new_sequence

    local changeMade="true"

    while [[ "$changeMade" == "true" ]]; do
        changeMade="false"

        new_sequence="[]"

        length=$(echo "$sequence" | jq -r "length")
        [ $? -ne 0 ] && throwError 1 "Error: $length"

        for (( i=0; i<length; i++ )); do

            item=$(echo "$sequence" | jq -r ".[$i]")
            [ $? -ne 0 ] && throwError 1 "Error: $item"

            is_precreate="$(getIsPrecreate "$item")"
            [ $? -ne 0 ] && throwError 116 "$is_precreate"

            is_analysed="$(echo "$item" | jq -r ".isAnalysed")"
            [ $? -ne 0 ] && throwError 1 "Error: $is_analysed"

            if [[ "$is_precreate" == "true" && "$is_analysed" != "true" ]]; then

                name="$(getBasedOnName "$item")"
                [ $? -ne 0 ] && throwError 117 "$name"

                new_items="$(getItemsForSequence "$name")"
                [ $? -ne 0 ] && throwError 114 "$new_items"

                item=$(echo "$item" | jq -r ".isAnalysed=true")
                [ $? -ne 0 ] && throwError 1 "Error: $item"

                new_sequence=$(echo "$new_sequence" | jq -r ". + $new_items + [$item]")
                [ $? -ne 0 ] && throwError 1 "Error: $new_sequence"

                changeMade="true"
            else
                new_sequence=$(echo "$new_sequence" | jq -r ". + [$item]")
                [ $? -ne 0 ] && throwError 1 "Error: $new_sequence"
            fi

        done

        sequence="$new_sequence"
        
    done

    echo "$sequence"

    exit 0
}


function isInSequenceAlready {
    local sequence="$1"
    local item_to_check="$2"

    local length
    local item
    local name
    local item_to_check_name
    local i

    length=$(echo "$sequence" | jq -r "length")
    [ $? -ne 0 ] && throwError 1 "Error: $length"

    item_to_check_name="$(getBasedOnName "$item_to_check")"
    [ $? -ne 0 ] && throwError 117 "$item_to_check_name"

    for (( i=0; i<length; i++ )); do
        item=$(echo "$sequence" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "Error: $item"

        name="$(getBasedOnName "$item")"
        [ $? -ne 0 ] && throwError 117 "$name"

        if [[ "$name" == "$item_to_check_name" ]]; then
            echo "true"
            exit 0
        fi
    done

    echo "false"
    exit 0
}

function sortSequence {
    local sequence="$1"

    local length
    local sorted_sequence="[]"
    local sorted_sequence_length
    local item
    local is_precreate
    local tag
    local i
    local is_in_sequence_already

    length=$(echo "$sequence" | jq -r "length")
    [ $? -ne 0 ] && throwError 1 "Error: $length"

    for (( i=0; i<length; i++ )); do
        item=$(echo "$sequence" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "Error: $item"

        is_precreate="$(getIsPrecreate "$item")"
        [ $? -ne 0 ] && throwError 116 "$is_precreate"

        tag="$(getBasedOnTag "$item")"
        [ $? -ne 0 ] && throwError 118 "$tag"

        initial_item="$item"

        if [[ "$is_precreate" == "false" || "$tag" != "latest" ]]; then
            # Only one non-precreate or non-latest item is allowed in the sequence and it should be the first one
            sorted_sequence_length=$(echo "$sorted_sequence" | jq -r "length")
            [ $? -ne 0 ] && throwError 1 "$sorted_sequence_length"
            if [[ "$sorted_sequence_length" -eq 0 ]]; then
                sorted_sequence="[$item]"
            fi
        
            continue
        fi

        is_in_sequence_already="$(isInSequenceAlready "$sorted_sequence" "$item")"
        [ $? -ne 0 ] && throwError 120 "$is_in_sequence_already"

        if [[ "$is_in_sequence_already" == "true" ]]; then
            continue
        fi

        sorted_sequence="$(echo "$sorted_sequence" | jq -r ". + [$item]")"
        [ $? -ne 0 ] && throwError 1 "Error: $sorted_sequence"

    done

    echo "$sorted_sequence"
    exit 0
}


function removeIsAnalysed {
    local sequence="$1"

    local length
    local item
    local i
    local new_sequence="[]"

    length=$(echo "$sequence" | jq -r "length")
    [ $? -ne 0 ] && throwError 1 "Error: $length"

    for (( i=0; i<length; i++ )); do
        item=$(echo "$sequence" | jq -r ".[$i] | del(.isAnalysed)")
        [ $? -ne 0 ] && throwError 1 "Error: $item"

        new_sequence="$(echo "$new_sequence" | jq -r ". + [$item]")"
        [ $? -ne 0 ] && throwError 1 "Error: $new_sequence"
    done

    echo "$new_sequence"
    exit 0
}
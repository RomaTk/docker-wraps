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

    file_to_source="$config_dir/wrap/based-on/as-abstract.sh"
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

    if [[ -z "$wrap" ]]; then
        throwError 122 "Wrap \"$wrap_name\" not found"
    fi

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

    local item
    local is_precreate
    local is_as_abstract
    local is_analysed
    local name
    local new_items
    local new_sequence

    local changeMade="true"
    local items_array

    while [[ "$changeMade" == "true" ]]; do
        changeMade="false"
        new_sequence="[]"

        # Read JSON array elements into bash array
        local items_array
    eval "items_array=($(echo "$sequence" | jq -e -r '.[] | (if type == "string" then . else tostring end) | @sh'))"
    [ $? -ne 0 ] && throwError 1 "Error parsing sequence"

        for item in "${items_array[@]}"; do
            is_precreate="$(getIsPrecreate "$item")"
            [ $? -ne 0 ] && throwError 116 "$is_precreate"

            is_as_abstract="$(getAsAbstract "$item")"
            [ $? -ne 0 ] && throwError 123 "$is_as_abstract"

            is_analysed="$(echo "$item" | jq -r '.isAnalysed')"
            [ $? -ne 0 ] && throwError 1 "Error: $is_analysed"

            if [[ "$is_precreate" == "true" || "$is_as_abstract" == "true" ]] && [[ "$is_analysed" != "true" ]]; then

                name="$(getBasedOnName "$item")"
                [ $? -ne 0 ] && throwError 117 "$name"

                new_items="$(getItemsForSequence "$name")"
                [ $? -ne 0 ] && throwError 114 "$new_items"

                if [[ "$is_precreate" == "false" && "$is_as_abstract" == "true" ]]; then
                    new_items="$(changeNewItemsAsAbstractOnly "$new_items")"
                    [ $? -ne 0 ] && throwError 124 "$new_items"
                fi

                item=$(echo "$item" | jq -c -r '.isAnalysed=true')
                [ $? -ne 0 ] && throwError 1 "Error: $item"

                new_sequence=$(jq -c -r --argjson seq "$new_sequence" --argjson ni "$new_items" --argjson it "$item" '$seq + $ni + [$it]' <<<"{}")
                [ $? -ne 0 ] && throwError 1 "Error: $new_sequence"

                changeMade="true"
            else
                new_sequence=$(jq -c -r --argjson seq "$new_sequence" --argjson it "$item" '$seq + [$it]' <<<"{}")
                [ $? -ne 0 ] && throwError 1 "Error: $new_sequence"
            fi
        done

        sequence="$new_sequence"        
    done

    echo "$sequence"
    exit 0
}

function changeNewItemsAsAbstractOnly {
    local items="$1"

    local item
    local is_as_abstract
    local is_precreate
    local new_items="[]"
    local items_array

    local items_array
    eval "items_array=($(echo "$items" | jq -e -r '.[] | (if type == "string" then . else tostring end) | @sh'))"
    [ $? -ne 0 ] && throwError 1 "Error parsing items"

    for item in "${items_array[@]}"; do
        is_precreate="$(getIsPrecreate "$item")"
        [ $? -ne 0 ] && throwError 116 "$is_precreate"

        is_as_abstract="$(getAsAbstract "$item")"
        [ $? -ne 0 ] && throwError 123 "$is_as_abstract"

        if [[ "$is_precreate" == "true" || "$is_as_abstract" == "true" ]]; then
            item="$(echo "$item" | jq -c -r '.asAbstract=true | .precreate=false')"
            [ $? -ne 0 ] && throwError 1 "Error: $item"
        fi

        new_sequence="$(jq -c -r --argjson seq "$new_items" --argjson it "$item" '$seq + [$it]' <<<"{}")"
        new_items="$new_sequence"
        [ $? -ne 0 ] && throwError 1 "Error: $new_items"
    done

    echo "$new_items"
    exit 0
}


function isInSequenceAlready {
    local sequence="$1"
    local item_to_check="$2"

    local item
    local name
    local item_to_check_name
    local items_array

    item_to_check_name="$(getBasedOnName "$item_to_check")"
    [ $? -ne 0 ] && throwError 117 "$item_to_check_name"

    local items_array
    eval "items_array=($(echo "$sequence" | jq -e -r '.[] | (if type == "string" then . else tostring end) | @sh'))"
    [ $? -ne 0 ] && throwError 1 "Error parsing sequence"

    for item in "${items_array[@]}"; do
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

    local sorted_sequence="[]"
    local sorted_sequence_length
    local item
    local is_precreate
    local is_as_abstract
    local tag
    local is_in_sequence_already
    local items_array
    local new_sequence

    local items_array
    eval "items_array=($(echo "$sequence" | jq -e -r '.[] | (if type == "string" then . else tostring end) | @sh'))"
    [ $? -ne 0 ] && throwError 1 "Error parsing sequence"

    for item in "${items_array[@]}"; do
        is_precreate="$(getIsPrecreate "$item")"
        [ $? -ne 0 ] && throwError 116 "$is_precreate"

        is_as_abstract="$(getAsAbstract "$item")"
        [ $? -ne 0 ] && throwError 123 "$is_as_abstract"

        tag="$(getBasedOnTag "$item")"
        [ $? -ne 0 ] && throwError 118 "$tag"

        if [[ "$is_precreate" == "false" && "$is_as_abstract" != "true" ]] || [[ "$tag" != "latest" ]]; then
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

        new_sequence="$(jq -c -r --argjson seq "$sorted_sequence" --argjson it "$item" '$seq + [$it]' <<<"{}")"
        sorted_sequence="$new_sequence"
        [ $? -ne 0 ] && throwError 1 "Error: $sorted_sequence"
    done

    echo "$sorted_sequence"
    exit 0
}


function removeIsAnalysed {
    local sequence="$1"

    local item
    local new_sequence="[]"
    local items_array
    local next_sequence

    local items_array
    eval "items_array=($(echo "$sequence" | jq -e -r '.[] | (if type == "string" then . else tostring end) | @sh'))"
    [ $? -ne 0 ] && throwError 1 "Error parsing sequence"

    for item in "${items_array[@]}"; do
        item=$(echo "$item" | jq -c -r 'del(.isAnalysed)')
        [ $? -ne 0 ] && throwError 1 "Error: $item"

        next_sequence="$(jq -c -r --argjson seq "$new_sequence" --argjson it "$item" '$seq + [$it]' <<<"{}")"
        new_sequence="$next_sequence"
        [ $? -ne 0 ] && throwError 1 "Error: $new_sequence"
    done

    echo "$new_sequence"
    exit 0
}
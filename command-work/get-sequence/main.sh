#!/bin/bash

function getSequence {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"
    local wrap_weights="$5"

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

    if [[ -n "$wrap_weights" && "$wrap_weights" != "null" && "$wrap_weights" != "{}" ]]; then
        sequence="$(sortByWrapWeights "$sequence" "$wrap_weights")"
        [ $? -ne 0 ] && throwError 135 "$sequence"
    fi

    echo "$sequence" | jq '.'
    exit 0
}

function sortByWrapWeights {
    local sequence="$1"
    local wrap_weights="$2"

    local has_missing
    local sorted_sequence

    # Check for missing names in items or names missing from wrap_weights
    has_missing="$(echo "$sequence" | jq -e --argjson weights "$wrap_weights" 'any(.[]; .name == null or .name == "" or ($weights[.name] == null))')"
    if [ $? -ne 0 ] && [[ "$has_missing" != "false" && "$has_missing" != "true" ]]; then
        throwError 133 "jq error checking for missing names"
    fi

    if [[ "$has_missing" == "true" ]]; then
        throwError 134 "Sequence item missing name or name not found in wrap_weights"
    fi

    # Perform stable sort by wrap_weights descending
    sorted_sequence="$(echo "$sequence" | jq -c --argjson weights "$wrap_weights" 'sort_by(-$weights[.name])')"
    [ $? -ne 0 ] && throwError 133 "Failed to sort sequence by wrap_weights"

    echo "$sorted_sequence"
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
    [ $? -ne 0 ] && throwError 125 "Error checking basedOn type: $type"

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
    local items_data
    local i

    while [[ "$changeMade" == "true" ]]; do
        changeMade="false"
        new_sequence="[]"

        # Batch extract fields for all items to minimize jq calls in the loop
        mapfile -d $'\0' -t items_data < <(echo "$sequence" | jq -j '.[] | (.precreate // false, "\u0000", .asAbstract // false, "\u0000", .isAnalysed // false, "\u0000", .name // "", "\u0000", tostring, "\u0000")')
        [ $? -ne 0 ] && throwError 126 "Error mapping sequence data in goThrewSequence"

        for (( i=0; i<${#items_data[@]}; i+=5 )); do
            is_precreate="${items_data[i]}"
            is_as_abstract="${items_data[i+1]}"
            is_analysed="${items_data[i+2]}"
            name="${items_data[i+3]}"
            item="${items_data[i+4]}"

            if [[ "$is_precreate" == "true" || "$is_as_abstract" == "true" ]] && [[ "$is_analysed" != "true" ]]; then

                # Check for empty name which would cause getItemsForSequence to fail
                if [[ -z "$name" ]]; then
                    throwError 117 "Empty name"
                fi

                new_items="$(getItemsForSequence "$name")"
                [ $? -ne 0 ] && throwError 114 "$new_items"

                if [[ "$is_precreate" == "false" && "$is_as_abstract" == "true" ]]; then
                    new_items="$(changeNewItemsAsAbstractOnly "$new_items")"
                    [ $? -ne 0 ] && throwError 124 "$new_items"
                fi

                item="$(echo "$item" | jq -c '.isAnalysed=true')"
                [ $? -ne 0 ] && throwError 127 "Error setting isAnalysed in goThrewSequence: $item"

                # Append using jq array concatenation
                new_sequence="$(echo "$new_sequence" | jq -c --argjson n "$new_items" --argjson i "$item" '. + $n + [$i]')"
                [ $? -ne 0 ] && throwError 128 "Error concatenating new items in goThrewSequence: $new_sequence"

                changeMade="true"
            else
                # Append single item
                new_sequence="$(echo "$new_sequence" | jq -c --argjson i "$item" '. + [$i]')"
                [ $? -ne 0 ] && throwError 129 "Error appending single item in goThrewSequence: $new_sequence"
            fi
        done

        sequence="$new_sequence"        
    done

    echo "$sequence"
    exit 0
}

function changeNewItemsAsAbstractOnly {
    local items="$1"

    local new_items
    new_items="$(echo "$items" | jq -c 'map(if (.precreate == true or .asAbstract == true) then .asAbstract = true | .precreate = false else . end)')"
    [ $? -ne 0 ] && throwError 130 "Error setting asAbstract in changeNewItemsAsAbstractOnly: $new_items"

    echo "$new_items"
    exit 0
}


function sortSequence {
    local sequence="$1"

    local sorted_sequence
    sorted_sequence="$(echo "$sequence" | jq -c '
        reduce .[] as $item ([];
            if (($item.precreate == false and $item.asAbstract != true) or $item.tag != "latest") then
                if length == 0 then [$item] else . end
            elif any(.[]; .name == $item.name) then
                .
            else
                . + [$item]
            end
        )
    ')"
    [ $? -ne 0 ] && throwError 131 "Error sorting sequence in sortSequence: $sorted_sequence"

    echo "$sorted_sequence"
    exit 0
}


function removeIsAnalysed {
    local sequence="$1"

    local new_sequence
    new_sequence="$(echo "$sequence" | jq -c 'map(del(.isAnalysed))')"
    [ $? -ne 0 ] && throwError 132 "Error removing isAnalysed in removeIsAnalysed: $new_sequence"

    echo "$new_sequence"
    exit 0
}
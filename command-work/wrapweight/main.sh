#!/bin/bash

function wrapWeightAll {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"

    local file_to_source="$scripts_dir/command-work/wrapweight/utils.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && exit 111

    local wrap_names
    local wrap_names_length
    local i
    local wrap_name
    local weights="{}"

    file_to_source="$scripts_dir/config-file-work/get-all-wrap-names.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    wrap_names=$(getAllWrapNames "$file_with_config")
    [ $? -ne 0 ] && throwError 123 "$wrap_names"

    wrap_names_length=$(echo "$wrap_names" | jq -r "length")
    [ $? -ne 0 ] && throwError 1 "Error: $wrap_names_length"

    # initialize weights with 0 for all wraps in config
    for (( i=0; i<wrap_names_length; i++ )); do
        wrap_name=$(echo "$wrap_names" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "Error: $wrap_name"

        if [[ -n "$wrap_name" && "$wrap_name" != "null" ]]; then
            weights=$(echo "$weights" | jq -r --arg name "$wrap_name" '.[$name] = 0')
        fi
    done

    # calculate weights
    for (( i=0; i<wrap_names_length; i++ )); do
        wrap_name=$(echo "$wrap_names" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "Error: $wrap_name"

        if [[ -n "$wrap_name" && "$wrap_name" != "null" ]]; then
            weights=$(calcWeight "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "$weights" "$wrap_names")
            [ $? -ne 0 ] && throwError 124 "$weights"
        fi
    done

    # Print nicely
    echo "$weights" | jq .

    exit 0
}

function calcWeight {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"
    local current_weights="$5"
    local all_wrap_names="$6"

    local sequence
    local sequence_length
    local j
    local seq_item
    local seq_wrap_name
    local is_in_config

    # Add +1 to the current wrap
    current_weights=$(echo "$current_weights" | jq -r --arg name "$wrap_name" '.[$name] = (.[$name] + 1)')

    # Execute getSequence in a subshell since it exits
    sequence=$(
        source "$scripts_dir/utils.sh"
        source "$scripts_dir/install-all-necessary/main.sh"
        source "$scripts_dir/command-work/utils.sh"
        source "$scripts_dir/command-work/get-sequence/main.sh"

        getSequence "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name"
    )

    if [ $? -eq 0 ]; then
        sequence_length=$(echo "$sequence" | jq -r "length")
        if [ $? -eq 0 ]; then
            for (( j=0; j<sequence_length; j++ )); do
                seq_item=$(echo "$sequence" | jq -r ".[$j]")

                # Use jq to get the name directly to avoid needing to source extra scripts or if they are already sourced
                seq_wrap_name=$(echo "$seq_item" | jq -r ".name")

                if [[ -n "$seq_wrap_name" && "$seq_wrap_name" != "null" ]]; then
                    is_in_config=$(echo "$all_wrap_names" | jq -r --arg name "$seq_wrap_name" 'any(. == $name)')
                    if [[ "$is_in_config" == "true" ]]; then
                        current_weights=$(echo "$current_weights" | jq -r --arg name "$seq_wrap_name" '.[$name] = (.[$name] + 1)')
                    fi
                fi
            done
        fi
    fi

    echo "$current_weights"
}
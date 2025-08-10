#!/bin/bash

function getRunAfterBuildInit {
    local wrap_name="$1"
    local file_to_source

    local run_after_build

    file_to_source="$current_dir/data-get/run-after-build.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    run_after_build=$(getRunAfterBuild "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name")
    [ $? -ne 0 ] && throwError 157 "$run_after_build"

    run_after_build=$(echo "$run_after_build" | jq -r --sort-keys '.')
    [ $? -ne 0 ] && throwError 143 "$run_after_build"

    echo "$run_after_build"
    exit 0
}


function insertRunAfterBuildToRunBeforeBuild {
    local run_after_build="$1"
    local run_before_build="$2"
    
    local based_on_list
    local based_on_list_1
    local based_on_list_length
    local i
    local current_wrap_name
    local current_wrap_data="null"
    local current_wrap_data_before

    based_on_list=$(echo "$run_before_build" | jq -r '.basedOnList')
    [ $? -ne 0 ] && throwError 159 "$based_on_list"
    based_on_list_1=$(echo "$run_after_build" | jq -r '.basedOnList')
    [ $? -ne 0 ] && throwError 159 "$based_on_list_1"

    if [[ "$based_on_list" != "$based_on_list_1" ]]; then
        throwError 161
    fi

    based_on_list_length=$(echo "$based_on_list" | jq -r '. | length')
    [ $? -ne 0 ] &&  throwError 162 "$based_on_list_length"

    for (( i=0; i<$based_on_list_length; i++ )); do
        current_wrap_name=$(echo "$based_on_list" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "$current_wrap_name"

        if [[ "$current_wrap_name" != "null" ]]; then
            current_wrap_data_before=$(echo "$run_before_build" | jq -r ".data.\"$current_wrap_name\"")
            [ $? -ne 0 ] && throwError 164 "$current_wrap_data_before"

            if [[ "$current_wrap_data_before" != "null" ]]; then
                current_wrap_data_before=$(echo "$current_wrap_data" | jq -r ". + $current_wrap_data_before")
                [ $? -ne 0 ] && throwError 165 "$current_wrap_data_before"
            else
                current_wrap_data_before=$current_wrap_data
            fi

            run_before_build=$(echo "$run_before_build" | jq -r ".data.\"$current_wrap_name\" = $current_wrap_data_before")
            [ $? -ne 0 ] && throwError 165 "$run_before_build"

        fi
        current_wrap_data=$(echo "$run_after_build" | jq -r ".data.\"$current_wrap_name\"")
        [ $? -ne 0 ] && throwError 164 "$current_wrap_data"
    done

    if [[ "$current_wrap_data" != "null" ]]; then
        run_before_build=$(echo "$run_before_build" | jq -r ".inTheEnd = $current_wrap_data")
        [ $? -ne 0 ] && throwError 165 "$run_before_build"
    fi

    echo "$run_before_build"

    exit 0
}

function runAfterBuildDo {
    local length_of_array
    local in_the_end_array
    local command

    if [[ "$is_to_run_in_the_end" == "false" ]]; then
        exit 0
    fi

    in_the_end_array=$(echo "$run_before_build" | jq -r '.inTheEnd')
    [ $? -ne 0 ] && throwError 1 "$in_the_end_array"

    if [[ "$in_the_end_array" == "null" ]]; then
        exit 0
    fi

    length_of_array=$(echo "$in_the_end_array" | jq -r '. | length')
    [ $? -ne 0 ] && throwError 1 "$length_of_array"
    
    for (( i=0; i<$length_of_array; i++ )); do
        command=$(echo "$in_the_end_array" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "$command"

        echo "COMMAND: $command"
        (eval "$command")
        [ $? -ne 0 ] && throwError 156
    done

    exit 0
}
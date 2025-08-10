#!/bin/bash

function runBeforeBuildDo {

    local based_on_array
    local length_of_array
    
    local i
    local wrap_name

    if [[ "$is_only_run_this_run_before_build" == "true" ]]; then

        (runBeforeBuildDoForSomeWrap "$initial_wrap_name")
        [ $? -ne 0 ] && throwError 154

        exit 0
    fi


    based_on_array=$(echo "$run_before_build" | jq -r ".basedOnList")
    [ $? -ne 0 ] && throwError 1 "$based_on_array"

    length_of_array=$(echo "$based_on_array" | jq -r ". | length")
    [ $? -ne 0 ] && throwError 1 "$based_on_array"

    for (( i=0; i<$length_of_array; i++ )); do
        wrap_name=$(echo "$based_on_array" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "$based_on_array"

        (runBeforeBuildDoForSomeWrap "$wrap_name")
        [ $? -ne 0 ] && throwError 154

    done

    exit 0
}

function runBeforeBuildDoForSomeWrap {
    local wrap_name="$1"

    local is_there_some_commands
    local commands
    local length_of_commands
    local command

    is_there_some_commands=$(echo "$run_before_build" | jq -r ".data | has(\"$wrap_name\")")
    [ $? -ne 0 ] && throwError 1 "$is_there_some_commands"

    if [[ "$is_there_some_commands" == "false" ]]; then
        exit 0
    fi

    commands=$(echo "$run_before_build" | jq -r ".data.\"$wrap_name\"")
    [ $? -ne 0 ] && throwError 1 "$commands"

    length_of_commands=$(echo "$commands" | jq -r ". | length")
    [ $? -ne 0 ] && throwError 1 "$length_of_commands"

    for (( i=0; i<$length_of_commands; i++ )); do
        command=$(echo "$commands" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "$command"

        echo "COMMAND: $command"
        (eval "$command")
        [ $? -ne 0 ] && throwError 156
    done

    exit 0
}

# To remove data from previous will be created build
function removeSomeWrapFromRunBeforeBuild {
    local run_before_build="$1"
    local wrap_name="$2"

    run_before_build=$(echo "$run_before_build" | jq -r --sort-keys "del(.data.\"$wrap_name\") | .basedOnList -= [\"$wrap_name\"]")
    [ $? -ne 0 ] && throwError 1 "$run_before_build"

    echo "$run_before_build"
    exit 0
}

function getRunBeforeBuildInit {
    local wrap_name="$1"
    local file_to_source

    local run_before_build

    file_to_source="$current_dir/data-get/run-before-build.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    run_before_build=$(getRunBeforeBuild "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name")
    [ $? -ne 0 ] && throwError 148 "$run_before_build"

    run_before_build=$(echo "$run_before_build" | jq -r --sort-keys '.')
    [ $? -ne 0 ] && throwError 143 "$run_before_build"

    echo "$run_before_build"
    exit 0
}
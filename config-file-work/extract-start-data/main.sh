#!/bin/bash

function extractStartData {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"

    local common_utils_dir="$scripts_dir/common-utils"
    local current_dir="$scripts_dir/config-file-work/extract-start-data"
    local config_dir="$scripts_dir/config-file-work"

    local file_to_source

    local cmd
    local data
    local return_data

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    # find deep
    file_to_source="$common_utils_dir/find-deep.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$common_utils_dir/extract-docker-option.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$current_dir/data-get/options.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    cmd=$(getCmd "$wrap_name")
    [ $? -ne 0 ] && throwError 162 "$cmd"

    data=$(getDataForRun "$wrap_name" "$cmd")
    [ $? -ne 0 ] && throwError 155 "$data"
    
    return_data=$(jq -n -r --arg data "$data" --arg cmd "$cmd" '{data: $data, cmd: $cmd}')
    [ $? -ne 0 ] && throwError 156 "$return_data"

    echo "$return_data" 

    exit 0
}

function getCmd {
    local wrap_name="$1"

    local file_to_source
    local entrypoint_args
    local entrypoint_commands
    local cmd

    file_to_source="$current_dir/data-get/entrypoint-args.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    entrypoint_args=$(getEntrypointArgs "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name")
    [ $? -ne 0 ] && throwError 152 "$entrypoint_args"

    file_to_source="$current_dir/data-get/entrypoint-commands.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    entrypoint_commands=$(getEntrypointCommands "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name")
    [ $? -ne 0 ] && throwError 153 "$entrypoint_commands"

    cmd=$(convertEntrypointValuesToOptions)
    [ $? -ne 0 ] && throwError 154 "$cmd"

    echo "$cmd"
    exit 0
}

function getDataForRun {
    local wrap_name="$1"
    local cmd="$2"
    local file_to_source

    local stop_signal
    local stop_timeout
    local stop_options="[]"
    local stop_options_string=""

    local interactive
    local volumes
    local entrypoint
    local run_options="[]"
    local options_string=""

    local all_data_together=""
    local image_name

    stop_signal=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/stop-signal.sh")
    [ $? -ne 0 ] && throwError 125 "$stop_signal"

    if [[ -n "$stop_signal" ]]; then
        stop_options=$(echo "$stop_options" | jq -r ". + [ \"--stop-signal \\\"$stop_signal\\\"\"] ")
        [ $? -ne 0 ] && throwError 1 "Error within jq adding stop-signal"
    fi

    stop_timeout=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/stop-timeout.sh")
    [ $? -ne 0 ] && throwError 126 "$stop_timeout"

    if [[ -n "$stop_timeout" ]]; then
        stop_options=$(echo "$stop_options" | jq -r ". + [ \"--stop-timeout $stop_timeout\"] ")
        [ $? -ne 0 ] && throwError 1 "Error within jq adding stop-timeout"
    fi

    stop_options=$(getOptions "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$stop_options" "stop-options")
    [ $? -ne 0 ] && throwError 127 "$stop_options"

    stop_options_string=$(echo "$stop_options" | jq -r 'join(" ")')
    if [ $? -ne 0 ]; then
        echo "Error within jq converting stop_options to strings" >&2
        exit 1
    fi

    stop_signal=$(getAllCommandOptionValues "--stop-signal" "someCommand $stop_options_string")
    #add error handling
    if [[ -n "$stop_signal" ]]; then
        while IFS= read -r val; do
            run_options=$(echo "$run_options" | jq -r ". + [ \"--stop-signal ${val//\"/\\\"}\"] ")
            [ $? -ne 0 ] && throwError 1 "Error within jq adding stop-signal"
        done <<< "$stop_signal"
    fi

    stop_timeout=$(getAllCommandOptionValues "--stop-timeout" "someCommand $stop_options_string")
    #add error handling
    if [[ -n "$stop_timeout" ]]; then
        while IFS= read -r val; do
            run_options=$(echo "$run_options" | jq -r ". + [ \"--stop-timeout $val\"] ")
            [ $? -ne 0 ] && throwError 1 "Error within jq adding stop-timeout"
        done <<< "$stop_timeout"
    fi

    interactive=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/interactive.sh")
    [ $? -ne 0 ] && throwError 123 "$interactive"

    if [[ -z "$interactive" ]]; then
        interactive="false"
    fi

    if [[ "$interactive" == "true" ]]; then
        run_options=$(echo "$run_options" | jq -r ". + [ \"-i\"] ")
        [ $? -ne 0 ] && throwError 1 "Error within jq adding -i"
    fi

    entrypoint=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/entrypoint.sh")
    [ $? -ne 0 ] && throwError 123 "$entrypoint"

    if [[ -n "$entrypoint" ]]; then
        run_options=$(echo "$run_options" | jq -r ". + [ \"--entrypoint \\\"$entrypoint\\\"\"] ")
        [ $? -ne 0 ] && throwError 1 "Error within jq adding entrypoint"
    fi

    file_to_source="$current_dir/data-get/volumes.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    volumes=$(getVolumes "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name")
    [ $? -ne 0 ] && throwError 124 "$volumes"
    
    run_options=$(convertVolumesToOptions)
    [ $? -ne 0 ] && throwError 150 "$run_options"

    run_options=$(getOptions "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$run_options" "run-options")
    [ $? -ne 0 ] && throwError 127 "$run_options"

    options_string=$(echo "$run_options" | jq -r 'join(" ")')
    if [ $? -ne 0 ]; then
        echo "Error within jq converting run_options to strings" >&2
        exit 1
    fi
    
    file_to_source="$scripts_dir/command-work/get-name/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    image_name=$(getName "$unique_prefix" "$wrap_name" "image")
    [ $? -ne 0 ] && throwError 163 "$image_name"

    all_data_together="$options_string"
    if [[ ${#all_data_together} -gt 0 ]]; then
        all_data_together="$all_data_together \"$image_name\""
    else
        all_data_together="\"$image_name\""
    fi

    if [[ ${#cmd} -gt 0 ]]; then
        all_data_together="$all_data_together $cmd"
    fi

    echo "$all_data_together"

    exit 0
}

function convertVolumesToOptions {
    local volume_data_source
    local volume_data_destination
    local volume_data_readonly
    local volume_data_nocopy
    local volume_string
    local volume_strings=()

    file_to_source="$common_utils_dir/path-convert.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    while IFS=$'\t' read -r volume_data_source volume_data_destination volume_data_readonly volume_data_nocopy; do
        if [[ "$volume_data_source" == "null" ]]; then
            continue
        fi

        if [[ "$volume_data_source" == *'/'* ]]; then
            volume_data_source=$(abspath "$volume_data_source")
            [ $? -ne 0 ] && throwError 135 "$volume_data_source"
        fi

        # TODO add change bind or volume
        volume_string="--mount type=bind,src=\"$volume_data_source\",dst=\"$volume_data_destination\""

        if [[ "$volume_data_readonly" == "true" ]]; then
            volume_string="$volume_string,ro"
        fi

        if [[ "$volume_data_nocopy" == "true" ]]; then
            volume_string="$volume_string,volume-opt=nocopy"
        fi

        volume_strings+=("$volume_string")
    done < <(echo "$volumes" | jq -r 'if type == "array" then .[] | [.source // "null", .destination // "null", (if .readonly == true then "true" else "false" end), (if ."volume-nocopy" == true then "true" else "false" end)] | @tsv else empty end')

    if [[ ${#volume_strings[@]} -gt 0 ]]; then
        run_options=$(jq -r -n --argjson run_options "$run_options" --args '$run_options + $ARGS.positional' -- "${volume_strings[@]}")
        [ $? -ne 0 ] && throwError 1 "Error within jq adding volumes"
    fi

    echo "$run_options"
    exit 0
}

function convertEntrypointValuesToOptions {
    local entrypoint_args_string
    local entrypoint_commands_string=""
    local command_value
    local command_continue_in_error
    local cmd
    local count=0

    entrypoint_args_string=$(echo "$entrypoint_args" | jq -r 'join(" ")')
    if [ $? -ne 0 ]; then
        echo "Error within jq converting entrypoint_args to strings" >&2
        exit 1
    fi

    while IFS=$'\t' read -r command_value command_continue_in_error; do
        if [[ $count -eq 0 ]]; then
            entrypoint_commands_string="$command_value"
        else
            entrypoint_commands_string="$entrypoint_commands_string $command_value"
        fi

        if [[ "$command_continue_in_error" == "true" ]]; then
            entrypoint_commands_string="$entrypoint_commands_string ;"
        else
            entrypoint_commands_string="$entrypoint_commands_string &&"
        fi
        ((count++))
    done < <(echo "$entrypoint_commands" | jq -r 'if type == "array" then .[] | [.value // empty, (if .continueInError == true then "true" else "false" end)] | @tsv else empty end')

    if [[ "$count" -gt 0 ]]; then
        entrypoint_commands_string="$entrypoint_commands_string exit 0"
    fi

    cmd="$entrypoint_args_string"
    if [[ ${#cmd} -gt 0 && ${#entrypoint_commands_string} -gt 0 ]]; then
        cmd="$cmd \"${entrypoint_commands_string//\"/\\\"}\""
    elif [[ ${#entrypoint_commands_string} -gt 0 ]]; then
        cmd="\"${entrypoint_commands_string//\"/\\\"}\""
    fi

    echo "$cmd"
    exit 0
}
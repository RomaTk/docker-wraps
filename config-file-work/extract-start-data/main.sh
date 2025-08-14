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
    local lengthOfVolumes
    local i
    local volume_data
    local type
    local volume_data_source
    local volume_data_destination
    local volume_data_readonly
    local is_exist

    local volume_string

    file_to_source="$common_utils_dir/path-convert.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    lengthOfVolumes=$(echo "$volumes" | jq -r ". | length")
    [ $? -ne 0 ] && throwError 1 "Error within jq getting length of volumes"

    for (( i=0; i<lengthOfVolumes; i++ )); do

        volume_data=$(echo "$volumes" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "Error within jq getting volume"

        type=$(echo "$volume_data" | jq -r ".source | type")
        [ $? -ne 0 ] && throwError 1 "Error within jq getting type of source"

        if [[ "$type" == "null" ]]; then
            continue
        fi

       

        volume_data_source=$(echo "$volume_data" | jq -r ".source")
        [ $? -ne 0 ] && throwError 1 "Error within jq getting source of volume"

        if [[ "$volume_data_source" == *'/'* ]]; then
            volume_data_source=$(abspath "$volume_data_source")
            [ $? -ne 0 ] && throwError 135 "$volume_data_source"
        fi

        volume_data_destination=$(echo "$volume_data" | jq -r ".destination")
        [ $? -ne 0 ] && throwError 1 "Error within jq getting destination of volume"

        # TODO add change bind or volume
        volume_string="--mount type=bind,src=\"$volume_data_source\",dst=\"$volume_data_destination\""

        
        is_exist=$(echo "$volume_data" | jq -r "has(\"readonly\")")
        [ $? -ne 0 ] && throwError 1 "Error within jq checking readonly"

        if [[ "$is_exist" == "true" ]]; then
            volume_data_readonly=$(echo "$volume_data" | jq -r ".readonly")
            [ $? -ne 0 ] && throwError 1 "Error within jq getting readonly"
            if [[ "$volume_data_readonly" == "true" ]]; then
                volume_string="$volume_string,ro"
            fi
        fi
        
        is_exist=$(echo "$volume_data" | jq -r "has(\"volume-nocopy\")")
        [ $? -ne 0 ] && throwError 1 "Error within jq checking volume-nocopy"

        if [[ "$is_exist" == "true" ]]; then
            volume_data_nocopy=$(echo "$volume_data" | jq -r ".volume-nocopy")
            [ $? -ne 0 ] && throwError 1 "Error within jq getting volume-nocopy"
            if [[ "$volume_data_nocopy" == "true" ]]; then
                volume_string="$volume_string,volume-opt=nocopy"
            fi
        fi

        run_options=$(echo "$run_options" | jq -r ". + [ \"${volume_string//\"/\\\"}\"] ")
        [ $? -ne 0 ] && throwError 1 "Error within jq adding volume"
    done


    echo "$run_options"
    exit 0
}

function convertEntrypointValuesToOptions {
    local entrypoint_args_string

    local length_array
    local entrypoint_commands_string=""
    local entrypoint_command
    local command_value
    local command_continue_in_error

    local cmd
    local i

    entrypoint_args_string=$(echo "$entrypoint_args" | jq -r 'join(" ")')
    if [ $? -ne 0 ]; then
        echo "Error within jq converting entrypoint_args to strings" >&2
        exit 1
    fi

    length_array=$(echo "$entrypoint_commands" | jq -r ". | length")
    if [ $? -ne 0 ]; then
        echo "Error within jq getting length of entrypoint_commands" >&2
        exit 1
    fi

    for (( i=0; i<length_array; i++ )); do
        entrypoint_command=$(echo "$entrypoint_commands" | jq -r ".[$i]")   
        if [ $? -ne 0 ]; then
            echo "Error within jq getting entrypoint_command" >&2
            exit 1
        fi

        command_value=$(echo "$entrypoint_command" | jq -r ".value")
        if [ $? -ne 0 ]; then
            echo "Error within jq getting value of entrypoint_command" >&2
            exit 1
        fi

        command_continue_in_error=$(echo "$entrypoint_command" | jq -r ".continueInError")
        if [ $? -ne 0 ]; then
            echo "Error within jq getting continueInError of entrypoint_command" >&2
            exit 1
        fi

        if [[ "$i" -eq 0 ]]; then
            entrypoint_commands_string="$command_value"
        else
            entrypoint_commands_string="$entrypoint_commands_string $command_value"
        fi
        

        if [ "$command_continue_in_error" == "true" ]; then
            entrypoint_commands_string="$entrypoint_commands_string ;"
        else
            entrypoint_commands_string="$entrypoint_commands_string &&"
        fi
    done

    if [[ "$length_array" -gt 0 ]]; then
        entrypoint_commands_string="$entrypoint_commands_string exit 0"
    fi

    cmd="$entrypoint_args_string"
    if [[ ${#cmd} -gt 0 && ${#entrypoint_commands_string} -gt 0 ]]; then
        cmd="$cmd \"${entrypoint_commands_string//\"/\\\"}\""
    elif [[ ${#entrypoint_commands_string} -gt 0 ]]; then
        cmd=cmd="\"${entrypoint_commands_string//\"/\\\"}\""
    fi

    echo "$cmd"
    exit 0
}
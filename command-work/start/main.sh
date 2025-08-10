#!/bin/bash

function start {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"

    local common_utils_dir="$scripts_dir/common-utils"
    local current_dir="$scripts_dir/command-work/start"
    local config_dir="$scripts_dir/config-file-work"

    local file_to_source

    local full_data
    local cmd
    local data
    local container_name
    local run_command
    local paused_state
    local last_action
    local running_state
    local final_command
    local exit_code
    local specific_command_dir="$current_dir/get-command-for"
    local is_same_image

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    file_to_source="$config_dir/extract-start-data/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$scripts_dir/command-work/get-name/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    full_data=$(extractStartData "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name")
    [ $? -ne 0 ] && throwError 113 "$full_data"

    cmd=$(echo "$full_data" | jq -r '.cmd')
    [ $? -ne 0 ] && throwError 114 "$cmd"

    data=$(echo "$full_data" | jq -r '.data')
    [ $? -ne 0 ] && throwError 115 "$data"

    container_name=$(getName "$unique_prefix" "$wrap_name"  "container" )
    [ $? -ne 0 ] && throwError 165 "$container_name"

    run_command="docker run --name \"$container_name\" $data"

    paused_state=$(docker inspect -f '{{.State.Paused}}' "${container_name}" 2>/dev/null)
    if [[ "$paused_state" == "true" ]]; then
        last_action=$(docker unpause "${container_name}")
        [ $? -ne 0 ] && throwError 164 "$last_action"
    fi

    running_state=$(docker inspect -f '{{.State.Running}}' "${container_name}" 2>/dev/null)    

    if [[ "$running_state" != "true" ]]; then
        # INIT CONTAINER IF IT IS NOT RUNNING

        file_to_source="$scripts_dir/command-work/init/main.sh"
        source "$file_to_source"
        [ $? -ne 0 ] && throwError 111 "$file_to_source"

        (
            init "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name"
        )
        exit_code=$?
        [ $exit_code -ne 0 ] && throwError 166 "Exit code was: $exit_code"

        if [[ "$running_state" == "false" ]]; then
            is_same_image=$(isSameImageId)
            [ $? -ne 0 ] && throwError 170 "$is_same_image"

            if [[ "$is_same_image" == "false" ]]; then
                file_to_source="$scripts_dir/command-work/remove/main.sh"
                source "$file_to_source"
                [ $? -ne 0 ] && throwError 111 "$file_to_source"

                (
                    remove "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "container"
                )
                exit_code=$?
                [ $exit_code -ne 0 ] && throwError 171 "Exit code was: $exit_code"

                (
                    start "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name"
                )
                exit_code=$?
                [ $exit_code -ne 0 ] && throwError 172 "Exit code was: $exit_code"
                
                exit 0
            fi
        fi

    fi

    if [[ "$running_state" == "true" ]]; then
        
        file_to_source="$specific_command_dir/exec.sh"
        source "$file_to_source"
        [ $? -ne 0 ] && throwError 111 "$file_to_source"

        final_command=$(getCommandForExec "$run_command" "$common_utils_dir" "$specific_command_dir" "$container_name" "$cmd")
        [ $? -ne 0 ] && throwError 160 "$final_command"

    elif [[ "$running_state" == "false" ]]; then

        file_to_source="$specific_command_dir/start.sh"
        source "$file_to_source"
        [ $? -ne 0 ] && throwError 111 "$file_to_source"

        final_command=$(getCommandForStart "$run_command" "$common_utils_dir" "$specific_command_dir" "$container_name")
        [ $? -ne 0 ] && throwError 159 "$final_command"

    else
        ## NOT EXISTING CONTAINER
        final_command="$run_command"
    fi

    echo "STARTING COMMAND: $final_command"
    (eval "$final_command")
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 163 "Exit code was: $exit_code"

    exit 0
}

function isSameImageId {
    local image_name

    local image_id_from_image
    local image_id_from_container

    image_name=$(getName "$unique_prefix" "$wrap_name"  "image")
    [ $? -ne 0 ] && throwError 167 "$image_name"

    image_id_from_image=$(docker image inspect --format='{{.Id}}' "$image_name")
    [ $? -ne 0 ] && throwError 168 "$image_id_from_image"

    image_id_from_container=$(docker inspect --format='{{.Image}}' "$container_name")
    [ $? -ne 0 ] && throwError 169 "$image_id_from_container"

    if [[ "$image_id_from_image" == "$image_id_from_container" ]]; then
        echo "true"
    else
        echo "false"
    fi

    exit 0
}
#!/bin/bash

function stopOrKill {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"
    local action_type="$5"

    local common_utils_dir="$scripts_dir/common-utils"
    local current_dir="$scripts_dir/command-work/stop-kill"
    local config_dir="$scripts_dir/config-file-work"

    local file_to_source
    local container_name
    local paused_state
    local last_action
    local running_state

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    file_to_source="$common_utils_dir/extract-docker-option.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$current_dir/data-get/options.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$scripts_dir/command-work/get-name/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"


    container_name=$(getName "$unique_prefix" "$wrap_name"  "container" )
    [ $? -ne 0 ] && throwError 138 "$container_name"

    paused_state=$(docker inspect -f '{{.State.Paused}}' "${container_name}" 2>/dev/null)
    if [[ "$paused_state" == "true" ]]; then
        last_action=$(docker unpause "${container_name}")
        [ $? -ne 0 ] && throwError 139 "$last_action"
    fi

    running_state=$(docker inspect -f '{{.State.Running}}' "${container_name}" 2>/dev/null)    

    if [[ "$running_state" == "true" ]]; then
       
       case $action_type in
            "stop")
                stop
                ;;
            "kill")
                kill
                ;;
            *)
                throwError 142
                ;;
        esac

    elif [[ "$running_state" == "false" ]]; then

        echo "Container with name \"$container_name\" does not run, so it cannot be stopped"

    else
        echo "Container with name \"$container_name\" does not exist"
    fi



    exit 0
}

function stop {
    local data
    local full_command
    local exit_code

    data=$(getDataForStop "$wrap_name")
    [ $? -ne 0 ] && throwError 124 "$data"

    full_command="docker stop $data \"$container_name\""
    echo "STOP COMMAND: $full_command"
    (eval "$full_command")
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 140 "Exit code was: $exit_code"
}

function kill {
    local data
    local full_command
    local exit_code

    data=$(getDataForKill "$wrap_name")
    [ $? -ne 0 ] && throwError 143 "$data"

    full_command="docker kill $data \"$container_name\""
    echo "KILL COMMAND: $full_command"
    (eval "$full_command")
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 141 "Exit code was: $exit_code"
}

# As run command was before, it has priority over stop command
function getDataForStop {
    local wrap_name="$1"
    
    local start_data
    local cmd
    local stop_options="[]"

    local stop_signal
    local stop_timeout
    local stop_options_string

    file_to_source="$config_dir/extract-start-data/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    start_data=$(extractStartData "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name")
    [ $? -ne 0 ] && throwError 125 "$start_data"

    cmd=$(echo "$start_data" | jq -r '.cmd')
    [ $? -ne 0 ] && throwError 126 "$cmd"

    start_data=$(echo "$start_data" | jq -r '.data')
    [ $? -ne 0 ] && throwError 126 "$start_data"

    start_data="someCommand $start_data"

    stop_signal=$(getAllCommandOptionValues "--stop-signal" "$start_data")
    [ $? -ne 0 ] && throwError 127 "$stop_signal (--stop-signal)"
    if [[ -n "$stop_signal" ]]; then
        while IFS= read -r val; do
            stop_options=$(echo "$stop_options" | jq -r ". + [ \"--signal ${val//\"/\\\"}\"] ")
            [ $? -ne 0 ] && throwError 1 "Error within jq adding signal"
        done <<< "$stop_signal"
    fi

    stop_timeout=$(getAllCommandOptionValues "--stop-timeout" "$start_data")
    [ $? -ne 0 ] && throwError 127 "$stop_timeout (--stop-timeout)"
    if [[ -n "$stop_timeout" ]]; then
        while IFS= read -r val; do
            stop_options=$(echo "$stop_options" | jq -r ". + [ \"--timeout $val\"] ")
            [ $? -ne 0 ] && throwError 1 "Error within jq adding timeout"
        done <<< "$stop_timeout"
    fi

    stop_options=$(getOptions "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$stop_options" "stop-options")
    [ $? -ne 0 ] && throwError 128 "$stop_options (stop-options)"

    stop_options_string=$(echo "$stop_options" | jq -r 'join(" ")')
    [ $? -ne 0 ] && throwError 1 "Error within jq joining stop-options"

    echo "$stop_options_string"
    exit 0
}

function getDataForKill {
    local wrap_name="$1"

    file_to_source="$common_utils_dir/find-deep.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    local kill_options="[]"
    local kill_signal
    local kill_options_string

    kill_signal=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/kill-signal.sh")
    [ $? -ne 0 ] && throwError 137 "$kill_signal"

    if [[ -n "$kill_signal" ]]; then
        kill_options=$(echo "$kill_options" | jq -r ". + [ \"--signal \\\"$kill_signal\\\"\"] ")
        [ $? -ne 0 ] && throwError 1 "Error within jq adding stop-signal"
    fi

    kill_options=$(getOptions "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$kill_options" "kill-options")
    [ $? -ne 0 ] && throwError 128 "$kill_options (kill-options)"

    kill_options_string=$(echo "$kill_options" | jq -r 'join(" ")')
    [ $? -ne 0 ] && throwError 1 "Error within jq joining kill-options"

    echo "$kill_options_string"
    exit 0
}
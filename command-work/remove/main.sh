function remove {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"
    local type="$5"

    local current_dir="$scripts_dir/command-work/remove"
    local config_dir="$scripts_dir/config-file-work"

    local file_to_source
    local is_to_do_clean
    
    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    if [ -z "$unique_prefix" ] || [ -z "$wrap_name" ]; then
        throwError 112
    fi

    file_to_source="$scripts_dir/command-work/get-name/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    case $type in
        "container")
            (removeContainer)
            ;;
        "image")
            (removeImage)
            ;;
        "both")
            (removeContainer)
            (removeImage)
            ;;
        *)
            echo "Unknown type: $type" >&2
            exit 1
            ;;
    esac
    
    # Clean up if needed
    is_to_do_clean=$(isToDoClean)
    [ $? -ne 0 ] && throwError 122 "$is_to_do_clean"

    if [[ "$is_to_do_clean" == "false" ]]; then
        exit 0
    fi
    
    file_to_source="$current_dir/clean.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    (clean "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name")
    [ $? -ne 0 ] && throwError 123 "Error during clean process"

    exit 0
}

function isToDoClean {
    local image_name
    local container_name
    local image_info
    local container_info

    image_name=$(getName "$unique_prefix" "$wrap_name" "image")
    [ $? -ne 0 ] && throwError 116 "$image_name"

    container_name=$(getName "$unique_prefix" "$wrap_name" "container")
    [ $? -ne 0 ] && throwError 113 "$container_name"

    image_info=$(docker image inspect "$image_name" 2>/dev/null)

    if [[ "$image_info" != "[]" ]]; then
        echo "false"
        exit 0
    fi

    container_info=$(docker container inspect "$container_name" 2>/dev/null)

    if [[ "$container_info" != "[]" ]]; then
        echo "false"
        exit 0
    fi

    echo "true"
    exit 0
}


function removeContainer {
    local container_name
    local running_state
    local file_to_source
    local exit_code
    local new_file_with_config
    local last_action

    container_name=$(getName "$unique_prefix" "$wrap_name" "container")
    [ $? -ne 0 ] && throwError 113 "$container_name"

    running_state=$(docker inspect -f '{{.State.Running}}' "${container_name}" 2>/dev/null)

    if [[ "$running_state" == "true" ]]; then
        echo "Container \"$container_name\" is running, killing it first..."
        #KILL -> REMOVE
        file_to_source="$scripts_dir/command-work/stop-kill/main.sh"
        source "$file_to_source"
        [ $? -ne 0 ] && throwError 111 "$file_to_source"

        # FOR STOP/KILL WE NEED TO RESOLVE SEQUENCE
        file_to_source="$scripts_dir/command-work/resolve-sequence/main.sh"
        source "$file_to_source"
        [ $? -ne 0 ] && throwError 111 "$file_to_source"

        new_file_with_config="$(mktemp)"
        [ $? -ne 0 ] && throwError 125 "$new_file_with_config"
        (
            resolveSequence "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "$new_file_with_config"
        )
        exit_code=$?
        [ $exit_code -ne 0 ] && throwError 126 "Exit code was: $exit_code"

        # NOW WE RESOLVED SEQUENCE, AND SAVED IN FILE

        (
            stopOrKill "$scripts_dir" "$new_file_with_config" "$unique_prefix" "$wrap_name" "kill"
        )
        exit_code=$?
        [ $exit_code -ne 0 ] && throwError 114 "Exit code was: $exit_code"

        last_action=$(rm -f "$new_file_with_config")
        [ $? -ne 0 ] && throwError 127 "$last_action"

    elif [[ "$running_state" != "false" ]]; then

        # NO SUCH CONTAINER
        echo "No container with name \"$container_name\" to remove"
        exit 0

    else
        echo "Container \"$container_name\" is not running"
    fi

    # REMOVE CONTAINER

    (
        docker container rm --force --volumes "$container_name"
    )
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 115 "Exit code was: $exit_code"

    exit 0
}

function removeImage {
    local image_name
    local image_info
    local exit_code
    
    image_name=$(getName "$unique_prefix" "$wrap_name" "image")
    [ $? -ne 0 ] && throwError 116 "$image_name"

    image_info=$(docker image inspect "$image_name" 2>/dev/null)

    if [[ "$image_info" == "[]" ]]; then
        echo "No image with name \"$image_name\" to remove"
        exit 0
    fi

    # REMOVE IMAGE
    (
        docker image rm --force "$image_name"
    )
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 117 "Exit code was: $exit_code"

    exit 0
}
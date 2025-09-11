#!/bin/bash

function commandWork {
    local scripts_dir="$1"
    local file_with_config="$2"
    local command="$3"

    local current_dir="$scripts_dir/command-work"
    local file_to_source

    local unique_prefix

    local command_as_args

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi


    if [ -z "$command" ]; then
        throwError 112
    fi

    # unique tag
    file_to_source="$scripts_dir/config-file-work/get-unique-prefix.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    unique_prefix=$(getUniquePrefix "$file_with_config")
    [ $? -ne 0 ] && throwError 116 "$unique_prefix"

    if [ -z "$command" ]; then
        throwError 119 "Command is not mentioned"
    fi

    read -r -a command_as_args <<< "$command"

    if [[ ${#command_as_args[@]} -eq 0 ]]; then
        throwError 120 "Length is zero"
    fi

    case ${command_as_args[0]} in
        "get")
           forGet
            ;;
        "remove")
            forRemove
            ;;
        "init" | "start" | "stop" | "kill" | "resolve-sequence")
            forOther
            ;;
        *)
            throwError 113 "Tried command: $command"
            ;;
    esac

    

    exit 0
}

function forGet {
    local file_to_source
    local exit_code
    local what
    local type
    local wrap_name

    if [[ ${#command_as_args[@]} -lt 3 ]]; then
        throwError 120 "Length is less than 3"
    fi
    what="${command_as_args[1]}"
    if [[ "$what" == "name" ]]; then
        if [[ ${#command_as_args[@]} -lt 4 ]]; then
            throwError 120 "Length is less than 4"
        fi
        type="${command_as_args[2]}"
        wrap_name="${command_as_args[3]}"
    else
        wrap_name="${command_as_args[2]}"
    fi

   

    case $what in
        "name")
            file_to_source="$current_dir/get-name/main.sh"
            source "$file_to_source"
            [ $? -ne 0 ] && throwError 111 "$file_to_source"
            (
                getName "$unique_prefix" "$wrap_name" "$type"
            )
            
            exit_code=$?
            [ $exit_code -ne 0 ] && throwError 117 "Exit code was: $exit_code"
            ;;
        "sequence")
            file_to_source="$current_dir/get-sequence/main.sh"
            source "$file_to_source"
            [ $? -ne 0 ] && throwError 111 "$file_to_source"
            (
                getSequence "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name"
            )
            exit_code=$?
            [ $exit_code -ne 0 ] && throwError 124 "Exit code was: $exit_code"
            ;;
        *)
            throwError 121 "Mentioned: $what"
            ;;
    esac
    
}

function forRemove {
    local file_to_source
    local exit_code
    local type
    local wrap_name

    if [[ ${#command_as_args[@]} -lt 3 ]]; then
        if [[ ${#command_as_args[@]} -lt 2 ]]; then
            throwError 120 "Length is less than 2"
        fi
        type="${command_as_args[1]}"

        if [[ "$type" != "all" ]]; then
            throwError 120 "Length is less than 3"
        fi

    fi

    type="${command_as_args[1]}"

    if [[ "$type" == "all" ]]; then
        if [[ ${#command_as_args[@]} -ne 2 ]]; then
            type="${command_as_args[2]}"
            removeAll "$type"
        else
            removeAll "both"
        fi

        exit 0
    fi


    wrap_name="${command_as_args[2]}"

    file_to_source="$current_dir/remove/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"
    (
        remove "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "$type"
    )
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 122 "Exit code was: $exit_code"
}

function removeAll {
    local type="$1"

    local file_to_source
    local wrap_names
    local wrap_names_length
    local i

    file_to_source="$scripts_dir/config-file-work/get-all-wrap-names.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$current_dir/remove/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    wrap_names=$(getAllWrapNames "$file_with_config")
    [ $? -ne 0 ] && throwError 123 "$wrap_names"

    wrap_names_length=$(echo "$wrap_names" | jq -r "length")
    [ $? -ne 0 ] && throwError 1 "Error: $wrap_names_length"

    for (( i=0; i<wrap_names_length; i++ )); do
        wrap_name=$(echo "$wrap_names" | jq -r ".[$i]")
        [ $? -ne 0 ] && throwError 1 "Error: $wrap_name"

        if [[ -z "$wrap_name" ]]; then
            continue
        fi

        (
            remove "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "$type"
        )
        exit_code=$?
        [ $exit_code -ne 0 ] && throwError 122 "Exit code was: $exit_code"
    
    done

}

function forOther {
    local file_to_source
    local exit_code
    local wrap_name
    local new_file_with_config

    if [[ ${#command_as_args[@]} -lt 2 ]]; then
        throwError 120 "Length is less than 2"
    fi

    wrap_name="${command_as_args[1]}"

    case ${command_as_args[0]} in
        "init")
            file_to_source="$current_dir/init/main.sh"
            source "$file_to_source"
            [ $? -ne 0 ] && throwError 111 "$file_to_source"

            (
                init "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name"
            )
            exit_code=$?
            [ $exit_code -ne 0 ] && throwError 114 "Exit code was: $exit_code"
            ;;
        "resolve-sequence")
            if [[ ${#command_as_args[@]} -lt 3 ]]; then
                throwError 120 "Length is less than 3"
            fi

            new_file_with_config="${command_as_args[2]}"

            file_to_source="$current_dir/resolve-sequence/main.sh"
            source "$file_to_source"
            [ $? -ne 0 ] && throwError 111 "$file_to_source"

            (
                resolveSequence "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "$new_file_with_config"
            )
            exit_code=$?
            [ $exit_code -ne 0 ] && throwError 125 "Exit code was: $exit_code"
            ;;
        "start")
            file_to_source="$current_dir/start/main.sh"
            source "$file_to_source"
            [ $? -ne 0 ] && throwError 111 "$file_to_source"

            (
                start "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name"
            )
            exit_code=$?
            [ $exit_code -ne 0 ] && throwError 115 "Exit code was: $exit_code"
            ;;
        "stop")
            file_to_source="$current_dir/stop-kill/main.sh"
            source "$file_to_source"
            [ $? -ne 0 ] && throwError 111 "$file_to_source"

            (
                stopOrKill "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "stop"
            )
            exit_code=$?
            [ $exit_code -ne 0 ] && throwError 118 "Exit code was: $exit_code"
            ;;
        "kill")
            file_to_source="$current_dir/stop-kill/main.sh"
            source "$file_to_source"
            [ $? -ne 0 ] && throwError 111 "$file_to_source"

            (
                stopOrKill "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "kill"
            )
            exit_code=$?
            [ $exit_code -ne 0 ] && throwError 118 "Exit code was: $exit_code"
            ;;
        *)
            throwError 113 "Tried command: $command"
            ;;
    esac
}
#!/bin/bash

function findDeep {
    local current_dir="$1"
    local config_dir="$2"
    local common_utils_dir="$3"
    local file_with_config="$4"
    local wrap_name="$5"
    local command_to_extract="$6"

    local file_to_source
    local is_in_array
    local exit_code
    local was_wrap_names=()
    local wrap

    # for based_on
    local based_on

    file_to_source="$current_dir/utils.sh"
    sourceDo

    file_to_source="$config_dir/find-wrap.sh"
    sourceDo

    file_to_source="$config_dir/wrap/based-on/main.sh"
    sourceDo

    file_to_source="$config_dir/wrap/based-on/is-precreate.sh"
    sourceDo

    file_to_source="$config_dir/wrap/based-on/name.sh"
    sourceDo

    file_to_source="$common_utils_dir/is-in-array.sh"
    sourceDo

    while true; do

        is_in_array=$(checkIsInArray "$wrap_name" "${was_wrap_names[@]}")
        if [ $? -ne 0 ]; then
            echo "$is_in_array" >&2
            echo "Problem with checkIsInArray function" >&2
            exit 1
        fi

        if [[ "$is_in_array" == "true" ]]; then
            echo "BasedOn is circular" >&2
            exit 1
        fi

        was_wrap_names+=("$wrap_name")
        
        wrap=$(findWrap "$file_with_config" "$wrap_name")
        if [ $? -ne 0 ]; then
            echo "$wrap" >&2
            echo "Problem with findWrap function" >&2
            exit 1
        fi

        if [[ -z "$wrap" ]]; then
            echo "No wrap was found with such name \"$wrap_name\"" >&2
            exit 1
        fi

        # get data
        (
            source "$command_to_extract"
            getData
        )
        exit_code=$?

        case $exit_code in
            0)
                exit 0
                ;;
            2)
                # based on
                based_on=$(getBasedOn "$wrap")
                if [ $? -ne 0 ]; then
                    echo "$based_on" >&2
                    echo "Problem with getBasedOn function" >&2
                    exit 1
                fi

                if [[ -z "$based_on" ]]; then
                    exit 0
                fi

                # based on is precreate
                based_on_is_precreate=$(getIsPrecreate "$based_on")
                if [ $? -ne 0 ]; then
                    echo "$based_on_is_precreate" >&2
                    echo "Problem with getIsPrecreate function" >&2
                    exit 1
                fi

                if [[ "$based_on_is_precreate" != "true" ]]; then
                    exit 0
                fi

                # based on name
                based_on_name=$(getBasedOnName "$based_on")
                if [ $? -ne 0 ]; then
                    echo "$based_on_name" >&2
                    echo "Problem with getBasedOnName function" >&2
                    exit 1
                fi

                wrap_name="$based_on_name"

                ;;
            *)
                echo "Unknown error" >&2
                exit 1
                ;;
        esac
    done

    exit 0
}

function sourceDo {
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 1
    fi
}
#!/bin/bash

function getImplementSpecificData {
    local wrap_name="$1"
    local all_data="$2"
    local file_with_config="$3"
    local config_dir="$4"
    local specific_data_work_dir="$5"

    local file_to_source
    local one_data
    local wrap

    local length
    local i
    local type
    local new_arg
    
    file_to_source="$config_dir/find-wrap.sh"
    sourceDo

    file_to_source="$config_dir/wrap/$specific_data_work_dir/get.sh"
    sourceDo

    file_to_source="$config_dir/wrap/$specific_data_work_dir/implement.sh"
    sourceDo

    wrap=$(findWrap "$file_with_config" "$wrap_name")
    if [ $? -ne 0 ]; then
        echo "$wrap" >&2
        echo "Problem within findWrap function" >&2
        exit 1
    fi

    if [[ -z "$wrap" ]]; then
        echo "No wrap found with name $wrap_name" >&2
    fi

    one_data=$(getSpecificData "$wrap")
    if [ $? -ne 0 ]; then
        echo "$one_data" >&2
        echo "Problem within getSpecificData function" >&2
        exit 1
    fi

    if [[ -z "$one_data" ]]; then
        echo "$all_data"
        exit 0
    fi

    length=$(echo "$one_data" | jq -r 'length')
    if [ $? -ne 0 ]; then
        echo "$length" >&2
        echo "Problem with getting length of specific data" >&2
        exit 1
    fi

    for (( i=0; i<$length; i++ )); do
        type=$(echo "$one_data" | jq -r ".[$i] | type")
        if [ $? -ne 0 ]; then
            echo "$type" >&2
            echo "Problem with getting type of specific data" >&2
            exit 1
        fi

        new_arg=$(echo "$one_data" | jq -r ".[$i]")
        if [ $? -ne 0 ]; then
            echo "$new_arg" >&2
            echo "Problem with getting new argument of specific data" >&2
            exit 1
        fi

        all_data=$(implementSpecificData "$new_arg" "$all_data" "$type" "$wrap_name")
        if [ $? -ne 0 ]; then
            echo "$all_data" >&2
            echo "Problem within implementSpecificData function" >&2
            exit 1
        fi
    done

    echo "$all_data"
    exit 0
}

function sourceDo {
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 1
    fi
}
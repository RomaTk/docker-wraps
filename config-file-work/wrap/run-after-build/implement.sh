#!/bin/bash

function implementSpecificData {
    local run_before_builds="$1"
    local all_run_before_builds="$2"
    local type="$3"
    local wrap_name="$4"

    if [[ "$type" == "object" ]]; then
        all_run_before_builds=$(implementObject)
        if [ $? -ne 0 ]; then
            echo "Error in implementing object $all_run_before_builds" >&2
            exit 1
        fi
    elif [[ "$type" == "string" ]]; then
        all_run_before_builds=$(implementString)
        if [ $? -ne 0 ]; then
            echo "Error in implementing string" >&2
            exit 1
        fi
    else
        echo "Unknown type" >&2
        exit 1
    fi

    echo "$all_run_before_builds"
    exit 0
}

function implementString {
    local is_key_exists
    local array_by_key

    is_key_exists=$(echo "$all_run_before_builds" | jq -r "has(\"$wrap_name\")")
    [ $? -ne 0 ] && exit 1

    if [[ "$is_key_exists" == "false" ]]; then
        array_by_key="[]"
    else
        array_by_key=$(echo "$all_run_before_builds" | jq -r ".\"$wrap_name\"")
        [ $? -ne 0 ] && exit 1
    fi

    array_by_key=$(echo "$array_by_key" | jq -r ". + [ \"${run_before_builds//\"/\\\"}\" ]")
    [ $? -ne 0 ] && exit 1

    all_run_before_builds=$(echo "$all_run_before_builds" | jq -r ".\"$wrap_name\" = $array_by_key ")
    [ $? -ne 0 ] && exit 1
    
    echo "$all_run_before_builds"
    exit 0
}

function implementObject {
    local type
    local key

    local action
    local value
    local basedOnScope

    local is_key_exists
    local array_by_key

    local length_of_array

    local extracted_data
    local action_type
    local value_type
    local basedOnScope_type

    extracted_data=$(echo "$run_before_builds" | jq -r '[.action, (.action | type), .value, (.value | type), .basedOnScope, (.basedOnScope | type)] | @tsv')
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting keys" >&2
        exit 1
    fi

    IFS=$'\t' read -r action action_type value value_type basedOnScope basedOnScope_type <<< "$extracted_data"

    if [[ "$action_type" != "string" || "$value_type" != "string" || "$basedOnScope_type" != "string" ]]; then
        echo "Type is not a string" >&2
        exit 1
    fi


    case $action in
        "add")
            all_run_before_builds=$(implementSpecificData "$value" "$all_run_before_builds" "string" "$basedOnScope")
            if [ $? -ne 0 ]; then
                echo "Unknown error in implementing string with implementRunAfterBuild function" >&2
                exit 1
            fi
            ;;
        "remove")
            is_key_exists=$(echo "$all_run_before_builds" | jq -r "has(\"$basedOnScope\")")
            [ $? -ne 0 ] && exit 1

            if [[ "$is_key_exists" == "false" ]]; then
                echo "$all_run_before_builds"
                exit 0
            fi

            array_by_key=$(echo "$all_run_before_builds" | jq -r ".\"$basedOnScope\"")
            [ $? -ne 0 ] && exit 1

            array_by_key=$(echo "$array_by_key" | jq -r ". - [ \"${value//\"/\\\"}\" ]")
            [ $? -ne 0 ] && exit 1

            length_of_array=$(echo "$array_by_key" | jq -r 'length')
            [ $? -ne 0 ] && exit 1

            if [[ "$length_of_array" -eq 0 ]]; then
                all_run_before_builds=$(echo "$all_run_before_builds" | jq -r "del(.\"$basedOnScope\")")
                [ $? -ne 0 ] && exit 1
            else
                all_run_before_builds=$(echo "$all_run_before_builds" | jq -r ".\"$basedOnScope\" = $array_by_key ")
                [ $? -ne 0 ] && exit 1
            fi
            ;;
        *)
            echo "Unknown action" >&2
            exit 1
            ;;
    esac

    echo "$all_run_before_builds"
    exit 0
}
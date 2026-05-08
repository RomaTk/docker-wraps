#!/bin/bash

function implementSpecificData {
    local object_option="$1"
    local options="$2"
    local type="$3"

    if [[ "$type" == "object" ]]; then
        options=$(implementObject)
        if [ $? -ne 0 ]; then
            echo "Error in implementing object" >&2
            exit 1
        fi
    elif [[ "$type" == "string" ]]; then
        options=$(implementString)
        if [ $? -ne 0 ]; then
            echo "Error in implementing string" >&2
            exit 1
        fi
    else
        echo "Unknown type" >&2
        exit 1
    fi

    echo "$options"
    exit 0
}

function implementString {
    options=$(echo "$options" | jq -r ". + [ {
        value: \"${object_option//\"/\\\"}\",
        continueInError: false
    } ]")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    echo "$options"
    exit 0
}

function implementObject {
    local type
    local key

    local action
    local value
    local continue_in_error

    local parsed_data
    parsed_data=$(echo "$object_option" | jq -r '[ (.action | type), (.value | type), (.continueInError | type), .action, .value, (.continueInError | tostring) ] | @sh')
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting object properties" >&2
        exit 1
    fi

    eval "local arr=($parsed_data)"

    local type_action="${arr[0]}"
    local type_value="${arr[1]}"
    local type_continue="${arr[2]}"
    action="${arr[3]}"
    value="${arr[4]}"
    continue_in_error="${arr[5]}"

    if [[ "$type_action" != "string" || "$type_value" != "string" ]]; then
        echo "Type is not a string" >&2
        exit 1
    fi

    if [[ "$type_continue" != "boolean" && "$type_continue" != "null" ]]; then
        echo "Type of continueInError is not a boolean and not null" >&2
        exit 1
    fi

    if [[ "$continue_in_error" == "null" ]]; then
        continue_in_error="null" # it's already "null" string from tostring, but keeping it conceptually clear
    fi


    case $action in
        "add")
            if [[ "$continue_in_error" == "null" ]]; then
                continue_in_error="false"
            fi
            options=$(echo "$options" | jq -r ". + [ {
                value: \"${value//\"/\\\"}\",
                continueInError: $continue_in_error
            } ]")
            if [ $? -ne 0 ]; then
                echo "Unknown error in adding action" >&2
                exit 1
            fi
            ;;
        "remove")
            if [[ "$continue_in_error" == "null" ]]; then
                options=$(echo "$options" | jq -r ". - [ {
                    value: \"${value//\"/\\\"}\",
                    continueInError: true
                } ]")
                if [ $? -ne 0 ]; then
                    echo "Unknown error in removing action" >&2
                    exit 1
                fi
                options=$(echo "$options" | jq -r ". - [ {
                    value: \"${value//\"/\\\"}\",
                    continueInError: false
                } ]")
                if [ $? -ne 0 ]; then
                    echo "Unknown error in removing action" >&2
                    exit 1
                fi
            else
                options=$(echo "$options" | jq -r ". - [ {
                    value: \"${value//\"/\\\"}\",
                    continueInError: $continue_in_error
                } ]")
                if [ $? -ne 0 ]; then
                    echo "Unknown error in removing action" >&2
                    exit 1
                fi
            fi
            ;;
        *)
            echo "Unknown action" >&2
            exit 1
            ;;
    esac

    echo "$options"
    exit 0
}
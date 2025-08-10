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

    for key in "action" "value"; do
        type=$(echo "$object_option" | jq -r ".$key | type")
        if [ $? -ne 0 ]; then
            echo "Unknown error in extracting key type" >&2
            exit 1
        fi

        if [[ "$type" != "string" ]]; then
            echo "Type is not a string" >&2
            exit 1
        fi
    done

    key="continueInError"
    type=$(echo "$object_option" | jq -r ".$key | type")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting key type" >&2
        exit 1
    fi
    if [[ "$type" != "boolean" && "$type" != "null" ]]; then
        echo "Type of $key is not a boolean and not null" >&2
        exit 1
    fi
    continue_in_error=$(echo "$object_option" | jq -r ".$key")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting key value" >&2
        exit 1
    fi

    action=$(echo "$object_option" | jq -r ".action")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting key value" >&2
        exit 1
    fi

    value=$(echo "$object_option" | jq -r ".value")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting key value" >&2
        exit 1
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
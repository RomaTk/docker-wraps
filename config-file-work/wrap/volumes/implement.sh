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
    else
        echo "Unknown type" >&2
        exit 1
    fi

    echo "$options"
    exit 0
}

function implementObject {
    local length_array
    local i
    local checked_option
    local checked_option_destination
    local object_option_destination
    local is_was_merged

    (checkObjectTypes) 
    if [ $? -ne 0 ]; then
        echo "Error in checking object types" >&2
        exit 1
    fi

    object_option_destination=$(echo "$object_option" | jq -r ".destination")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting destination" >&2
        exit 1
    fi

    length_array=$(echo "$options" | jq -r "length")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting array length" >&2
        exit 1
    fi

    is_was_merged="false"
    for (( i=0; i<length_array; i++ )); do
        checked_option=$(echo "$options" | jq -r ".[$i]")
        if [ $? -ne 0 ]; then
            echo "Unknown error in extracting array element" >&2
            exit 1
        fi

        checked_option_destination=$(echo "$checked_option" | jq -r ".destination")
        if [ $? -ne 0 ]; then
            echo "Unknown error in extracting destination" >&2
            exit 1
        fi

        if [[ "$object_option_destination" != "$checked_option_destination" ]]; then
            continue
        fi
        is_was_merged="true"

        object_option=$(echo "$checked_option $object_option" | jq -r -s add)
        if [ $? -ne 0 ]; then
            echo "Unknown error in merging objects" >&2
            exit 1
        fi

        options=$(echo "$options" | jq -r ".[$i] = $object_option")
        if [ $? -ne 0 ]; then
            echo "Unknown error in replacing object" >&2
            exit 1
        fi

        break
    done

    if [[ "$is_was_merged" == "false" ]]; then
        options=$(echo "$options" | jq -r ". += [$object_option]")
        if [ $? -ne 0 ]; then
            echo "Unknown error in adding object" >&2
            exit 1
        fi
    fi

    echo "$options"
    exit 0
}

function checkObjectTypes {
    local type
    local is_exist
    local key

    for key in "readonly" "nocopy"; do
        is_exist=$(echo "$object_option" | jq -r "has(\"$key\")")
        if [ $? -ne 0 ]; then
            echo "Unknown error in checking key existence" >&2
            exit 1
        fi

        if [[ "$is_exist" == "false" ]]; then
            continue
        fi

        type=$(echo "$object_option" | jq -r ".$key | type")
        if [ $? -ne 0 ]; then
            echo "Unknown error in extracting key type" >&2
            exit 1
        fi

        if [[ "$type" != "boolean" ]]; then
            echo "Type is not a boolean" >&2
            exit 1
        fi
    done

    type=$(echo "$object_option" | jq -r ".destination | type")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting key type" >&2
        exit 1
    fi

    if [[ "$type" != "string" ]]; then
        echo "Type is not a string" >&2
        exit 1
    fi

    is_exist=$(echo "$object_option" | jq -r "has(\"source\")")
    if [ $? -ne 0 ]; then
        echo "Unknown error in checking key existence" >&2
        exit 1
    fi

    if [[ "$is_exist" == "false" ]]; then
        echo "Source key does not exist" >&2
        exit 1
    fi

    type=$(echo "$object_option" | jq -r ".source | type")
    if [ $? -ne 0 ]; then
        echo "Unknown error in extracting key type" >&2
        exit 1
    fi

    if [[ "$type" != "string" && "$type" != "null" ]]; then
        echo "Type is nor a string nor null" >&2
        exit 1
    fi

    exit 0   
}
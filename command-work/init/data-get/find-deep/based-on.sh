#!/bin/bash

function getData {
    local based_on_data
    local based_on_is_precreate
    local based_on_as_abstract
    local based_on_name
    local based_on_tag


    source "$config_dir/wrap/based-on/main.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    based_on_data=$(getBasedOn "$wrap")
    [ $? -ne 0 ] && throwError 117 "$based_on_data"

    if [[ -z "$based_on_data" ]]; then
        echo "null"
        exit 0
    fi

    source "$config_dir/wrap/based-on/as-abstract.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    based_on_as_abstract=$(getAsAbstract "$based_on_data")
    [ $? -ne 0 ] && throwError 136 "$based_on_as_abstract"

    if [[ "$based_on_as_abstract" == "true" ]]; then
        exit 2
    fi
    
    source "$config_dir/wrap/based-on/name.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    source "$config_dir/wrap/based-on/tag.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    source "$config_dir/wrap/based-on/is-precreate.sh"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    based_on_name=$(getBasedOnName "$based_on_data")
    [ $? -ne 0 ] && throwError 119 "$based_on_name"

    based_on_tag=$(getBasedOnTag "$based_on_data")
    [ $? -ne 0 ] && throwError 125 "$based_on_tag"

    based_on_is_precreate=$(getIsPrecreate "$based_on_data")
    [ $? -ne 0 ] && throwError 118 "$based_on_is_precreate"

    echo "{\"name\": \"$based_on_name\", \"tag\": \"$based_on_tag\", \"precreate\": \"$based_on_is_precreate\"}"

    exit 0
}
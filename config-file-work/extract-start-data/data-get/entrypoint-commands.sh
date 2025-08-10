#!/bin/bash

function getEntrypointCommands {
    local current_main_dir="$1"
    local config_dir="$2"
    local common_utils_dir="$3"
    local file_with_config="$4"
    local wrap_name="$5"

    local options="[]"

    local file_to_source

    local wrap
    local based_on
    local is_precreate
    local is_in_array
    
    local len
    local i
    
    local based_ons=()

    file_to_source="$current_main_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    file_to_source="$config_dir/find-wrap.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/is-precreate.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/name.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$common_utils_dir/is-in-array.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$common_utils_dir/get-implement-specific-data.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    based_ons+=("$wrap_name")

    while true; do 
        
        wrap=$(findWrap "$file_with_config" "$wrap_name")
        [ $? -ne 0 ] && throwError 115 "$wrap"

        if [[ -z "$wrap" ]]; then
            throwError 116 "Was looking for wrap with name \"$wrap_name\""
        fi

        based_on=$(getBasedOn "$wrap")
        [ $? -ne 0 ] && throwError 117 "$based_on"

        if [[ -z "$based_on" ]]; then
            break
        fi

        is_precreate=$(getIsPrecreate "$based_on")
        [ $? -ne 0 ] && throwError 118 "$is_precreate"

        if [[ "$is_precreate" == "false" ]]; then
            break
        fi

        wrap_name=$(getBasedOnName "$based_on")
        [ $? -ne 0 ] && throwError 119 "$wrap_name"

        is_in_array=$(checkIsInArray "$wrap_name" "${based_ons[@]}")
        [ $? -ne 0 ] && throwError 113 "$is_in_array"

        if [[ "$is_in_array" == "true" ]]; then
            throwError 114
        fi

        based_ons+=("$wrap_name")

    done

    len=${#based_ons[@]}

    # Loop through the array in reverse order
    for (( i=$len-1; i>=0; i-- )); do
        options=$(getImplementSpecificData "${based_ons[$i]}" "$options" "$file_with_config" "$config_dir" "entrypoint-commands")
        [ $? -ne 0 ] && throwError 149 "$options"
    done
   
   echo "$options"

   exit 0
}
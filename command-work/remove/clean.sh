function clean {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"

    local config_dir="$scripts_dir/config-file-work"

    local wrap
    local clean_array
    local length
    local command
    local items_array

    file_to_source="$config_dir/find-wrap.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/get-clean.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    wrap=$(findWrap "$file_with_config" "$wrap_name")
    [ $? -ne 0 ] && throwError 118 "$wrap"

    if [[ -z "$wrap" ]]; then
        throwError 124 "Wrap \"$wrap_name\" not found"
    fi

    clean_array=$(getClean "$wrap")
    [ $? -ne 0 ] && throwError 119 "$clean_array"

    if [[ -z "$clean_array" ]]; then
        exit 0
    fi

    length=$(echo "$clean_array" | jq -r 'length')
    [ $? -ne 0 ] && throwError 120 "$length"

    if [[ $length -eq 0 ]]; then
        exit 0
    fi

    echo "Cleaning wrap \"$wrap_name\""

    eval "items_array=($(echo "$clean_array" | jq -e -r '.[] | @sh'))"
    [ $? -ne 0 ] && throwError 120 "Error getting commands"

    for command in "${items_array[@]}"; do
        echo "CLEAN commnand: $command"
        (eval "$command")
        [ $? -ne 0 ] && throwError 121 "$command"
    done

    exit 0
}
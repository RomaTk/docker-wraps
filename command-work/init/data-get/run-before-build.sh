#!/bin/bash

function getRunBeforeBuild {
    local current_main_dir="$1"
    local config_dir="$2"
    local common_utils_dir="$3"
    local file_with_config="$4"
    local wrap_name="$5"

    local all_run_before_builds="{}"

    local file_to_source

    local wrap
    local based_on
    local is_precreate
    local is_in_array
    local tag
    local as_abstract
    
    local len
    local i
    
    local based_ons=()
    local is_abstract=()

    local based_on_jq_array="[]"
    local is_abstract_jq_array="[]"
    local abstract_jq_array_commands="[]"
    local abstract_jq_array_commands_some_wrap
    local current_object

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

    file_to_source="$config_dir/wrap/based-on/as-abstract.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/name.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$config_dir/wrap/based-on/tag.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$common_utils_dir/is-in-array.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$common_utils_dir/get-implement-specific-data.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    based_ons+=("$wrap_name")
    is_abstract+=("false")

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

        tag=$(getBasedOnTag "$based_on")
        [ $? -ne 0 ] && throwError 125 "$tag"

        if [[ "$tag" != "latest" ]]; then
            break
        fi

        as_abstract=$(getAsAbstract "$based_on")
        [ $? -ne 0 ] && throwError 136 "$as_abstract"

        based_ons+=("$wrap_name")
        is_abstract+=("$as_abstract")

    done

    len=${#based_ons[@]}

    # Loop through the array in reverse order
    for (( i=$len-1; i>=0; i-- )); do
        all_run_before_builds=$(getImplementSpecificData "${based_ons[$i]}" "$all_run_before_builds" "$file_with_config" "$config_dir" "run-before-build")
        [ $? -ne 0 ] && throwError 149 "$all_run_before_builds"

        based_on_jq_array=$(echo "$based_on_jq_array" | jq -r ". + [\"${based_ons[$i]}\"]")
        [ $? -ne 0 ] && throwError 152 "$based_on_jq_array"

    done

    # Resolve abstracts
    for (( i=$len-1; i>=0; i-- )); do
        as_abstract=${is_abstract[$i]}
        wrap_name=${based_ons[$i]}

        if [[ "$as_abstract" == "true" ]]; then

            abstract_jq_array_commands_some_wrap=$(echo "$all_run_before_builds" | jq -r ".\"$wrap_name\"")
            [ $? -ne 0 ] && exit 1
            if [[ "$abstract_jq_array_commands_some_wrap" != "null" ]]; then
                abstract_jq_array_commands=$(echo "$abstract_jq_array_commands" | jq -r ". + $abstract_jq_array_commands_some_wrap")
                [ $? -ne 0 ] && exit 1
            fi

            all_run_before_builds=$(echo "$all_run_before_builds" | jq -r "del(.\"$wrap_name\")")
            [ $? -ne 0 ] && exit 1

            based_on_jq_array=$(echo "$based_on_jq_array" | jq -r ". - [\"$wrap_name\"]")
            [ $? -ne 0 ] && exit 1

            continue
        fi

        if [[ "$abstract_jq_array_commands" == "[]" ]]; then
            continue
        fi

        current_object=$(echo "$all_run_before_builds" | jq -r ".\"$wrap_name\"")
        [ $? -ne 0 ] && exit 1

        if [[ "$current_object" == "null" ]]; then
            all_run_before_builds=$(echo "$all_run_before_builds" | jq -r ".\"$wrap_name\" = $abstract_jq_array_commands")
            [ $? -ne 0 ] && exit 1
        else
            current_object=$(echo "$current_object" | jq -r "$abstract_jq_array_commands + .")
            [ $? -ne 0 ] && exit 1

            all_run_before_builds=$(echo "$all_run_before_builds" | jq -r ".\"$wrap_name\" = $current_object")
            [ $? -ne 0 ] && exit 1
        fi

        abstract_jq_array_commands="[]"

    done

    echo "{ \"basedOnList\": $based_on_jq_array, \"data\": $all_run_before_builds }"

    exit 0
}


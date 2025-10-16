#!/bin/bash

function init {
    local scripts_dir="$1"
    local file_with_config="$2"
    local unique_prefix="$3"
    local wrap_name="$4"
    local run_before_build="$5"
    local run_after_build="$6"

    local common_utils_dir="$scripts_dir/common-utils"
    local current_dir="$scripts_dir/command-work/init"
    local config_dir="$scripts_dir/config-file-work"
    local file_to_source    

    local initial_wrap_name="$wrap_name"

    local this_wrap_data
    local based_ons=()
    local wrap
    local based_on
    local is_precreate
    local is_in_array
    local some_wrap_data
    local exit_code
    local rename_with

    local final_command

    local type
    local tag
    local based_on_line
    local build_options
    local context

    # Checking that I can use previously created build
    local to_rename

    # These values is used to compare can i safely make build, if based on was changed
    local current_wrap_before_build
    local run_before_build_compare_1
    local run_before_build_compare_2
    local run_after_build_compare_2

    local cropped_run_before_build
    local is_only_run_this_run_before_build="false"
    local is_to_run_in_the_end="false"

    local was_image_id
    local now_image_id

    file_to_source="$current_dir/utils.sh"
    source "$file_to_source"
    if [ $? -ne 0 ]; then
        echo "Problem with sourcing $file_to_source" >&2
        exit 111
    fi

    # import all necessary functions
    file_to_source="$current_dir/run-before-build.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$current_dir/run-after-build.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"
    
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

    file_to_source="$config_dir/wrap/based-on/tag.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$common_utils_dir/is-in-array.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    this_wrap_data=$(getDataForBuild "$wrap_name")
    [ $? -ne 0 ] && throwError 131 "$this_wrap_data"

    if [ -z "$run_before_build" ]; then
        run_before_build=$(getRunBeforeBuildInit "$wrap_name")
        [ $? -ne 0 ] && throwError 150 "$run_before_build"
    
        run_after_build=$(getRunAfterBuildInit "$wrap_name")
        [ $? -ne 0 ] && throwError 158 "$run_after_build"

        run_before_build=$(insertRunAfterBuildToRunBeforeBuild "$run_after_build" "$run_before_build")
        [ $? -ne 0 ] && throwError 166 "$run_before_build"

        is_to_run_in_the_end="true"
    fi

    based_ons+=("$wrap_name")

    to_rename="false"

    # Here is while loop, just to use break
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

        some_wrap_data=$(getDataForBuild "$wrap_name")
        exit_code=$?

        case $exit_code in
            124)
                break
                ;;
            0)
                ;;
            *)
                throwError 131 "$some_wrap_data"
                ;;
        esac

        if [[ "$this_wrap_data" != "$some_wrap_data" ]]; then
            break;
        fi

        current_wrap_before_build=$(echo "$run_before_build" | jq -r ".data.\"$initial_wrap_name\"")
        [ $? -ne 0 ] && throwError 1

        if [[ "$current_wrap_before_build" != "null" ]]; then
            break;
        fi

        run_before_build_compare_1=$(removeSomeWrapFromRunBeforeBuild "$run_before_build" "$initial_wrap_name")
        [ $? -ne 0 ] && throwError 153 "$run_before_build_compare_1"

        run_before_build_compare_2=$(getRunBeforeBuildInit "$wrap_name")
        [ $? -ne 0 ] && throwError 150 "$run_before_build_compare_2"

        run_after_build_compare_2=$(getRunAfterBuildInit "$wrap_name")
        [ $? -ne 0 ] && throwError 158 "$run_after_build_compare_2"
        run_before_build_compare_2=$(insertRunAfterBuildToRunBeforeBuild "$run_after_build_compare_2" "$run_before_build_compare_2")
        [ $? -ne 0 ] && throwError 166 "$run_before_build_compare_2"

        run_before_build_compare_1=$(echo "$run_before_build_compare_1" | jq -S -r ".data")
        [ $? -ne 0 ] && throwError 1 "$run_before_build_compare_1"
        run_before_build_compare_2=$(echo "$run_before_build_compare_2" | jq -S -r ".data")
        [ $? -ne 0 ] && throwError 1 "$run_before_build_compare_2"


        if [[ "$run_before_build_compare_1" == "$run_before_build_compare_2" ]]; then
            to_rename="true"
            rename_with="$wrap_name"
            break
        fi

    done

    if [[ "$to_rename" == "true" ]]; then
        cropped_run_before_build=$(removeSomeWrapFromRunBeforeBuild "$run_before_build" "$initial_wrap_name")
        [ $? -ne 0 ] && throwError 153 "$cropped_run_before_build"

        is_only_run_this_run_before_build="true"

        (init "$scripts_dir" "$file_with_config" "$unique_prefix" "$rename_with" "$cropped_run_before_build" "$run_after_build")
        exit_code=$?
        [ $exit_code -ne 0 ] && throwError 132 "Exit code was: $exit_code"
    
        final_command=$(renameImageCreateCommandString)
        [ $? -ne 0 ] && throwError 169 "$final_command"
    else
        type=$(echo "$this_wrap_data" | jq -r ".basedOn | type")
        [ $? -ne 0 ] && throwError 137 "$type"

        if [[ "$type" == "object" ]]; then

            based_on=$(echo "$this_wrap_data" | jq -r ".basedOn")
            [ $? -ne 0 ] && throwError 140 "$based_on"

            wrap_name=$(echo "$based_on" | jq -r ".name")
            [ $? -ne 0 ] && throwError 139 "$wrap_name"

            tag=$(echo "$based_on" | jq -r ".tag")
            [ $? -ne 0 ] && throwError 137 "$tag"

            is_precreate=$(echo "$based_on" | jq -r ".precreate")
            [ $? -ne 0 ] && throwError 138 "$is_precreate"

            based_on_line="$wrap_name:$tag"
            if [[ "$is_precreate" == "true" ]]; then
                based_on_line="$unique_prefix/$based_on_line"
            fi
            
            if [[ "$is_precreate" == "true" && "$tag" == "latest" ]]; then

                cropped_run_before_build=$(removeSomeWrapFromRunBeforeBuild "$run_before_build" "$initial_wrap_name")
                [ $? -ne 0 ] && throwError 153 "$cropped_run_before_build"

                is_only_run_this_run_before_build="true"

                (init "$scripts_dir" "$file_with_config" "$unique_prefix" "$wrap_name" "$cropped_run_before_build" "$run_after_build")
                exit_code=$?
                [ $exit_code -ne 0 ] && throwError 132 "Exit code was: $exit_code"
            fi

        fi

        build_options=$(echo "$this_wrap_data" | jq -r ".buildOptions")
        [ $? -ne 0 ] && throwError 141 "$build_options"

        context=$(echo "$this_wrap_data" | jq -r ".context")
        [ $? -ne 0 ] && throwError 142 "$context"

        if [[ -n "$based_on_line" ]]; then
            based_on_line="--build-arg BASED_ON=\"$based_on_line\""
        fi

        final_command=$(buildImageCreateCommandString)
        [ $? -ne 0 ] && throwError 170 "$final_command"
    fi


    file_to_source="$current_dir/get-current-image-id.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    was_image_id=$(getCurrentImageId)
    [ $? -ne 0 ] && throwError 172 "$was_image_id"

    (runBeforeBuildDo)
    [ $? -ne 0 ] && throwError 155

    echo "BUILD COMMAND: $final_command"
    (eval "$final_command")
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 133 "Exit code was: $exit_code"

    (runAfterBuildDo)
    [ $? -ne 0 ] && throwError 167

    now_image_id=$(getCurrentImageId)
    [ $? -ne 0 ] && throwError 172 "$now_image_id"

    (removeImage)
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 176 "Exit code was: $exit_code"

    exit 0
}

function removeImage {
    local image_info
    local remove_image_command
    local exit_code

    if [[ -z "$was_image_id" ]]; then
        exit 0
    fi

    if [[ "$was_image_id" == "$now_image_id" ]]; then
        exit 0
    fi

    image_info=$(docker image inspect "$was_image_id" 2>/dev/null)

    if [[ "$image_info" == "[]" ]]; then
        exit 0
    fi

    # Check is image dungling
    image_info=$(docker image inspect --format='{{.RepoTags}} {{.RepoDigests}}' "$was_image_id")
    [ $? -ne 0 ] && throwError 174 "$image_info"

    if [[ "$image_info" != "[] []" ]]; then
        exit 0
    fi

    (
        local file_to_source="$scripts_dir/command-work/remove/main.sh"
        source "$file_to_source"
        if [ $? -ne 0 ]; then
            throwError 111 "$file_to_source"
        fi

        remove "$scripts_dir" "$file_with_config" "$unique_prefix" "$initial_wrap_name" "container"
    )
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        throwError 175 "Exit code was: $exit_code"
    fi

    remove_image_command="docker image rm --force \"$was_image_id\""
    echo "REMOVE COMMAND: $remove_image_command"
    (eval "$remove_image_command")
    exit_code=$?
    [ $exit_code -ne 0 ] && throwError 173 "Exit code was: $exit_code"
    
    exit 0
}

function renameImageCreateCommandString {
    local file_to_source
    local source_image
    local target_image

    file_to_source="$scripts_dir/command-work/get-name/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    source_image=$(getName "$unique_prefix" "$rename_with" "image")
    [ $? -ne 0 ] && throwError 168 "$source_image"
    target_image=$(getName "$unique_prefix" "$initial_wrap_name" "image")
    [ $? -ne 0 ] && throwError 168 "$source_image"


    echo "docker tag \"${source_image}\" \"${target_image}\""
    exit 0
}

function buildImageCreateCommandString {
    local file_to_source
    local image_name

    file_to_source="$scripts_dir/command-work/get-name/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    image_name=$(getName "$unique_prefix" "$initial_wrap_name" "image")
    [ $? -ne 0 ] && throwError 168 "$image_name"

    echo "docker build -t \"${image_name}\" $build_options $based_on_line \"$context\""
    exit 0
}

function getDataForBuild {
    local wrap_name="$1"
    local file_to_source

    local dockerfile
    local context
    local based_on
    local build_options
    
    local build_options_string

    # find deep
    file_to_source="$common_utils_dir/find-deep.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    file_to_source="$common_utils_dir/path-convert.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    context=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/context.sh")
    [ $? -ne 0 ] && throwError 121 "$context"

    if [[ -z "$context" ]]; then
        echo "Context could not be empty"
        throwError 124 
    fi

    context=$(abspath "$context")
    [ $? -ne 0 ] && throwError 135 "$context"

    dockerfile=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/file.sh")
    [ $? -ne 0 ] && throwError 121 "$dockerfile"

    if [[ -n "$dockerfile" ]]; then
        dockerfile=$(abspath "$dockerfile")
        [ $? -ne 0 ] && throwError 135 "$dockerfile"
    fi

    based_on=$(findDeep "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$current_dir/data-get/find-deep/based-on.sh")
    [ $? -ne 0 ] && throwError 121 "$based_on"

    file_to_source="$current_dir/data-get/build-options.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    build_options=$(getBuildOptions "$current_dir" "$config_dir" "$common_utils_dir" "$file_with_config" "$wrap_name" "$dockerfile")
    [ $? -ne 0 ] && throwError 130 "$build_options"

    build_options_string=$(echo "$build_options" | jq 'join(" ")')
    [ $? -ne 0 ] && throwError 134 "$build_options_string"

    echo "{ \"buildOptions\": "$build_options_string", \"context\": \"$context\", \"basedOn\": $based_on }"
    exit 0
}
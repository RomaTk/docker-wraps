function getCurrentImageId {
    local file_to_source
    local image_name
    local image_id_from_image
   

    file_to_source="$scripts_dir/command-work/get-name/main.sh"
    source "$file_to_source"
    [ $? -ne 0 ] && throwError 111 "$file_to_source"

    image_name=$(getName "$unique_prefix" "$initial_wrap_name" "image")
    [ $? -ne 0 ] && throwError 168 "$image_name"

    image_info=$(docker image inspect "$image_name" 2>/dev/null)

    if [ "$image_info" == "[]" ]; then
        exit 0
    fi

    image_id_from_image=$(docker image inspect --format='{{.Id}}' "$image_name")
    [ $? -ne 0 ] && throwError 171 "$image_id_from_image"

    echo "$image_id_from_image"

    exit 0
}
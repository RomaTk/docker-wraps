function getName {
    local unique_prefix="$1"
    local wrap_name="$2"
    local type="$3"

    if [ -z "$unique_prefix" ] || [ -z "$wrap_name" ]; then
        echo "Unique prefix or wrap name is empty" >&2
        exit 1
    fi

    case $type in
        "container")
            getContainerName
            ;;
        "image")
            getImageName
            ;;
        *)
            echo "Unknown type: $type" >&2
            exit 1
            ;;
    esac
    
    exit 0
}

function getContainerName {
    echo "${unique_prefix}-${wrap_name}"
}

function getImageName {
    echo "${unique_prefix}/${wrap_name}:latest"
}
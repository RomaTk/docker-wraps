#!/bin/bash

function throwError {
    local error_code="$1"
    local more_about_error="$2"
    if [ ! -z "$more_about_error" ]; then
        echo "$more_about_error" | while IFS= read -r line; do
            echo "$line" >&2
        done
    fi

    case $error_code in
        1)
            echo "<- Error within jq command" >&2
            ;;
        111)
            echo "<- Problem with sourcing" >&2
            ;;
        123)
            echo "<- Problem within getAllWrapNames function" >&2
            ;;
        124)
            echo "<- Problem within calcWeight function" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}

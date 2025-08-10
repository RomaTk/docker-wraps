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
        111)
            echo "<- Problem with sourcing" >&2
            ;;
        112)
            echo "Unique prefix or wrap name is empty" >&2
            ;;
        113)
            echo "Failed to get container name" >&2
            ;;
        114)
            echo "Error within stopOrKill function" >&2
            ;;
        115)
            echo "Error within \"docker container rm\" command" >&2
            ;;
        116)
            echo "Failed to get image name" >&2
            ;;
        117)
            echo "Error within \"docker image rm\" command" >&2
            ;;
        118)
            echo "Failed to get wrap with findWrap function" >&2
            ;;
        119)
            echo "Failed to get clean array with getClean function" >&2
            ;;
        120)
            echo "Problem with extracting length of clean array" >&2
            ;;
        121)
            echo "Error while executing some clean command" >&2
            ;;
        122)
            echo "Error within isToDoClean function" >&2
            ;;
        123)
            echo "Error during clean process" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
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
            echo "<- Problem within getSequence function" >&2
            ;;
        113)
            echo "<- Problem with creating file" >&2
            ;;
        114)
            echo "<- Problem within getBasedOnName function" >&2
            ;;
        115)
            echo "<- Problem within findWrap function" >&2
            ;;
        116)
            echo "No wrap found" >&2
            ;;
        117)
            echo "<- Problem within changeWrap function" >&2
            ;;
        118)
            echo "<- Problem within changeBasedOnInWrap function" >&2
            ;;
        119)
            echo "<- Problem within changeFileWithSequence function" >&2
            ;;
        120)
            echo "No wrap name provided" >&2
            ;;
        121)
            echo "No new file with config provided" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
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
            echo "<- Problem within findWrap function" >&2
            ;;
        113)
            echo "<- Problem within getBasedOn function" >&2
            ;;
        114)
            echo "<- Problem with getSequence function" >&2
            ;;
        115)
            echo "<- Problem with goThrewSequence function" >&2
            ;;
        116)
            echo "<- Problem with getIsPrecreate function" >&2
            ;;
        117)
            echo "<- Problem with getBasedOnName function" >&2
            ;;
        118)
            echo "<- Problem with getBasedOnTag function" >&2
            ;;
        119)
            echo "<- Problem with sortSequence function" >&2
            ;;
        120)
            echo "<- Problem with isInSequenceAlready function" >&2
            ;;
        121)
            echo "<- Problem with addToSequence function" >&2
            ;;
        122)
            echo "No wrap found" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
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
        123)
            echo "<- Problem with finding deep" >&2
            ;;
        124)
            echo "Problem within getDataForStop function" >&2
            ;;
        125)
            echo "Problem within extractStartData function" >&2
            ;;
        126)
            echo "Problem with extracting data from start_data with jq" >&2
            ;;
        127)
            echo "Problem within getAllCommandOptionValues function" >&2
            ;;
        128)
            echo "Problem within getOptions function" >&2
            ;;
        129)
            echo "Problem within findWrap function" >&2
            ;;
        130)
            echo "Problem within getBasedOn function" >&2
            ;;
        131)
            echo "<- No wrap was found with such name" >&2
            ;;
        132)
            echo "Problem within getIsPrecreate function" >&2
            ;;
        133)
            echo "Problem within getBasedOnName function" >&2
            ;;
        134)
            echo "Problem within checkIsInArray function" >&2
            ;;
        135)
            echo "BasedOn is circular" >&2
            ;;
        136)
            echo "Problem within getImplementSpecificData function" >&2
            ;;
        137)
            echo "Problem with findDeep kill signal" >&2
            ;;
        138)
            echo "Problem with getting container name" >&2
            ;;
        139)
            echo "Problem with unpausing container" >&2
            ;;
        140)
            echo "Problem with stopping container" >&2
            ;;
        141)
            echo "Problem with killing container" >&2
            ;;
        142)
            echo "Unnknown type of action" >&2
            ;;
        143)
            echo "Problem within getDataForKill function" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
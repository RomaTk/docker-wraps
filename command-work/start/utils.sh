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
        113)
            echo "Problem within extractStartData function" >&2
            ;;
        114)
            echo "Problem with extracting cmd data" >&2
            ;;
        115)
            echo "Problem with extracting data" >&2
            ;;
        156)
            echo "Problem within isOptionInCommand function" >&2
            ;;
        157)
            echo "Problem within getAllCommandOptionValues function" >&2
            ;;
        158)
            echo "<- Problem within checking option from run command" >&2
            ;;
        159)
            echo "Problem within getCommandForStart function" >&2
            ;;
        160)
            echo "Problem within getCommandForExec function" >&2
            ;;
        161)
            echo "It is impossible to simulte start command with running container without mentioning entrypoint as run option" >&2
            ;;
        163)
            echo "Problem within runnung docker command function" >&2
            ;;
        164)
            echo "Problem within docker unpause function" >&2
            ;;
        165)
            echo "Problem with getting container name" >&2
            ;;
        166)
            echo "Error within init function" >&2
            ;;
        167)
            echo "Problem with getting image name" >&2
            ;;
        168)
            echo "Problem with getting image id from image name" >&2
            ;;
        169)
            echo "Problem with getting image id from container" >&2
            ;;
        170)
            echo "Problem within isSameImageId function" >&2
            ;;
        171)
            echo "Problem within removing container" >&2
            ;;
        172)
            echo "Problem within statt in recursion" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
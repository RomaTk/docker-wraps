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
            echo "Command is not mentioned" >&2
            ;;
        113)
            echo "<- Unknown command" >&2
            ;;
        114)
            echo "Problem with init command" >&2
            ;;
        115)
            echo "Problem with start command" >&2
            ;;
        116)
            echo "Problem within getUniquePrefix function" >&2
            ;;
        117)
            echo "Problem with getName command" >&2
            ;;
        118)
            echo "Problem with stop command" >&2
            ;;
        119)
            echo "Not mentioned command" >&2
            ;;
        120)
            echo "Icorrect length of command arguments" >&2
            ;;
        121)
            echo "Can not get mentioned data" >&2
            ;;
        122)
            echo "Problem with remove command" >&2
            ;;
        123)
            echo "Problem with getAllWrapNames function" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
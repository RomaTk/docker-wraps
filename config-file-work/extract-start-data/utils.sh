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
            echo "Problem within checkIsInArray function" >&2
            ;;
        114)
            echo "BasedOn is circular" >&2
            ;;
        115)
            echo "Problem within findWrap function" >&2
            ;;
        116)
            echo "<- No wrap was found with such name" >&2
            ;;
        117)
            echo "Problem within getBasedOn function" >&2
            ;;
        118)
            echo "Problem within getIsPrecreate function" >&2
            ;;
        119)
            echo "Problem within getBasedOnName function" >&2
            ;;
        122)
            echo "Problem within getInteractive function" >&2
            ;;
        123)
            echo "Problem with find deep interactive" >&2
            ;;
        124)
            echo "Error within getVolumes function" >&2
            ;;
        125)
            echo "Problem with find deep stop signal" >&2
            ;;
        126)
            echo "Problem with find deep stop timeout" >&2
            ;;
        127)
            echo "Problem within getOptions function" >&2
            ;;
        135)
            echo "Problem with convering path to absolute one" >&2
            ;;
        149)
            echo "Problem within getImplementSpecificData function" >&2
            ;;
        150)
            echo "Problem within convertVolumesToOptions function" >&2
            ;;
        151)
            echo "Problem within getEntrypoint function" >&2
            ;;
        152)
            echo "Problem within getEntrypointArgs function" >&2
            ;;
        153)
            echo "Problem within getEntrypointCommands function" >&2
            ;;
        154)
            echo "Problem within convertEntrypointValuesToOptions function" >&2
            ;;
        155)
            echo "Problem within getDataForRun function" >&2
            ;;
        156)
            echo "Problem within jq generating object" >&2
            ;;
        162)
            echo "Problem within getCmd function" >&2
            ;;
        163)
            echo "Problem with getting image name" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
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
        117)
            echo "<- Problem with getBasedOnName function" >&2
            ;;
        119)
            echo "<- Problem with sortSequence function" >&2
            ;;
        121)
            echo "<- Problem with removeIsAnalysed function" >&2
            ;;
        122)
            echo "No wrap found" >&2
            ;;
        124)
            echo "<- Problem with changeNewItemsAsAbstractOnly function" >&2
            ;;
        125)
            echo "<- Problem checking basedOn type in getItemsForSequence" >&2
            ;;
        126)
            echo "<- Problem mapping sequence data in goThrewSequence" >&2
            ;;
        127)
            echo "<- Problem setting isAnalysed in goThrewSequence" >&2
            ;;
        128)
            echo "<- Problem concatenating new items in goThrewSequence" >&2
            ;;
        129)
            echo "<- Problem appending single item in goThrewSequence" >&2
            ;;
        130)
            echo "<- Problem setting asAbstract in changeNewItemsAsAbstractOnly" >&2
            ;;
        131)
            echo "<- Problem sorting sequence in sortSequence" >&2
            ;;
        132)
            echo "<- Problem removing isAnalysed in removeIsAnalysed" >&2
            ;;
        133)
            echo "<- Problem sorting by wrap_weights" >&2
            ;;
        134)
            echo "<- Sequence item missing name or name not found in wrap_weights" >&2
            ;;
        135)
            echo "<- Problem with sortByWrapWeights function" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
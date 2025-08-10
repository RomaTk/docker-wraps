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
        120)
            echo "Problem within getDockerfile function" >&2
            ;;
        121)
            echo "Problem within findDeep function" >&2
            ;;
        122)
            echo "Problem within getContext function" >&2
            ;;
        124)
            echo "Incorrect config configuration"
            ;;
        125)
            echo "Problem within getBasedOnTag function" >&2
            ;;
        130)
            echo "Problem within getBuildOptions function" >&2
            ;;
        131)
            echo "Problem within getDataForBuild function" >&2
            ;;
        132)
            echo "Problem within init function" >&2
            ;;
        133)
            echo "Problem within runnung docker command function" >&2
            ;;
        134)
            echo "Problem with converting build options to string" >&2
            ;;
        135)
            echo "Problem with convering path to absolute one" >&2
            ;;
        136)
            echo "Problem within getAsAbstract function" >&2
            ;;
        137)
            echo "Problem with getting type of basedOn with jq" >&2
            ;;
        138)
            echo "Problem with getting precreate of basedOn with jq" >&2
            ;;
        139)
            echo "Problem with getting name of basedOn with jq" >&2
            ;;
        140)
            echo "Problem with getting basedOn with jq" >&2
            ;;
        141)
            echo "Problem with getting buildOptions from wrap data with jq" >&2
            ;;
        142)
            echo "Problem with getting context from wrap data with jq" >&2
            ;;
        143)
            echo "Problem with sorting keys" >&2
            ;;
        148)
            echo "Problem within getRunBeforeBuild function" >&2
            ;;
        149)
            echo "Problem within getImplementSpecificData function" >&2
            ;;
        150)
            echo "Problem within getRunBeforeBuildInit function" >&2
            ;;
        152)
            echo "Problem with moving bash array to jq array" >&2
            ;;
        153)
            echo "Problem withing removeSomeWrapFromRunBeforeBuild function" >&2
            ;;
        154)
            echo "Problem within runBeforeBuildDoForSomeWrap function" >&2
            ;;
        155)
            echo "Problem within runBeforeBuildDo function" >&2
            ;;
        156)
            echo "Problem with running command before build" >&2
            ;;
        157)
            echo "Problem within getRunAfterBuild function" >&2
            ;;
        158)
            echo "Problem within getRunAfterBuildInit function" >&2
            ;;
        159)
            echo "Problem with jq function to extract basedOnList" >&2
            ;;
        161)
            echo "Unexpected problem, basedOnLists aren\`t same" >&2
            ;;
        162)
            echo "Problem with getting basedOnLists length" >&2
            ;;
        163)
            echo "Problem with getting basedOnLists length" >&2
            ;;
        164)
            echo "Problem with getting getting data from run parsed object" >&2
            ;;
        165)
            echo "Problem with getting setting data inside run parsed object" >&2
            ;;
        166)
            echo "Problem within insertRunAfterBuildToRunBeforeBuild function" >&2
            ;;
        167)
            echo "Problem within runAfterBuildDo function" >&2
            ;;
        168)
            echo "Error within getName function" >&2
            ;;
        169)
            echo "Error within renameImageCreateCommandString function" >&2
            ;;
        170)
            echo "Error within buildImageCreateCommandString function" >&2
            ;;
        171)
            echo "Problem with getting image id from image name" >&2
            ;;
        172)
            echo "Problem within getCurrentImageId function" >&2
            ;;
        173)
            echo "Problem with removing image" >&2
            ;;
        174)
            echo "Problem within defining is image dangling" >&2
            ;;
        *)
            echo "Unknown error" >&2
            exit 1
            ;;
    esac

    exit $error_code
}
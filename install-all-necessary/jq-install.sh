#!/bin/bash

function installJq {
    
    sudo apt-get update
    [ $? -ne 0 ] && exit 112
    sudo apt-get install jq -y
    [ $? -ne 0 ] && exit 113
    

    exit 0
}

if command -v jq &> /dev/null; then
    exit 0
else
    installJq
fi

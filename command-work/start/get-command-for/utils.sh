#!/bin/bash

function checkBooleanOption {
    local run_command="$1"
    local option_name="$2"
    local short_option="$3"

    local full_string=""
    local command_option_values
    local is_good_value
    local is_was_some_update="false"
    local is_option_exists


    if [[ -n "$short_option" ]]; then
        command_option_values=$(getAllCommandOptionValues "$short_option" "$run_command")
        [ $? -ne 0 ] && throwError 157 "$command_option_values"

        if [[ -n "$command_option_values" ]]; then
            while IFS= read -r val; do
                is_good_value=$(checkBooleanValue "$val")
                [ $? -ne 0 ] && exit 1
                
                if [[ "$is_good_value" == "false" ]]; then
                    continue
                fi

                full_string="$full_string $short_option=$val"
                is_was_some_update="true"
            done <<< "$command_option_values"
        fi
    fi

    command_option_values=$(getAllCommandOptionValues "$option_name" "$run_command")
    [ $? -ne 0 ] && throwError 157 "$command_option_values"

    if [[ -n "$command_option_values" ]]; then
        while IFS= read -r val; do
            is_good_value=$(checkBooleanValue "$val")
            [ $? -ne 0 ] && exit 1
            
            if [[ "$is_good_value" == "false" ]]; then
                continue
            fi

            full_string="$full_string $option_name=$val"
            is_was_some_update="true"
        done <<< "$command_option_values"
    fi


    if [[ "$is_was_some_update" == "false" ]]; then
        if [[ -n "$short_option" ]]; then
            is_option_exists=$(isOptionInCommand "$short_option" "$run_command")
            [ $? -ne 0 ] && throwError 156 "$is_option_exists"

            if [[ "$is_option_exists" == "true" ]]; then
                echo " $short_option"
                exit 0
            fi
        fi

        is_option_exists=$(isOptionInCommand "$option_name" "$run_command")
        [ $? -ne 0 ] && throwError 156 "$is_option_exists"

        if [[ "$is_option_exists" == "true" ]]; then
            echo " $option_name"
            exit 0
        fi
    fi

    echo "$full_string"
    exit 0
}

function checkNotBooleanOption {
    local run_command="$1"
    local option_name="$2"
    local short_option="$3"
    
    local full_string=""
    local command_option_values

    if [[ -n "$short_option" ]]; then
        command_option_values=$(getAllCommandOptionValues "$short_option" "$run_command")
        [ $? -ne 0 ] && throwError 157 "$command_option_values"

        if [[ -n "$command_option_values" ]]; then
            while IFS= read -r val; do
                full_string="$full_string $short_option $val"
            done <<< "$command_option_values"
        fi
    fi
    

    command_option_values=$(getAllCommandOptionValues "$option_name" "$run_command")
    [ $? -ne 0 ] && throwError 157 "$command_option_values"

    if [[ -n "$command_option_values" ]]; then
        while IFS= read -r val; do
            full_string="$full_string $option_name=$val"
        done <<< "$command_option_values"
    fi

    echo "$full_string"
    exit 0
}

function checkBooleanValue {
    local val="$1"

    if [[ "$val" == "true" || "$val" == "false" 
        || "$val" == "'true'" || "$val" == "'false'"
        || "$val" == '"true"' || "$val" == '"false"' ]]; then
        echo "true"
    else
        echo "false"
    fi

    exit 0
}
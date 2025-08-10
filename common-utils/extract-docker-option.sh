#!/bin/bash

# ---
# Checks if a specific option (flag) is present in a command string.
# Handles exact matches, options with '=', and combined short options (e.g., -i in -it).
#
# @param {string} option_to_find The option to search for (e.g., "--rm", "-d", "-i").
# @param {string} command_string The command string to parse.
# @returns {string} "true" if the option is found, "false" otherwise.
# ---
function isOptionInCommand {
    local option_to_find="$1"
    local command_string="$2"

    # Read the command string into an array for safe handling of arguments.
    read -ra command_args <<< "$command_string"
    [ $? -ne 0 ] && exit 1

    for current_arg in "${command_args[@]}"; do
        # 1. Exact match for the option
        if [[ "$current_arg" == "$option_to_find" ]]; then
            echo "true"
            exit 0
        fi

        # 2. Check for long options with an equals sign (e.g., --option=value)
        # We're checking if the option_to_find is the part before the '='
        if [[ "$option_to_find" == --* ]] && [[ "$current_arg" == "${option_to_find}="* ]]; then
            echo "true"
            exit 0
        fi

        # 3. Handle combined short options (e.g., finding -i in -it)
        # Check if option_to_find is a single short option (e.g., -i, not -it)
        # And if current_arg is a group of short options (e.g., -it, -itd)
        if [[ "$option_to_find" =~ ^-[a-zA-Z0-9]$ ]] && \
           [[ "$current_arg" =~ ^-[a-zA-Z0-9]+$ ]] && \
           [[ "$current_arg" != "$option_to_find" ]]; then # Avoid re-matching exact single options already covered
            # Extract the characters part of option_to_find (e.g., 'i' from '-i')
            local single_opt_char="${option_to_find:1}"
            # Extract the characters part of current_arg (e.g., 'it' from '-it')
            local group_opt_chars="${current_arg:1}"

            if [[ "$group_opt_chars" == *"$single_opt_char"* ]]; then
                echo "true"
                exit 0
            fi
        fi
    done

    # If the loop finishes, the option was not found.
    echo "false"
    exit 0
}

# ---
# Extracts all values for a given option from a command string.
# Handles formats like "--option=value", "--option value", and "-o value".
# If an option is repeated, all its values are returned, each on a new line.
#
# @param {string} option_to_find The option to search for (e.g., "--env" or "-a").
# @param {string} command_string The command string to parse.
# @returns {string} All found values, each on a new line. Empty if none found.
# ---
function getAllCommandOptionValues() {
    local option_to_find="$1"
    local command_string="$2"
    local -a found_values=() # Array to store all found values

    # Read the command string into an array for safe handling of arguments.
    read -ra command_args <<< "$command_string"
    [ $? -ne 0 ] && exit 1

    # Loop through the command arguments with an index.
    for i in "${!command_args[@]}"; do
        local current_arg="${command_args[$i]}"
        local value=""

        # Case 1: Handle --option=value
        if [[ "$current_arg" == "${option_to_find}="* ]]; then
            # Extract the value part after the '='
            value="${current_arg#*=}"
            found_values+=("$value") # Add to our array of values
            continue # Move to the next argument
        fi

        # Case 2: Handle --option value OR -o value
        if [[ "$current_arg" == "$option_to_find" ]]; then
            # The value is the next argument in the array.
            # Check if a next argument exists and it's not another option (heuristic).
            local next_index=$((i + 1))
            if [[ $next_index -lt ${#command_args[@]} ]]; then
                # Check if the next argument looks like an option itself.
                # This is a heuristic: if it starts with '-', it might be another option.
                # For simple cases, we assume it's a value.
                # More robust parsing might require knowing all possible options.
                local potential_value="${command_args[$next_index]}"
                if [[ "$potential_value" != -* ]] || [[ "$potential_value" =~ ^-[0-9]+$ ]]; then # Allow negative numbers as values
                    value="$potential_value"
                    found_values+=("$value")
                    # We don't 'continue' here in case the same option can appear
                    # consecutively, though that's rare for "option value" format.
                    # More commonly, there'd be other args between them.
                    # If we wanted to skip the value we just consumed: i=$((i + 1))
                fi
            fi
        fi
    done

    # Print all found values, each on a new line.
    if [[ ${#found_values[@]} -gt 0 ]]; then
        printf "%s\n" "${found_values[@]}"
    fi

    exit 0
}
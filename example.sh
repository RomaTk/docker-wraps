#!/bin/bash

scripts_dir="here should be path to folder with main code"
file_with_config="here should be path to config file"
source "$scripts_dir/main.sh"
main "$scripts_dir" "$file_with_config" "$*"
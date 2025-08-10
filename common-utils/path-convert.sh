#!/bin/bash

# Function to convert a relative path to an absolute path
function abspath {
  local path="$1"

  # If the path is already absolute, return it
  if [[ "$path" == /* ]]; then
    echo "$path"
    return
  fi

  # Get the current working directory
  local cwd=$(pwd)
  [ $? -ne 0 ] && exit 1

  # Handle paths starting with './'
  if [[ "$path" == ./* ]]; then
    path="${path:2}"
  fi

  # Handle paths containing '../'
  while [[ "$path" == ../* ]]; do
    path="${path:3}"
    cwd=$(dirname "$cwd")
    [ $? -ne 0 ] && exit 1
  done

  # Construct the absolute path
  echo "$cwd/$path"
  exit 0
}
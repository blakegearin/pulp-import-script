#!/usr/bin/env bash

red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)

checkmark=$green'✅'
swirl=$blue'\n🌀'
warn=$yellow'\n⚠️ '
x_mark=$red'\n❌'
output=$white'\n👾 Output:'$cyan

pulp_tile_size=8

echo_loading() {
  if [ "$SILENT" != true ]; then
    echo -e "$swirl $1"$white
  fi
}

echo_var() {
  eval 'printf $bldcyn"Variable:$txtrst "%s"\n" "$1=\"${'"$1"'}\""'
}

check_failure() {
  local exit_code=$1
  local action=$2

  if [[ $exit_code -ne 0 ]]; then
    echo -e "$x_mark $action failed"$white
    exit 1
  else
    if [ "$SILENT" != true ]; then
      echo -e "$checkmark $action succeeded"$white
    fi
  fi
}

create_output_directory() {
  echo_loading "Creating output directory: $output_directory"

  create_output_dir_command="mkdir '$output_directory'"
  if [ "$VERBOSE" == true ]; then
    echo_var create_output_dir_command
  fi
  eval $create_output_dir_command

  check_failure $? "Creation"
}


delete_directory_files() {
  if [ "$DELETE_OUTPUT_DIRECTORY" == true ]; then
    echo_loading "Deleting files in directory: $output_directory"

    remove_command="rm -rf '$output_directory/*'"
    if [ "$VERBOSE" == true ]; then
      echo_var remove_command
    fi
    eval $remove_command

    check_failure $? "Delete"
  fi
}

check_source_for_output_directory() {
  output_directory="$parent_dir/$OUTPUT_DIRECTORY_NAME"

  echo_loading "Checking if output directory exists at source: $output_directory"
  if [ -d "$output_directory" ]; then
    if [ "$SILENT" != true ]; then
      echo -e "$warn Output directory at source already exists"
    fi

    delete_directory_files
  elif [ -n "$OUTPUT_DIRECTORY_NAME" ]; then
    create_output_directory
  else
    create_output_directory
  fi
}

find_output_directory() {
  if [ -n "$OUTPUT_DIRECTORY_NAME" ]; then
    output_directory="$parent_dir/$OUTPUT_DIRECTORY_NAME"

    echo_loading "Checking if output directory exists: $output_directory"
    if [ -d "$output_directory" ]; then
      if [ "$SILENT" != true ]; then
        echo -e "$warn Output directory already exists at source"
      fi

      delete_directory_files
    elif [ -d "$OUTPUT_DIRECTORY_NAME" ]; then
      if [ "$SILENT" != true ]; then
        echo -e "$warn Output directory already exists"
      fi

      output_directory="$OUTPUT_DIRECTORY_NAME"

      delete_directory_files
    else
      check_source_for_output_directory
    fi
  else
    OUTPUT_DIRECTORY_NAME=$(date +"pulp-import-%s")
    check_source_for_output_directory
  fi
}

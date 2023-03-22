#!/usr/bin/env bash

# Functions

get_transformation() {
  if [ "$VERBOSE" == true ]; then
    echo_var RECOLOR
  fi

  case $RECOLOR in
    invert) transformation="-channel RGB -negate" ;;
    0) transformation="-alpha off -threshold 50%" ;;
    1) transformation="-alpha off -auto-threshold otsu" ;;
    2) transformation="-monochrome" ;;
    3) transformation="+dither -colors 3 -colors 2 -colorspace gray -normalize" ;;
    4) transformation="-alpha off -threshold 75%" ;;
    5) transformation="-colorspace gray -auto-level -lat 20x20+5%" ;;
    6) transformation="-colorspace gray -auto-level -negate -lat 20x20+5%" ;;
    7) transformation="-colorspace gray -auto-level -lat 20x20+10%" ;;
    *) transformation="$RECOLOR"
  esac
}

recolor() {
  get_transformation

  echo_loading "Recoloring image with transformation #$RECOLOR"

  if [ "$VERBOSE" == true ]; then
    echo_var IMAGE_FILEPATH
  fi

  recolor_command="convert '$IMAGE_FILEPATH' $transformation '$output_directory/recolor-image-$RECOLOR.png'"
  if [ "$VERBOSE" == true ]; then
    echo_var recolor_command
  fi
  eval $recolor_command

  check_failure $? "Recolor"
}

# Main

current_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
parent_dir="$(dirname "$current_dir")"

source "$parent_dir/.env"
source "$parent_dir/src/constants.sh"

while getopts d:i:r: flag; do
  case "${flag}" in
    d) OUTPUT_DIRECTORY_NAME=${OPTARG} ;;
    i) IMAGE_FILEPATH=${OPTARG} ;;
    r) RECOLOR=${OPTARG} ;;
  esac
done

find_output_directory

if [ "$RECOLOR" != "all" ]; then
  recolor
else
  RECOLOR=0
  until [ $RECOLOR -gt 7 ]; do
    recolor
    ((RECOLOR=RECOLOR+1))
  done
fi

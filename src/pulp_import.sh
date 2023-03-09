#!/usr/bin/env bash

# Functions

resize_image() {
  border_px=$pulp_tile_size

  until [ $border_px -gt $image_dimension ]; do
    ((border_px=border_px+pulp_tile_size))
  done

  extent="${border_px}x${border_px}"
  echo_loading "Updating image to be $extent pixels with a $BORDER_COLOR border"

  update_command="magick '$IMAGE_FILEPATH' -gravity $IMAGE_GRAVITY -background $BORDER_COLOR -extent $extent '$IMAGE_FILEPATH'"
  if [ "$VERBOSE" == true ]; then
    echo_var update_command
  fi
  eval $update_command

  check_failure $? "Update"
}

# Main

current_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
parent_dir="$(dirname "$current_dir")"

source "$parent_dir/.env"
source "$parent_dir/src/constants.sh"

while getopts c:d:g:i:n:q:r: flag; do
  case "${flag}" in
    c) BORDER_COLOR=${OPTARG} ;;
    d) OUTPUT_DIRECTORY_NAME=${OPTARG} ;;
    g) IMAGE_GRAVITY=${OPTARG} ;;
    i) IMAGE_FILEPATH=${OPTARG} ;;
    n) TILE_START_INDEX=${OPTARG} ;;
    q) QR_CODE_DATA=${OPTARG} ;;
    r) RECOLOR=${OPTARG} ;;
  esac
done

if [ -z "$QR_CODE_DATA" ] && [ -z "$IMAGE_FILEPATH" ]; then
  echo -e "$x_mark Required parameter is missing"
  echo -e "   - Pass in image filepath via -i or IMAGE_FILEPATH in .env"
  echo -e "   - Pass in QR code data via -q or QR_CODE_DATA in .env\n"
  exit 1
fi

find_output_directory

if [ -n "$QR_CODE_DATA" ]; then
  IMAGE_FILEPATH="$output_directory/qr_code.png"

  echo_loading "Creating QR code with data: $QR_CODE_DATA"

  create_qr_command="qrencode -m 0 -s 1 -o '$IMAGE_FILEPATH' '$QR_CODE_DATA'"
  if [ "$VERBOSE" == true ]; then
    echo_var create_qr_command
  fi
  eval $create_qr_command

  check_failure $? "Creation"
elif [ -n "$IMAGE_FILEPATH" ]; then
  echo_loading "Checking if image exists: $IMAGE_FILEPATH"
  if test -f "$IMAGE_FILEPATH"; then
    (exit 0)
  else
    (exit 1)
  fi
  check_failure $? "Check"

  echo_loading "Copying image to output directory: $IMAGE_FILEPATH"

  copy_command="cp '$IMAGE_FILEPATH' '$output_directory/original_image.png'"
  if [ "$VERBOSE" == true ]; then
    echo_var copy_command
  fi
  eval $copy_command

  check_failure $? "Copy"

  IMAGE_FILEPATH="$output_directory/original_image.png"

  if [ "$VERBOSE" == true ]; then
    echo_var RECOLOR
  fi

  if [ -n "$RECOLOR" ]; then
    eval "bash recolor.sh -i '$IMAGE_FILEPATH' -r $RECOLOR"
    IMAGE_FILEPATH="$output_directory/recolor-image-$RECOLOR.png"
  fi
fi

image_width=$(identify -ping -format '%w' "$IMAGE_FILEPATH")
image_height=$(identify -ping -format '%h' "$IMAGE_FILEPATH")

if [ "$VERBOSE" == true ]; then
  echo_var image_width
  echo_var image_height
fi

if ((image_width % pulp_tile_size != 0)) && (( image_width >= image_height )); then
  if [ "$SILENT" != true ]; then
    echo -e "$warn Image width is ${image_width}px which is not perfectly divisible by Pulp's tile size of ${pulp_tile_size}x${pulp_tile_size} pixels"
  fi

  image_dimension=$image_width
  resize_image
elif ((image_height % pulp_tile_size != 0)) && (( image_height >= image_width )); then
  if [ "$SILENT" != true ]; then
    echo -e "$warn Image height is ${image_height}px which is not perfectly divisible by Pulp's tile size of ${pulp_tile_size}x${pulp_tile_size} pixels"
  fi

  image_dimension=$image_height
  resize_image
fi

tiles_directory="$output_directory/tiles"

echo_loading "Checking if tiles directory exists: $tiles_directory"
if [ -d "$tiles_directory" ]; then
  if [ "$SILENT" != true ]; then
    echo -e "$warn Tiles directory already exists"
  fi
else
  echo_loading "Creating tiles directory: $tiles_directory"

  create_tiles_dir_command="mkdir '$tiles_directory'"
  if [ "$VERBOSE" == true ]; then
    echo_var create_tiles_dir_command
  fi
  eval $create_tiles_dir_command

  check_failure $? "Creation"
fi

echo_loading "Splitting image into Pulp tiles"
split_command="convert -crop ${pulp_tile_size}x${pulp_tile_size} '$IMAGE_FILEPATH' -scene $TILE_START_INDEX '$tiles_directory/tile.png'"
if [ "$VERBOSE" == true ]; then
  echo_var split_command
fi
eval $split_command

check_failure $? "Split"

output_filename="pulp-tiles-layer-table-$pulp_tile_size-$pulp_tile_size.png"
output_filepath="$output_directory/$output_filename"

echo_loading "Combining image tiles into Pulp import PNG"

combine_command="montage '$tiles_directory/tile-*.png' -geometry +0+0 -tile x1 -gravity NorthWest '$output_filepath'"
if [ "$VERBOSE" == true ]; then
  echo_var combine_command
fi
eval $combine_command

check_failure $? "Combine"

if [ "$DELETE_TILES" == true ]; then
  echo_loading "Deleting tiles directory and files inside"

  delete_command="rm -rf '$tiles_directory'"
  if [ "$VERBOSE" == true ]; then
    echo_var delete_command
  fi
  eval $delete_command

  check_failure $? "Delete"
fi

if [ "$SILENT" != true ]; then
  echo -e "$output $output_filepath"
fi

if [ "$OPEN_OUTPUT" == true ]; then
  echo_loading "Opening output file"
  open_command="open '$output_filepath'"
  if [ "$VERBOSE" == true ]; then
    echo_var open_command
  fi
  eval $open_command
fi

echo -e ""

#!/usr/bin/env bash

# Functions

resize_image() {
  border_px=$pulp_tile_size

  until [ $border_px -gt $image_dimension ]; do
    ((border_px=border_px+pulp_tile_size))
  done

  if [ "$BORDER_COLOR" == "dynamic" ]; then
    if [ "$INVERT" == true ]; then
      border='black'
    else
      border='white'
    fi
  else
    border=$BORDER_COLOR
  fi

  extent="${border_px}x${border_px}"
  echo_loading "Updating image to be $extent pixels with a $border border"

  update_command="magick '$IMAGE_FILEPATH' -gravity $IMAGE_GRAVITY -background $border -extent $extent '$IMAGE_FILEPATH'"
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

while getopts c:d:g:i:l:n:o:q:r:s:z: flag; do
  case "${flag}" in
    c) BORDER_COLOR=${OPTARG} ;;
    d) OUTPUT_DIRECTORY_NAME=${OPTARG} ;;
    g) IMAGE_GRAVITY=${OPTARG} ;;
    i) IMAGE_FILEPATH=${OPTARG} ;;
    l) LAYER_NAME=${OPTARG} ;;
    n) TILE_START_INDEX=${OPTARG} ;;
    o) TILE_INDEX_ZERO_PADDING=${OPTARG} ;;
    q) QR_CODE_DATA=${OPTARG} ;;
    r) RECOLOR=${OPTARG} ;;
    s) QR_CODE_SCALE=${OPTARG} ;;
    z) OUTPUT_ID=${OPTARG} ;;
  esac
done

if [ -z "$LAYER_NAME" ]; then
  echo -e "$x_mark Required parameter is missing:"
  echo -e "   - Pass in layer name via -l or LAYER_NAME in .env"
  exit 1
else
  case "$LAYER_NAME" in
    Items) ;;
    Player) ;;
    Sprites) ;;
    World) ;;
    items) LAYER_NAME="Items" ;;
    player) LAYER_NAME="Player" ;;
    sprites) LAYER_NAME="Sprites" ;;
    world) LAYER_NAME="World" ;;
    *) invalid_player_name=true ;;
  esac

  if [ "$invalid_player_name" == true ]; then
    echo -e "$x_mark Required parameter is invalid:"
    echo -e "   - Layer name must be one of the following: Items Player Sprites World"
    exit 1
  fi
fi

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

  # if [ "$INVERT" == true ]; then
  #   colors='--foreground=ffffff --background=000000'
  # else
  #   colors=''
  # fi

  # create_qr_command="qrencode $colors -m 0 -s $QR_CODE_SCALE -o $QR_ENCODE_OPTIONS '$IMAGE_FILEPATH' '$QR_CODE_DATA'"
  create_qr_command="qrencode -m 0 -s $QR_CODE_SCALE -o $QR_ENCODE_OPTIONS '$IMAGE_FILEPATH' '$QR_CODE_DATA'"
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
fi

if [ "$INVERT" == true ]; then
  RECOLOR='invert'
fi

if [ "$VERBOSE" == true ]; then
  echo_var RECOLOR
fi

if [ -n "$RECOLOR" ]; then
  eval "bash '${current_dir}/recolor.sh' -i '$IMAGE_FILEPATH' -r $RECOLOR"
  IMAGE_FILEPATH="$output_directory/recolor-image-$RECOLOR.png"
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
split_command="convert -crop ${pulp_tile_size}x${pulp_tile_size} '$IMAGE_FILEPATH' -scene $TILE_START_INDEX '$tiles_directory/pulp-tiles-%0${TILE_INDEX_ZERO_PADDING}d-layer-${LAYER_NAME}-count-1-table-8-8.png'"
if [ "$VERBOSE" == true ]; then
  echo_var split_command
fi
eval $split_command

check_failure $? "Split"

tile_amount=$(ls -1q $tiles_directory | wc -l | xargs)
if [ "$VERBOSE" == true ]; then
  echo_var tile_amount
fi

if [ -n "$OUTPUT_ID" ]; then
  OUTPUT_ID="-$OUTPUT_ID"
fi

output_filename="pulp-tiles${OUTPUT_ID}-layer-${LAYER_NAME}-count-${tile_amount}-table-$pulp_tile_size-$pulp_tile_size.png"
output_filepath="$output_directory/$output_filename"

echo_loading "Combining image tiles into Pulp import PNG"

combine_command="montage '$tiles_directory/pulp-tiles-*-layer-${LAYER_NAME}-count-1-table-8-8.png' -geometry +0+0 -tile x1 -gravity NorthWest '$output_filepath'"
if [ "$VERBOSE" == true ]; then
  echo_var combine_command
fi
eval $combine_command

check_failure $? "Combine"

if [ "$DELETE_TILES" == true ]; then
  echo_loading "Deleting tiles directory and files inside"

  delete_dir_command="rm -rf '$tiles_directory'"
  if [ "$VERBOSE" == true ]; then
    echo_var delete_dir_command
  fi
  eval $delete_dir_command

  check_failure $? "Delete"
fi

if [ "$DELETE_SOURCE_IMAGE" == true ]; then
  if [ -n "$QR_CODE_DATA" ]; then
    image_name="QR code source image"
  elif [ -n "$IMAGE_FILEPATH" ]; then
    image_name="copy of input source image"
  fi

  echo_loading "Deleting $image_name from output directory"

  delete_image_command="rm $IMAGE_FILEPATH"
  if [ "$VERBOSE" == true ]; then
    echo_var delete_image_command
  fi
  eval $delete_image_command

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

# Constants
red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)

checkmark=$green'✅'
swirl=$blue'🌀'
warn=$yellow'⚠️ '
x_mark=$red'❌'

# Defaults
gravity=center
background=white
directory_name=$(date +"%s")
open_output=false
silent=false

qr_code_filename='qr.png'

while getopts b:d:e:g:o:s: flag
do
  case "${flag}" in
    b) background=${OPTARG} ;;
    d) directory_name=${OPTARG} ;;
    e) encode_data=${OPTARG} ;;
    g) gravity=${OPTARG} ;;
    o) open_output=true ;;
    s) silent=true ;;
  esac
done

echo_loading() {
  if [ "$silent" != true ]; then
    echo -e "$swirl $1"
  fi
}

check_failure() {
  local exit_code=$1
  local action=$2

  if [[ $exit_code -ne 0 ]]; then
    echo -e "$x_mark $action failed"
    exit 1
  else
    if [ "$silent" != true ]; then
      echo -e "$checkmark $action succeeded\n"
    fi
  fi
}

if [ "$silent" != true ]; then
  echo -e "\n"
fi

if [ -z "$encode_data" ]; then
  echo -e "$x_mark Encode data is not defined; pass in data to encode into QR code with -e flag"
  exit 1
fi

output_directory="$PWD"/$directory_name

if [ -d $output_directory ]; then
  if [ "$silent" != true ]; then
    echo -e "$warn Directory already exists"
  fi

  echo_loading "$swirl Deleting files in directory: $output_directory"
  rm "$output_directory"/*.png
  check_failure $? "Delete"
else
  echo_loading "Creating directory: $output_directory"
  mkdir $output_directory
  check_failure $? "Creation"
fi

echo_loading "Creating QR code encoding: $encode_data"
qrencode -m 0 -s 1 -o $qr_code_filename $encode_data
check_failure $? "Creation"

qr_width=$(identify -ping -format '%w' $qr_code_filename)

if ((qr_width % 8 != 0)); then
  if [ "$silent" != true ]; then
    echo -e "$warn QR code width is ${qr_width}px which is not divisible by Pulp's tile size of 8px"
  fi

  border_px=8

  until [ $border_px -gt $qr_width ]
  do
    ((border_px=border_px+8))
  done

  echo_loading "Updating QR code to be ${border_px}x${border_px} pixels with a $background background"
  magick $qr_code_filename -gravity $gravity -background $background -extent "$border_px"x"$border_px" $qr_code_filename
  check_failure $? "Update"
fi

echo_loading "Splitting QR code into Pulp tiles"
convert -crop 8x8 $qr_code_filename -scene 134 "$output_directory/$qr_code_filename"
check_failure $? "Split"

output_filename="pulp-tiles-layer-count-16-table-8-8.png"
echo_loading "Combining QR code tiles into Pulp import PNG"
montage "$output_directory/qr-*.png" -geometry +0+0 -tile x1 -gravity NorthWest "$output_directory/$output_filename"
check_failure $? "Combine"

output_filepath=$output_directory/$output_filename

if [ "$open_output" == true ]; then
  if [ "$silent" != true ]; then
    echo -e $cyan"Output: $output_filepath (opening now)"
  fi

  open $output_filepath
elif [ "$silent" != true ]; then
  echo -e $cyan"Output: $output_filepath"
fi

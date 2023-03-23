<p align="center">
  <img id="logo" src="https://raw.githubusercontent.com/blakegearin/pulp-import-script/main/images/logo.png" class="center" alt="Pulp Import Script logo" title="Pulp Import Script" width="500" height="500"/>
</p>

# Pulp Import Script

A Bash script to automate image importing into Pulp.

It is not sponsored, endorsed, licensed by, or affiliated with Panic.

## Features

- Can generate QR codes or take in any image as input

- Outputs a PNG to import all tiles at once and separate PNG files for each tile

- Adds borders for clean tiling

- Provides color conversion options

- Configurable via CLI arguments or dotenv

## Prerequisites

- [Imagemagick](https://imagemagick.org)

- [libqrencode](https://github.com/fukuchi/libqrencode) (only necessary for QR code generation)

## Getting Started

1. Prepare your OS

   - Windows
     1. Install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
     1. Install [Ubuntu](https://apps.microsoft.com/store/detail/ubuntu/9PDXGNCFSCZV?hl=en-us&gl=us&rtc=1)
   - macOS
     1. Optionally install [Homebrew](https://brew.sh/) for easier installs

1. Install Imagemagick

   - Homebrew: `brew install imagemagick`
   - Ubuntu: `sudo apt-get install imagemagick`
   - [Manually download](https://imagemagick.org/script/download.php)

1. Optionally install `libqrencode` if you need QR code generation

   - Homebrew: `brew install qrencode`
   - Ubuntu: `sudo apt-get install qrencode`
   - [Manually download](https://github.com/fukuchi/libqrencode/releases)

1. Clone this repository

   - Git: `git clone https://github.com/blakegearin/pulp-import-script.git`
   - SSH: `ssh git@github.com:blakegearin/pulp-import-script.git`
   - GitHub CLI: `gh repo clone blakegearin/pulp-import-script`

## Usage

```sh
cd pulp-import-script

# Image filepath input
bash src/pulp_import.sh -l "Items" -i ~/Downloads/my_amazing_image.png

# QR code data input
bash src/pulp_import.sh  -l "Player" -q "https://github.com"

# "src/pulp_import.sh" is a relative path
# Use an absolute path to run the command from any directory
# e.g. ~/Documents/pulp-import-script/src/pulp_import.sh
```

### Required Parameters

The required input parameters are:

   - name of the destination Pulp layer

     - valid options: `items`, `player`, `sprites`, `world`

   - image filepath _**OR**_ data to encode a QR code

| Flag  | Environment Variable | Type   | Default | Description                               |
| :---: | -------------------- | ------ | :-----: | ----------------------------------------- |
| `-l`  | `LAYER_NAME`         | string |    ❌    | The Pulp layer that will be imported into |
| `-i`  | `IMAGE_FILEPATH`     | string |    ❌    | Location of image to be processed         |
| `-q`  | `QR_CODE_DATA`       | string |    ❌    | Data to encode into QR code               |

### Optional Parameters

#### Strings & Integers

| Flag  | Environment Variable      | Type    | Default                   | Description                                                                                                                           |
| :---: | ------------------------- | ------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `-c`  | `BORDER_COLOR`            | string  | `dynamic`                 | Color of the border added to an image; when set to `dynamic` it's white when `INVERT=false` and black when `INVERT=true`              |
| `-d`  | `OUTPUT_DIRECTORY_NAME`   | string  | `pulp-import-{timestamp}` | Directory where output file and tiles directory will get created                                                                      |
| `-g`  | `IMAGE_GRAVITY`           | string  | `center`                  | Position of an image in relation to the border (see [documentation](https://imagemagick.org/script/command-line-options.php#gravity)) |
| `-n`  | `TILE_START_INDEX`        | integer | `0`                       | Starting index used to create tiles                                                                                                   |
| `-o`  | `TILE_INDEX_ZERO_PADDING` | integer | `4`                       | Number of zeros to be padded on filenames of PNG tiles; setting too low can cause failure or improper ordering (e.g. 11 before 2)     |
| `-q`  | `QR_ENCODE_OPTIONS`       | string  | none                      | Pass in custom options to `libqrencode`, like `-M` for micro QR codes; see all options with `qrencode --help`                         |
| `-r`  | `RECOLOR`                 | integer | none                      | Color transformation to apply for changing an image to black & white                                                                  |
| `-s`  | `QR_CODE_SCALE`           | integer | `1`                       | The "module size" of the QR code; use to increase its size                                                                            |
| `-z`  | `OUTPUT_ID`               | integer | none                      | Identification number to include in the filename of the primary output PNG                                                            |

#### Booleans

| Environment Variable      | Default | Description                                                                                                      |
| ------------------------- | :-----: | ---------------------------------------------------------------------------------------------------------------- |
| `INVERT`                  | `false` | Whether to invert the colors of the image                                                                        |
| `DELETE_OUTPUT_DIRECTORY` | `false` | Whether to delete existing files in a preexisting output directory                                               |
| `DELETE_TILES`            | `false` | Whether to delete the tiles directory                                                                            |
| `DELETE_SOURCE_IMAGE`     | `false` | Whether to delete the source image that's being chunked; could be the QR code image or a copy of the input image |
| `OPEN_OUTPUT`             | `false` | Whether to open the output file on completion                                                                    |
| `SILENT`                  | `false` | Whether to suppress all logging except errors                                                                    |
| `VERBOSE`                 | `false` | Whether to log out extra variables useful for debugging                                                          |

## FAQ

- I'm not able to import an output PNG in Pulp. Why won't it work?

  - It's important to double-check that the import is actually failing. When you an import in Pulp it does _**not**_ automatically take you to the layer you imported into. For example, if you're on the `Player` layer and import some `Sprites` you'll stay on the `Player` layer and nothing visually will change. So it may _feel_ like the import failed when it actually didn't.
  - If you're certain it's failing, feel free to [open an issue](https://github.com/blakegearin/pulp-import-script/issues/new). Please include what command you ran, output logs, output files, and input image file if applicable.

- Does this downsize images that are too big for Pulp?

  - No. The only resizing that's considered is when the height or width is not divisible by eight (8) then the image is expanded to be a square divisible by eight.

- I'm getting this error: `syntax error near unexpected token $'{\r''`

  - DOS and Unix have different line endings, so you'll need to take some action to ensure that's being handled properly. For example, using `sed` or `dos2unix` to modify the `.sh` files or configuring your code editor to prefer Unix-based line endings. More information can be found on [Stack Overflow](https://stackoverflow.com/questions/11616835/r-command-not-found-bashrc-bash-profile).

## Links

- [PulpScript Docs](https://play.date/pulp/docs/pulpscript/)
- [Pulp Docs](https://play.date/pulp/docs/)
- [Pulp](https://play.date/pulp/)

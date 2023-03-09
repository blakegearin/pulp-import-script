<p align="center">
  <img id="logo" src="https://raw.githubusercontent.com/blakegearin/pulp-import-script/main/images/logo.png" class="center" alt="Pulp Import Script logo" title="Pulp Import Script" width="500" height="500"/>
</p>

# Pulp Import Script

A Bash script to automate image importing into Pulp.

It is not sponsored, endorsed, licensed by, or affiliated with Panic.

## Features

- Outputs both an import-able PNG and individual tiles

- Adds borders for clean tiling

- Generates QR codes

- Configurable via CLI arguments or dotenv

## Prerequisites

- [Imagemagick](https://imagemagick.org) ([Homebrew](https://formulae.brew.sh/formula/imagemagick))

For QR code generation: [qrencode](https://fukuchi.org/works/qrencode/index.html.en) ([Homebrew](https://formulae.brew.sh/formula/qrencode))

## Usage

```sh
bash src/pulp_import.sh -q "https://github.com"
```

### Required

The only required input is an image filepath or data to encode a QR code.

| Flag | Environment Variable | Type   | Default | Description                     |
|:----:|----------------------|--------|:-------:|---------------------------------|
| `-i` | `IMAGE_FILEPATH`     | string |    ❌    | Input image                     |
| `-q` | `QR_CODE_DATA`       | string |    ❌    | Input data for QR code encoding |

### Optional

#### Strings & Integers

| Flag | Environment Variable    | Type    | Default                   | Description                                                                                                                           |
|:----:|-------------------------|---------|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `-c` | `BORDER_COLOR`          | string  | `white`                   | Color of the border added to an image                                                                                                 |
| `-d` | `OUTPUT_DIRECTORY_NAME` | string  | `pulp-import-{timestamp}` | Directory where output file and tiles directory will get created                                                                      |
| `-g` | `IMAGE_GRAVITY`         | string  | `center`                  | Position of an image in relation to the border (see [documentation](https://imagemagick.org/script/command-line-options.php#gravity)) |
| `-n` | `TILE_START_INDEX`      | integer | `134`                     | Starting index used to create tiles                                                                                                   |
| `-r` | `RECOLOR`               | integer | none                      | Color transformation to apply for changing an image to black & white                                                                  |

#### Booleans

| Environment Variable      | Default | Description                                              |
|---------------------------|:-------:|----------------------------------------------------------|
| `DELETE_OUTPUT_DIRECTORY` |  `true` | Whether to delete existing files in the output directory |
| `DELETE_TILES`            | `false` | Whether to delete the tiles directory                    |
| `OPEN_OUTPUT`             | `false` | Whether to open the output file on completion            |
| `SILENT`                  | `false` | Whether to suppress all logging except errors            |
| `VERBOSE`                 | `false` | Whether to log out extra variables useful for debugging  |

## FAQ

- Does this downsize images that are too big for Pulp?

  - No. The only resizing that's considered is when the height or width is not divisible by eight (8) then the image is expanded to be a square divisible by eight.

## Links

- [PulpScript Docs](https://play.date/pulp/docs/pulpscript/)
- [Pulp Docs](https://play.date/pulp/docs/)
- [Pulp](https://play.date/pulp/)

# Pulp QR Code Automation

This is a Bash script to automate:

1. Generating a QR code
1. Splicing the QR code into Pulp-friendly PNG tiles
1. Recombining the QR code tiles into a Pulp-friendly import PNG

It is not sponsored, endorsed, licensed by, or affiliated with Panic.

## Prerequisites

- [Imagemagick](https://imagemagick.org) ([Homebrew](https://formulae.brew.sh/formula/imagemagick))
- [qrencode](https://fukuchi.org/works/qrencode/index.html.en) ([Homebrew](https://formulae.brew.sh/formula/qrencode))

## Flags

Use flags in this format: `bash pulp_qr_code.sh -e "https://github.com"`

### Required

- `-e` to pass in the data to be encoded in the QR code

### Optional

#### Borders

- `-b` to specify the border background color (default: `white`)

- `-d` to specify the QR code position (see: [gravity](https://imagemagick.org/script/command-line-options.php#gravity)) (default: center)

#### Meta

- `-d` to specify the name of the output directory; if already exists, files get deleted (default: timestamp)

- `-o` with any value opens the output file

- `-s` with any value silences all logging except failures

## Links

- [PulpScript Docs](https://play.date/pulp/docs/pulpscript/)
- [Pulp Docs](https://play.date/pulp/docs/)
- [Pulp](https://play.date/pulp/)

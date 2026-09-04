# winddcutil

Fork of [scottaxcell/winddcutil](https://github.com/scottaxcell/winddcutil), the Windows implementation of the [ddcutil](https://github.com/rockowitz/ddcutil) Linux program for querying and changing monitor settings, such as brightness and color levels. It uses the VESA Monitor Control Command Set (MCCS) over the Display Data Channel Command Interface Standard (DDC-CI).

All credit for `winddcutil` itself goes to [Scott Axcell](https://github.com/scottaxcell). This fork adds one thing on top of it: a pixel cleaning routine for the ASUS ROG Swift PG32UCDM, in [`examples/PG32UCDM_pixel_clean`](examples/PG32UCDM_pixel_clean).

## PG32UCDM Pixel Cleaning script

A Windows batch / Visual Basic script, built on `winddcutil`, that runs a pixel cleaning routine on the ASUS ROG Swift PG32UCDM.

It has been tested on a couple of units running firmware MCM103, beta MCM104 and MCM105. It should also work on earlier versions, but that is unconfirmed.

### Installation

Download the zip archive from [Releases](https://github.com/vermi5/winddcutil/releases) and unzip its two contained files into the same directory.

*Having your Windows [monitor drivers](https://rog.asus.com/monitors/27-to-31-5-inches/rog-swift-oled-pg32ucdm/helpdesk_download/) installed will help with ID'ing.*

### Usage

Run `PixelClean.cmd` / `PixelCleanv2.vbs`. It will:

- Read your current Windows power plan monitor timeout.
- Detect your Windows display number for the PG32UCDM.
- Get your current settings stored in the same address used for pixel cleaning.
- Set your Windows power plan monitor timeout to 10 minutes.
- Write the corrected value to that same address. This will black the screen out, and the logo should blink several times to indicate the cleaning has started. It takes around 6 minutes.
- Once it's done, if it took less than 6 minutes, it will wait for that period to elapse, restore your previous Windows monitor timeout and exit.

If Windows didn't detect user input (a random keypress or moving the mouse) while the cleaning was under way, and your previous timeout has elapsed, that will probably result in the monitor entering sleep.

## winddcutil usage

The `dist\winddcutil.exe` is a standalone executable that can be run without installing a Python interpreter.

```
usage: winddcutil [-h] {detect,capabilities,setvcp,getvcp} ...

Windows implementation of the ddcutil Linux program for querying and changing monitor settings

positional arguments:
  {detect,capabilities,setvcp,getvcp}
    detect              Detect monitors
    capabilities        Query monitor capabilities
    setvcp              Set VCP feature value
    getvcp              Get VCP feature value

options:
  -h, --help            show this help message and exit
```

Since upstream release 2.0.0 (2023-09-15) `winddcutil` is a Python program, using the API provided by the [monitorcontrol](https://github.com/newAM/monitorcontrol) package. See the [CHANGELOG](CHANGELOG.md) for details.

## Development

This Python package is built with Python 3.11.5. Get Python [here](https://www.python.org/downloads/).

### Useful commands

Initialize Python virtual environment

```
py -3 -m venv --upgrade-deps .venv
.venv\Scripts\activate.bat
pip install -r requirements.txt
```

Build standalone distributable [dist\winddcutil.exe]

```
pyinstaller cli.py --name winddcutil --onefile
```

Run tests

```
pytest test
```

Run pre-commit checks on all files

```
pre-commit run --all
```

## License

[MIT License](LICENSE)

## Issues

For bugs or feature requests about the **pixel cleaning script**, use [this fork's issue tracker](https://github.com/vermi5/winddcutil/issues).

For bugs in `winddcutil` itself, please report them upstream at [scottaxcell/winddcutil](https://github.com/scottaxcell/winddcutil/issues).

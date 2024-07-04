# PG32UCDM Pixel Cleaning script

This is a windows batch script based on winddcutil that executes a pixel cleaning routine for the ASUS ROG Swift PG32UCDM.
It has been tested on a couple units running firmware MCM103, beta MCM104, and MCM 105. It should also work on previous versions but it's unconfirmed. 

## Installation

Download the zip archive from [Releases](https://github.com/vermi5/winddcutil/releases) and unzip its two contained files to the same directory.
*Having your windows [monitor drivers]([url](https://rog.asus.com/monitors/27-to-31-5-inches/rog-swift-oled-pg32ucdm/helpdesk_download/)) installed will help with ID'ing*
## Usage

Run PixelClean.cmd, it will:

- Read your current windows power plan monitor timeout.
- Detect your windows display number for the PG32UCDM.
- Get your current settings stored in the same address used for pixel cleaning.
- Set your windows power plan monitor timeout to 10 minutes
- Write the corrected value to that same address. <- This will black the screen out and the logo should blink several times to indicate the cleaning has started and will take around 6 minutes.
- Once it's done, if it took less than 6 minutes, it'll wait for that period to elapse, restore your previous windows monitor timeout and exit.

If windows didn't detect user input (random keypress or moving the mouse) while the cleaning was under way and your previous timeout has elapsed, that'll probably result in the monitor entering sleep.
 


# winddcutil

Windows implementation of the [ddcutil](https://github.com/rockowitz/ddcutil) Linux program for querying and changing monitor settings, such as brightness and color levels. Uses the VESA Monitor Control Command Set (MCCS) over the Display Data Channel Command Interface Standard (DDC-CI).

## News

### Release [2.0.0] - 2023-09-15

- Good news, `winddcutil` has been ported to Python! We use the API provided by the [monitorcontrol](https://github.com/newAM/monitorcontrol) Python package.
- See the [CHANGELOG](https://github.com/scottaxcell/winddcutil/blob/main/CHANGELOG.md) for additional details.

## Usage

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

Bug fixes and enhancement contributions via PRs are welcome!

## License

[MIT License](https://github.com/scottaxcell/winddcutil/blob/main/LICENSE)

## Issues

If you find a bug or have a feature request, please file an issue using [the issue tracker on GitHub](https://github.com/scottaxcell/winddcutil/issues).

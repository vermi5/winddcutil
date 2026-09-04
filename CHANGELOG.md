# Changelog

## Fork (vermi5)

Releases of the PG32UCDM pixel cleaning script. The `winddcutil` program itself is unchanged from upstream.

### [v0.3] - 2026-09-04

#### Fixed

- Reading the Windows display timeout no longer fails when the active power
  scheme inherits that setting instead of storing an explicit per-scheme
  registry override (issue #1). The script now obtains the effective value
  through WMI without parsing localized `powercfg` output.
- The original timeout is preserved and restored in exact seconds, including
  the `0` value used for “Never”.
- The script now aborts and attempts to restore the original timeout when
  changing the power setting or the `winddcutil setvcp` command returns an
  error.

### [v0.2] - 2024-08-17

#### Changed

- Switched the script from batch to Visual Basic (`PixelCleanv2.vbs`).
- Added basic error handling and debugging output.

### [v0.1] - 2024-04-25

#### Added

- Initial release of the PG32UCDM pixel cleaning script (`PixelClean.cmd`).

## Upstream (scottaxcell/winddcutil)

### [2.0.0] - 2023-09-15

#### Changed

- Ported application from C++ to Python.
- Changed the `detect` CLI. The monitor id now starts at `1`, rather than `0`, to align with the `ddcutil` CLI.

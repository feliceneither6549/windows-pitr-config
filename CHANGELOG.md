# Changelog

Notable changes are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-08-26

First public release.

### Added

- Configuration of Point-in-time restore frequency, retention and storage limit on any
  Windows 11 edition, by writing the undocumented `_GPO` level values directly.
- Single self-contained `.cmd` file with a WPF interface. Self-elevating, portable, no
  installation and no PowerShell modules.
- Bilingual interface (English / German) with automatic detection of the Windows display
  language and a switch button in the top right.
- Current-state display: Windows edition, last and next task run, scheduled interval, and
  the state of `PITRTask` — including *waiting for the system to go idle* and a marker for
  an overdue run.
- List of existing restore points with age, build and whether a shadow copy still backs the
  registry entry.
- Shadow storage figures for the OS volume (in use, reserved, limit).
- **Apply and run now**, which lifts the task's idle condition for exactly one run and
  restores it afterwards, including on error.
- **Reset everything**, which removes every value the tool has written.
- `pitr-config.cmd selftest` — a read-only check of the interface with no window, no
  administrator rights and nothing written.

### Notes

- Frequency is an earliest possible interval, not a guarantee: restore points are only
  created while the system is idle.
- Only the OS volume is covered. Other partitions and disks are neither captured nor rolled
  back.
- Retention beyond the documented 72 hours was verified in practice.

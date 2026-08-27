# Changelog

Notable changes are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] — 2026-08-27

### Added

- A check for a newer release on start. When one exists, the window shows a line with a link
  to the release page, in whichever language is selected. The check runs in a background
  runspace so the window stays responsive, and it fails silently — no network, a firewall or
  GitHub's rate limit simply means no notice appears.
- `pitr-config.cmd noupdate` skips that check. The argument is passed on across the elevation
  prompt, which starts a new process that would otherwise lose it.

### Notes

- Nothing is downloaded or installed automatically, by design. A tool that writes to `HKLM`
  should not replace its own code over the network, and doing so would make the published
  checksums pointless. The notice is a link; the decision stays with the user.
- The update check is the only network connection the tool makes. The request reveals nothing
  about the system beyond what any web request does — an IP address and a `pitr-config` user
  agent.

## [1.1.0] — 2026-08-27

### Added

- French, Spanish and Portuguese interface translations, alongside the existing English and
  German. The language is still detected from the Windows display language; the top right now
  carries one button per language (EN DE FR ES PT) with the active one marked.
- A link to the project page and to a short guide in the window header. The guide opens in
  the language currently selected.
- `docs/guide.html` — a short guide in all five languages in one page, published at
  <https://henmedia.github.io/windows-pitr-config/guide.html> and attached to the release. A
  copy placed next to `pitr-config.cmd` takes precedence over the online version, so the tool
  stays fully usable without a network.

### Changed

- The text table is now organised as one block per language instead of one entry per string,
  which keeps a translation readable as a whole. Missing entries fall back to English, so an
  incomplete translation degrades to a mixed interface rather than to empty labels.

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

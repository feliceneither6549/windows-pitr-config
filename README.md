# windows-pitr-config

[![Download pitr-config.cmd](https://img.shields.io/badge/download-pitr--config.cmd-2ea44f?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/henmedia/windows-pitr-config/releases/latest/download/pitr-config.cmd)
[![Latest release](https://img.shields.io/github/v/release/henmedia/windows-pitr-config?style=for-the-badge&label=version&color=555555)](https://github.com/henmedia/windows-pitr-config/releases/latest)
[![Guide](https://img.shields.io/badge/guide-EN%20DE%20FR%20ES%20PT-1f6feb?style=for-the-badge)](https://henmedia.github.io/windows-pitr-config/guide.html)

Configure **Point-in-time restore** (PITR) on Windows 11 — including the frequency and
retention settings that Microsoft exposes on the Enterprise edition only.

A single, self-contained `.cmd` file with a graphical interface. No installation, no
dependencies, no PowerShell modules. Copy it to a USB stick and run it anywhere.

The interface speaks **English, German, French, Spanish and Portuguese**. It starts in
whichever one matches your Windows display language; the buttons in the top right switch at
any time. The window also links to the project and to the
[short guide](https://henmedia.github.io/windows-pitr-config/guide.html), which opens in the
language you are currently using.

![The tool running on Windows 11 Pro: current state, existing restore points, and the four
settings](docs/screenshot.png?v=1.3.0)
<!-- The ?v= is a cache buster. GitHub proxies README images and caches them by URL,
     so replacing the file alone keeps serving the old picture for a long time.
     Bump this whenever the screenshot is regenerated. -->

> **This is an unofficial approach.** The configuration values it writes are undocumented by
> Microsoft; they were recovered by analysing the Windows binaries. A future Windows release
> may change them, at which point the Windows default behaviour simply applies again. The
> tool states this in its own interface as well, and *Reset everything* undoes all of it.

---

## The problem

Point-in-time restore is the newer full-system rollback feature in Windows 11. It captures
complete system snapshots through the Volume Shadow Copy Service and lets you roll the
machine back from the Windows Recovery Environment.

Under **Settings → System → Recovery → Point-in-time restore**, Windows offers only two
controls on Home and Pro: on/off and the storage limit. According to
[Microsoft's own documentation](https://learn.microsoft.com/en-us/windows/configuration/point-in-time-restore),
**restore point frequency and retention are configurable on the Enterprise edition only** —
everywhere else those dropdowns are greyed out.

## What this tool does

It turns out the edition gate lives in the Settings user interface, not in the engine. The
PITR engine reads its configuration from a single registry key, and it does not check the
Windows edition when doing so.

This tool writes that configuration directly, which makes frequency and retention available
on any edition.

| Setting | Range offered here | Microsoft's documented range |
|---|---|---|
| Feature on/off | on / off | on / off (all editions) |
| Frequency | 1, 2, 4, 6, 8, 12, 16, 24 hours | 4, 6, 12, 16, 24 hours (Enterprise only) |
| Retention | 1–7 days (values above 72 h verified in practice) | up to 72 hours (Enterprise only) |
| Maximum storage | 2–50 GB | 2–50 GB (all editions) |

Every setting also offers **"Windows default"**, which removes the override again.

> **Frequency is an earliest possible interval, not a guarantee.** Restore points are only
> created while the system is idle: `PITRTask` runs with `RunOnlyIfIdle = True`. If the
> machine is in use — or switched off — the run is postponed, and a scheduled slot can be
> skipped entirely. Setting one hour on a machine that is used all day and shut down at
> night will not produce twenty-four points.
>
> The tool makes this visible rather than leaving you guessing: it shows the task status
> (*waiting for the system to go idle* when a run is pending) and marks an overdue next run.
> **Apply and run now** forces a point immediately whenever you want one.

## Scope: the OS volume only

Point-in-time restore covers the Windows volume — `C:` on a normal installation — and
nothing else. Other partitions and other disks are not included, **not even when they sit on
the same physical disk**.

That is not a setting anywhere; it is how the engine is built — see
[Evidence](#evidence).

Two consequences worth knowing:

- Data on other volumes is **not protected**. No restore point will bring it back after a
  deletion or an encryption attack — those volumes still need a backup of their own.
- Data on other volumes is also **not rolled back**. Rolling the system back to yesterday
  leaves today's work on `D:` exactly where it is.

The storage limit this tool sets likewise applies to the OS volume alone. The tool states
this in its own interface and labels the storage figures with the drive they refer to.

## How it works

The engine reads its configuration from:

```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Settings
```

Values follow the scheme `<name>_<level>`, all of type `REG_DWORD`:

| Value name | Unit | Meaning |
|---|---|---|
| `Active` | 0 / 1 | Feature enabled |
| `SnapshotInterval` | minutes | Interval between restore points |
| `MaxTimespan` | minutes | Lifetime of a restore point |
| `MaxGlobalSize` | MB | Ceiling for all restore points combined |
| `MaxCount` | count | Maximum number of restore points |

The level suffix determines precedence: **`GPO` > `CSP` > `UX` > `Default`**, where `UX` is
the Settings app and `CSP` is management through Intune. This tool writes at the `GPO`
level, so its values take precedence over the Settings app.

> **`GPO` here is only a name.** It is a plain registry value with that suffix — the Group
> Policy service is not involved and `gpedit.msc` is never used. Windows Home not shipping a
> Group Policy editor is therefore irrelevant.

These value names are **not documented by Microsoft**. They were recovered from
`C:\Windows\System32\OOBE\PITR.dll` and `RemoteRemediationCSP.dll`.

## Evidence

### The frequency really does change

Restore points are created by the scheduled task `\Microsoft\Windows\Setup\PITRTask`, which
recalculates its next run time on every execution. The gap between last and next run is
therefore a directly measurable indicator of the effective frequency.

Setting `SnapshotInterval_GPO = 240` and running the task once:

| | Before | After |
|---|---|---|
| Interval | 1440 min (24 h) | **240 min (4 h)** |

Task exit code `0`, and an additional restore point was created. Afterwards the Settings app
displayed *"Some of these settings are managed by your organization"* and showed the values
greyed out — on a machine under no management at all.

### Only the OS volume is ever covered

`PITR.dll` carries an explicit rejection for anything else, and a snapshot's registry entry
has no volume field at all, because there is only ever one volume:

```
OS volume      : %s
Snapshot is not on the OS volume
```

Confirmed on a machine whose `C:` and `D:` are two partitions of the same SSD: `C:` holds the
shadow copy and its difference area, while `D:` has no shadow copy and no shadow storage
configured at all.

## Usage

[**Download `pitr-config.cmd`**](https://github.com/henmedia/windows-pitr-config/releases/latest/download/pitr-config.cmd)
— that one file is the whole download, and the link always points at the newest release. The
version shown under the headline in the window tells you which release you are running.

Double-click `pitr-config.cmd`. It requests administrator rights itself (UAC).

A [short guide](https://henmedia.github.io/windows-pitr-config/guide.html) covers the same
ground in all five languages. Downloading `guide.html` next to `pitr-config.cmd` makes the
tool open that local copy instead, which keeps it fully usable on a stick without a network.

Browsers treat `.cmd` files as executable content, so the download may need one confirmation
before it is kept. Every release lists the SHA-256 of its file, which is worth comparing
before running anything that writes to `HKLM`:

```
Get-FileHash pitr-config.cmd -Algorithm SHA256
```

| Button | Effect |
|---|---|
| **Apply** | Writes the values. A new frequency takes effect on the next task run. |
| **Apply and run now** | Writes the values and runs the task immediately, so the schedule is recalculated at once. |
| **Refresh** | Re-reads the current state. |
| **Reset everything** | Removes every value this tool has set, after confirmation. |

For a read-only look at your system — no window, no administrator rights, nothing written:

```
pitr-config.cmd selftest
```

### Update check

On start the tool asks GitHub whether a newer release exists and, if so, shows a line in the
window with a link to it. It never downloads or installs anything by itself — the link opens
the release page in your browser and you decide from there. That is deliberate: a tool that
writes to `HKLM` has no business replacing its own code over the network, and doing so would
make the published checksums pointless.

The check runs in the background, so the window stays usable, and it fails silently. No
network, a firewall, or GitHub's rate limit simply means no notice appears. To skip it
entirely, start the tool as:

```
pitr-config.cmd noupdate
```

This is the only network connection the tool makes. The request reveals nothing about your
system beyond what any web request does — an IP address and a `pitr-config` user agent.

### Why "Apply and run now" exists

`PITRTask` has `RunOnlyIfIdle = True`. While you are actively using the machine it stays in
the *Queued* state and a manual start appears to do nothing. That button lifts the idle
condition for exactly one run and restores it afterwards — including when an error occurs
in between.

## Requirements

- Windows 11 with Point-in-time restore present (Settings → System → Recovery).
  Home and Pro are both confirmed working; Enterprise offers these settings natively anyway.
- Administrator rights (the tool requests them itself)
- Windows PowerShell 5.1, which ships with Windows

## Risks and reversal

- The value names are undocumented. A larger Windows update may change the scheme; the
  Windows default behaviour then simply applies again.
- A short frequency produces more shadow copies. VSS storage is shared with other tools —
  keep an eye on the storage limit if you also run something like Macrium Reflect.
- Nothing here is permanent. *Reset everything* removes the values, or delete every value
  with the `_GPO` suffix from the registry key above by hand.
- The tool never deletes restore points. It only changes configuration.

## About restore point storage

The tool shows three figures, all for the OS volume:

- **In use** — data actually written by the shadow copies.
- **Reserved** — space VSS has already claimed on disk. It is unavailable to other files but
  not yet fully filled; VSS grabs it ahead of time so writes never stall.
- **Limit** — the configured ceiling.

Windows reports these per volume only. There is deliberately **no per-point size**: all
restore points share one common difference area, so an individual size would not be a
meaningful figure.

## Editing the file

The tool is a hybrid file: a short batch section on top, and the complete PowerShell code
with the WPF interface below the `#___PSCODE___` marker. The batch part secures
administrator rights, reads its own file through `%~f0` (so renaming it is harmless), and
executes the lower part as a script block.

> **Keep the encoding.** The file must stay **UTF-8 without BOM** with CRLF line endings — a
> BOM makes `cmd.exe` trip over the first line. Non-ASCII characters survive regardless,
> because the loader reads the file as UTF-8 explicitly rather than relying on the console
> code page.

## Versioning

Releases follow `MAJOR.MINOR.PATCH` and are tagged `vX.Y.Z`. The running version is shown in
the window below the headline and printed by `pitr-config.cmd selftest`, so a bug report can
always name the exact build. What changed between releases is in [CHANGELOG.md](CHANGELOG.md).

## Licence

MIT — see [LICENSE](LICENSE).

This project is not affiliated with or endorsed by Microsoft. "Windows" is a trademark of
Microsoft Corporation.

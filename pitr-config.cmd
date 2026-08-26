@echo off
rem ===========================================================================
rem  pitr-config.cmd
rem  Configures Point-in-time restore / Zeitpunktwiederherstellung (Windows 11).
rem  Bilingual: English / German, the language is detected automatically.
rem
rem  Single file: the complete PowerShell code sits below the #___PSCODE___
rem  marker and is loaded from here. Just double-click it; the file requests
rem  administrator rights itself (UAC) and can be copied anywhere, e.g. onto
rem  a USB stick.
rem
rem  Running it with the argument "selftest" only checks the interface - no
rem  window, no administrator rights, and nothing is written.
rem
rem  IMPORTANT: this file must stay UTF-8 WITHOUT BOM. A BOM makes cmd.exe
rem  trip over the very first line. Non-ASCII characters in the PowerShell
rem  part survive regardless, because the loader reads the file as UTF-8
rem  explicitly instead of relying on the console code page.
rem ===========================================================================
setlocal

if /i "%~1"=="selftest" goto :selftest

net session >nul 2>&1
if "%errorlevel%"=="0" goto :admin
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
exit /b

:admin
set "PITR_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb"
exit /b

:selftest
set "PITR_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb -SelfTest"
exit /b

#___PSCODE___
<#
    Point-in-time restore (PITR) / Zeitpunktwiederherstellung
    Graphical configuration tool, bilingual EN/DE.

    The PITR engine reads its configuration from
        HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Settings
    using the scheme <name>_<level> (DWORD).
        Names  : Active, SnapshotInterval (min), MaxTimespan (min),
                 MaxGlobalSize (MB), MaxCount
        Levels : GPO > CSP > UX (Settings app) > Default

    This tool writes at the GPO level and therefore takes precedence over the
    Settings app. That makes frequency and retention configurable on Windows 11
    Home and Pro as well, where the interface does not offer them.

    Scope: PITR only ever covers the OS volume. PITR.dll rejects anything else
    ("Snapshot is not on the OS volume"), there is no per-volume configuration,
    and a snapshot registry entry carries no volume at all. Other partitions and
    other disks are neither captured nor rolled back.

    The value names are undocumented by Microsoft; they were recovered from
    PITR.dll and RemoteRemediationCSP.dll and verified in practice.
#>

param([switch]$SelfTest)

$ErrorActionPreference = 'Stop'

# The one place the version is defined. It appears under the headline in the window
# and in the selftest; a release is tagged with "v" followed by this value. Keeping
# it out of the batch header above avoids having two numbers that can drift apart.
$Version  = '1.0.0'

$KeyPath  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Settings'
$SnapPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Snapshots'
$TaskPath = '\Microsoft\Windows\Setup\'
$TaskName = 'PITRTask'
$Level    = 'GPO'

# Windows default retention (minutes). Longer values demonstrably work, even
# though Microsoft documents 72 hours as the maximum.
$RetentionDefault = 4320   # 72 Stunden = 3 Tage

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Derive the language from the Windows display language, English as fallback.
$script:Lang = if ((Get-UICulture).TwoLetterISOLanguageName -eq 'de') { 'de' } else { 'en' }

# ------------------------------------------------------------------- Text --
# The name is deliberately long and distinct: PowerShell variables are not
# case-sensitive and are resolved dynamically. A short $S would be shadowed by
# the local $s in Update-View as soon as T() is called from there.
$LangText = @{
    # Der deutsche Untertitel nennt bewusst den englischen Originalbegriff - unter dem
    # findet man Microsofts Dokumentation. Umgekehrt gibt es diesen Bedarf nicht, in der
    # englischen Fassung taucht daher kein deutscher Begriff auf.
    winTitle   = @{ de = 'Zeitpunktwiederherstellung (Point-in-time restore)'; en = 'Point-in-time restore' }
    headline   = @{ de = 'Zeitpunktwiederherstellung';                          en = 'Point-in-time restore' }
    subtitle   = @{ de = 'Point-in-time restore (PITR)';                        en = 'PITR' }
    intro      = @{ de = 'Windows bietet Häufigkeit und Aufbewahrung nur auf der Enterprise-Edition an. Dieses Werkzeug schreibt sie direkt in die Konfiguration der PITR-Engine, die keine Editionsprüfung vornimmt.'
                    en = 'Windows offers frequency and retention on the Enterprise edition only. This tool writes them straight into the PITR engine configuration, which performs no edition check.' }
    btnLang    = @{ de = 'English';                    en = 'Deutsch' }

    grpState   = @{ de = 'Aktueller Zustand';          en = 'Current state' }
    capEdition = @{ de = 'Windows-Edition:';           en = 'Windows edition:' }
    capLast    = @{ de = 'Letzter Lauf:';              en = 'Last run:' }
    capNext    = @{ de = 'Nächster Lauf:';             en = 'Next run:' }
    capDelta   = @{ de = 'Eingeplanter Abstand:';      en = 'Scheduled interval:' }
    capTaskSt  = @{ de = 'Status der Aufgabe:';        en = 'Task status:' }
    tsReady    = @{ de = 'bereit';                     en = 'ready' }
    tsQueued   = @{ de = 'wartet auf Leerlauf des Systems';  en = 'waiting for the system to go idle' }
    tsRunning  = @{ de = 'läuft gerade';               en = 'running right now' }
    tsDisabled = @{ de = 'deaktiviert';                en = 'disabled' }
    tsOverdue  = @{ de = 'überfällig seit';            en = 'overdue by' }
    noteIdle   = @{ de = 'Wiederherstellungspunkte entstehen nur, wenn das System im Leerlauf ist. Wird der Rechner gerade benutzt oder ist er ausgeschaltet, verschiebt sich der Lauf — ein Termin kann dadurch auch ganz ausfallen. Die eingestellte Häufigkeit ist deshalb ein frühestmöglicher Abstand, keine Garantie. Mit „Übernehmen und sofort ausführen" lässt sich jederzeit ein Punkt erzwingen.'
                    en = 'Restore points are only created while the system is idle. If the machine is in use or switched off, the run is postponed — and a scheduled slot may be skipped entirely. The configured frequency is therefore an earliest possible interval, not a guarantee. Use "Apply and run now" to force a point at any time.' }

    grpPoints  = @{ de = 'Wiederherstellungspunkte';   en = 'Restore points' }
    lblCount   = @{ de = 'Anzahl';                     en = 'Count' }
    lblOldest  = @{ de = 'Ältester Punkt';             en = 'Oldest point' }
    lblStorage = @{ de = 'Speicher auf Laufwerk';      en = 'Storage on drive' }
    stUsed     = @{ de = 'belegt';                     en = 'in use' }
    stAlloc    = @{ de = 'reserviert';                 en = 'reserved' }
    stMax      = @{ de = 'Grenze';                     en = 'limit' }
    stNoAdmin  = @{ de = 'nicht abrufbar (Administratorrechte erforderlich)'; en = 'unavailable (administrator rights required)' }
    noteStore  = @{ de = 'Windows weist den belegten Speicher nur für das gesamte Laufwerk aus, nicht je einzelnem Punkt — die Punkte teilen sich einen gemeinsamen Differenzbereich.'
                    en = 'Windows reports storage per drive only, never per point — all points share one common difference area.' }
    tipStore   = @{ de = 'Belegt = tatsächlich von Schattenkopien beschriebene Daten.' + [Environment]::NewLine +
                         'Reserviert = Platz, den VSS bereits auf der Platte abgesteckt hat. Er steht anderen Dateien nicht mehr zur Verfügung, ist aber noch nicht vollständig gefüllt.' + [Environment]::NewLine +
                         'Grenze = konfigurierte Obergrenze; darüber hinaus wächst der Bereich nicht.'
                    en = 'In use = data actually written by shadow copies.' + [Environment]::NewLine +
                         'Reserved = space VSS has already claimed on disk. It is no longer available to other files but is not yet fully filled.' + [Environment]::NewLine +
                         'Limit = configured ceiling; the area never grows beyond it.' }
    # {0} wird zur Laufzeit durch das Windows-Laufwerk ersetzt.
    noteVolume = @{ de = 'Erfasst wird ausschließlich das Windows-Laufwerk {0}. Weitere Partitionen und weitere Festplatten bleiben außen vor — auch wenn sie auf derselben physischen Platte liegen. Sie werden weder gesichert noch bei einer Wiederherstellung zurückgesetzt; für Daten dort ist weiterhin eine eigene Sicherung nötig. Auch die Speichergrenze weiter unten gilt allein für {0}.'
                    en = 'Only the Windows drive {0} is covered. Other partitions and other disks are left out — even when they sit on the same physical disk. They are neither captured nor rolled back during a restore, so data there still needs a backup of its own. The storage limit below likewise applies to {0} alone.' }

    colTime    = @{ de = 'Zeitpunkt';                  en = 'Time' }
    colAge     = @{ de = 'Alter';                      en = 'Age' }
    colStatus  = @{ de = 'Status';                     en = 'Status' }
    colBuild   = @{ de = 'Build';                      en = 'Build' }
    stShadowOk = @{ de = 'Schattenkopie vorhanden';    en = 'shadow copy present' }
    stRegOnly  = @{ de = 'nur Registry-Eintrag';       en = 'registry entry only' }
    stUnknown  = @{ de = 'unbekannt (Adminrechte nötig)'; en = 'unknown (needs admin rights)' }

    grpSet     = @{ de = 'Einstellungen';              en = 'Settings' }
    capActive  = @{ de = 'Feature aktiv';              en = 'Feature enabled' }
    capFreq    = @{ de = 'Häufigkeit — Abstand zwischen Wiederherstellungspunkten'; en = 'Frequency — interval between restore points' }
    capReten   = @{ de = 'Aufbewahrung — Lebensdauer eines Wiederherstellungspunkts'; en = 'Retention — lifetime of a restore point' }
    capSize    = @{ de = 'Maximaler Speicherplatz für alle Wiederherstellungspunkte'; en = 'Maximum storage for all restore points' }

    optNoOver  = @{ de = 'Windows-Standard (nicht überschreiben)'; en = 'Windows default (do not override)' }
    optOn      = @{ de = 'Ein';                        en = 'On' }
    optOff     = @{ de = 'Aus';                        en = 'Off' }
    optStdFreq = @{ de = 'Windows-Standard (24 Stunden)'; en = 'Windows default (24 hours)' }
    optStdRet  = @{ de = 'Windows-Standard (3 Tage / 72 Stunden)'; en = 'Windows default (3 days / 72 hours)' }
    unitHour   = @{ de = 'Stunde';                     en = 'hour' }
    unitHours  = @{ de = 'Stunden';                    en = 'hours' }
    unitDay    = @{ de = 'Tag';                        en = 'day' }
    unitDays   = @{ de = 'Tage';                       en = 'days' }
    unitMin    = @{ de = 'Minuten';                    en = 'minutes' }

    btnReset   = @{ de = 'Alles zurücksetzen';         en = 'Reset everything' }
    btnRefresh = @{ de = 'Aktualisieren';              en = 'Refresh' }
    btnApply   = @{ de = 'Übernehmen';                 en = 'Apply' }
    btnApplyNow= @{ de = 'Übernehmen und sofort ausführen'; en = 'Apply and run now' }
    grpLog     = @{ de = 'Protokoll';                  en = 'Log' }

    effective  = @{ de = 'Aktuell wirksam';            en = 'Currently effective' }
    source     = @{ de = 'Quelle';                     en = 'source' }
    winDefault = @{ de = 'Windows-Standard';           en = 'Windows default' }
    srcGPO     = @{ de = 'Richtlinie (dieses Werkzeug)'; en = 'policy (this tool)' }
    srcCSP     = @{ de = 'Intune/MDM';                 en = 'Intune/MDM' }
    srcUX      = @{ de = 'Einstellungen-App';          en = 'Settings app' }
    sizeStd    = @{ de = 'Windows-Standard (2% der Platte)'; en = 'Windows default (2% of the disk)' }

    carryOver  = @{ de = 'stammt noch aus der vorherigen Einstellung; wird beim nächsten Lauf angepasst auf'
                    en = 'still stems from the previous setting; will be adjusted on the next run to' }
    proven72   = @{ de = 'älter als 72 Stunden: die erweiterte Aufbewahrung wirkt nachweislich'
                    en = 'older than 72 hours: the extended retention demonstrably works' }
    unofficial = @{ de = 'Inoffizielle Lösung: Die hier gesetzten Konfigurationswerte sind von Microsoft nicht dokumentiert und können sich mit künftigen Windows-Versionen ändern. „Alles zurücksetzen" stellt jederzeit den Windows-Standard wieder her.'
                    en = 'Unofficial approach: the configuration values written here are undocumented by Microsoft and may change with future Windows releases. "Reset everything" restores the Windows default at any time.' }
    taskMissing= @{ de = 'PITRTask nicht gefunden';    en = 'PITRTask not found' }
    unknownTxt = @{ de = 'unbekannt';                  en = 'unknown' }

    logReady   = @{ de = 'Bereit. Werte werden auf Level "Richtlinie" gesetzt und haben Vorrang vor der Einstellungen-App.'
                    en = 'Ready. Values are written at policy level and take precedence over the Settings app.' }
    logNoAdmin = @{ de = 'WARNUNG: Ohne Administratorrechte lassen sich keine Werte speichern.'
                    en = 'WARNING: without administrator rights no values can be saved.' }
    logRefresh = @{ de = 'Ansicht aktualisiert.';      en = 'View refreshed.' }
    logSaved   = @{ de = 'Gespeichert. Wirksam beim nächsten Lauf von PITRTask (der läuft nur im Leerlauf).'
                    en = 'Saved. Takes effect on the next PITRTask run (it only runs when the system is idle).' }
    logCleared = @{ de = 'Überschreibung entfernt -> Windows-Standard'; en = 'override removed -> Windows default' }
    logIdleOff = @{ de = 'Leerlauf-Bedingung vorübergehend aufgehoben.'; en = 'Idle condition temporarily lifted.' }
    logStarted = @{ de = 'PITRTask gestartet, warte auf Abschluss...'; en = 'PITRTask started, waiting for completion...' }
    logIdleOn  = @{ de = 'Leerlauf-Bedingung wiederhergestellt.'; en = 'Idle condition restored.' }
    logIdleErr = @{ de = 'Leerlauf-Bedingung nach Fehler wiederhergestellt.'; en = 'Idle condition restored after an error.' }
    logIdleBad = @{ de = 'WARNUNG: Leerlauf-Bedingung konnte nicht wiederhergestellt werden!'; en = 'WARNING: could not restore the idle condition!' }
    logDone    = @{ de = 'Fertig. Ergebnis';           en = 'Done. Result' }
    logNextRun = @{ de = 'nächster Lauf';              en = 'next run' }
    logRemoved = @{ de = 'entfernt';                   en = 'removed' }
    logNothing = @{ de = 'Es waren keine Werte gesetzt.'; en = 'No values were set.' }
    logError   = @{ de = 'Fehler';                     en = 'Error' }
    askReset   = @{ de = 'Alle von diesem Werkzeug gesetzten Werte entfernen und zum Windows-Standard zurückkehren?'
                    en = 'Remove every value set by this tool and return to the Windows default?' }
    askResetT  = @{ de = 'Zurücksetzen';               en = 'Reset' }
}

function T { param([string]$Key) return $LangText[$Key][$script:Lang] }

function Test-Admin {
    ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ------------------------------------------------------------ Registry-Layer --
$LevelOrder = @('GPO', 'CSP', 'UX')

function Get-LevelLabel {
    param([string]$Lvl)
    switch ($Lvl) { 'GPO' { T 'srcGPO' } 'CSP' { T 'srcCSP' } default { T 'srcUX' } }
}

function Get-PitrValue {
    param([string]$Name)
    foreach ($lvl in $LevelOrder) {
        $vn = "${Name}_$lvl"
        $v = (Get-ItemProperty -Path $KeyPath -Name $vn -ErrorAction SilentlyContinue).$vn
        if ($null -ne $v) { return [pscustomobject]@{ Value = [int]$v; Level = $lvl } }
    }
    return $null
}

function Set-PitrValue {
    param([string]$Name, [int]$Value)
    if (-not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force | Out-Null }
    New-ItemProperty -Path $KeyPath -Name "${Name}_$Level" -Value $Value -PropertyType DWord -Force | Out-Null
}

function Remove-PitrValue {
    param([string]$Name)
    $vn = "${Name}_$Level"
    if ($null -ne (Get-ItemProperty -Path $KeyPath -Name $vn -ErrorAction SilentlyContinue).$vn) {
        Remove-ItemProperty -Path $KeyPath -Name $vn -Force
        return $true
    }
    return $false
}

function Format-Duration {
    param([int]$Minutes)
    $h = $Minutes / 60
    if ($Minutes % 1440 -eq 0 -and $Minutes -ge 1440) {
        $d = $Minutes / 1440
        $du = if ($d -eq 1) { T 'unitDay' } else { T 'unitDays' }
        return "$d $du ($h $(T 'unitHours'))"
    }
    $hr = [math]::Round($h, 1)
    $hu = if ($hr -eq 1) { T 'unitHour' } else { T 'unitHours' }
    return "$hr $hu"
}

function Format-Age {
    param([double]$Hours)
    if ($Hours -lt 48) { return ('{0:N1} h' -f $Hours) }
    return ('{0:N1} {1}' -f ($Hours / 24), (T 'unitDays'))
}

# Restore points: timestamps from the registry (TimeUTC = 8-byte FILETIME),
# reconciled against the VSS shadow copies that actually exist. A registry entry
# without a matching shadow copy is a leftover and cannot be restored from.
function Get-RestorePoints {
    # Without administrator rights the VSS query fails. The status must then stay
    # open instead of falsely claiming "registry entry only".
    $vss = @{}
    $vssOk = $false
    try {
        foreach ($c in (Get-CimInstance Win32_ShadowCopy -ErrorAction Stop)) { $vss["$($c.ID)"] = $true }
        $vssOk = $true
    } catch { }

    $now = Get-Date
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($k in (Get-ChildItem -Path $SnapPath -ErrorAction SilentlyContinue)) {
        $p = Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue
        if (-not $p) { continue }
        $b = $p.TimeUTC
        $dt = $null
        if ($b -is [byte[]] -and $b.Length -eq 8) {
            try { $dt = [DateTime]::FromFileTimeUtc([BitConverter]::ToInt64($b, 0)).ToLocalTime() } catch { }
        }
        $ageH = if ($dt) { ($now - $dt).TotalHours } else { $null }
        $list.Add([pscustomobject]@{
            Sortier   = if ($dt) { $dt } else { [DateTime]::MinValue }
            AlterStd  = $ageH
            Zeitpunkt = if ($dt) { $dt.ToString('dd.MM.yyyy  HH:mm') } else { T 'unknownTxt' }
            Alter     = if ($null -ne $ageH) { Format-Age $ageH } else { '-' }
            Status    = if (-not $vssOk) { T 'stUnknown' }
                        elseif ($vss.ContainsKey("$($p.Id)")) { T 'stShadowOk' }
                        else { T 'stRegOnly' }
            Version   = "$($p.Build).$($p.Revision)"
        })
    }
    return @($list | Sort-Object Sortier -Descending)
}

# VSS reports storage per drive only, never per individual point. The query is
# pinned to the OS volume rather than taking whatever comes first, because that is
# the only volume PITR ever touches - other volumes may well carry shadow copies
# from unrelated tools, and those figures would be misleading here.
#   UsedSpace      = data actually written by the shadow copies
#   AllocatedSpace = difference area already claimed on disk (>= Used)
#   MaxSpace       = configured ceiling
function Get-ShadowStorage {
    try {
        $osVol = (Get-CimInstance Win32_Volume -Filter "DriveLetter='$env:SystemDrive'" -ErrorAction Stop).DeviceID
        $s = Get-CimInstance Win32_ShadowStorage -ErrorAction Stop |
             Where-Object { $_.Volume.DeviceID -eq $osVol } | Select-Object -First 1
        if ($s) {
            return [pscustomobject]@{
                Drive = $env:SystemDrive
                Used  = [double]$s.UsedSpace
                Alloc = [double]$s.AllocatedSpace
                Max   = [double]$s.MaxSpace
            }
        }
    } catch { }
    return $null
}

# --------------------------------------------------------------- User interface --
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="790" Height="880" MaxHeight="900" MinWidth="720" MinHeight="480"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize" Background="#F5F5F5"
        FontFamily="Segoe UI" FontSize="13">
  <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
    <StackPanel Margin="18">

    <Grid Margin="0,0,0,14">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock x:Name="TxtHead" FontSize="21" FontWeight="SemiBold"/>
        <TextBlock x:Name="TxtSub" FontSize="13" Foreground="#777" Margin="0,1,0,0"/>
        <TextBlock x:Name="TxtIntro" Foreground="#555" TextWrapping="Wrap" Margin="0,6,0,0"/>
        <Border BorderBrush="#D9B36A" BorderThickness="1" Background="#FFF8E7"
                Padding="9,7" Margin="0,10,0,0">
          <TextBlock x:Name="TxtUnofficial" TextWrapping="Wrap" Foreground="#6B5210" FontSize="12"/>
        </Border>
      </StackPanel>
      <Button x:Name="BtnLang" Grid.Column="1" Width="96" Height="28"
              VerticalAlignment="Top" Margin="12,2,0,0"/>
    </Grid>

    <GroupBox x:Name="GrpState" Padding="12" Margin="0,0,0,14">
      <StackPanel>
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <TextBlock x:Name="CapEdition" Grid.Row="0" Grid.Column="0" Margin="0,0,10,4"/>
          <TextBlock x:Name="TxtEdition" Grid.Row="0" Grid.Column="1" Text="-" Margin="0,0,0,4" TextWrapping="Wrap"/>
          <TextBlock x:Name="CapLast" Grid.Row="1" Grid.Column="0" Margin="0,0,10,4"/>
          <TextBlock x:Name="TxtLast" Grid.Row="1" Grid.Column="1" Text="-" Margin="0,0,0,4"/>
          <TextBlock x:Name="CapNext" Grid.Row="2" Grid.Column="0" Margin="0,0,10,4"/>
          <TextBlock x:Name="TxtNext" Grid.Row="2" Grid.Column="1" Text="-" Margin="0,0,0,4" TextWrapping="Wrap"/>
          <TextBlock x:Name="CapTaskState" Grid.Row="3" Grid.Column="0" Margin="0,0,10,4"/>
          <TextBlock x:Name="TxtTaskState" Grid.Row="3" Grid.Column="1" Text="-" Margin="0,0,0,4" TextWrapping="Wrap"/>
          <TextBlock x:Name="CapDelta" Grid.Row="4" Grid.Column="0" Margin="0,0,10,0"/>
          <TextBlock x:Name="TxtDelta" Grid.Row="4" Grid.Column="1" Text="-" TextWrapping="Wrap"/>
        </Grid>
        <Border BorderBrush="#C9D6E4" BorderThickness="1" Background="#EEF4FA"
                Padding="9,7" Margin="0,10,0,0">
          <TextBlock x:Name="TxtIdleNote" TextWrapping="Wrap" Foreground="#2C4A66" FontSize="12"/>
        </Border>
      </StackPanel>
    </GroupBox>

    <GroupBox x:Name="GrpPoints" Padding="12" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock x:Name="TxtPoints" Text="-" Margin="0,0,0,2"/>
        <TextBlock x:Name="TxtOldest" Text="-" Margin="0,0,0,6" TextWrapping="Wrap"/>
        <TextBlock x:Name="TxtStorage" Text="-" Margin="0,0,0,2" TextWrapping="Wrap"/>
        <TextBlock x:Name="TxtStoreNote" Foreground="#666" FontSize="11" TextWrapping="Wrap" Margin="0,0,0,8"/>
        <ListView x:Name="LstPoints" Height="150" BorderThickness="1" BorderBrush="#DDD"
                  ScrollViewer.HorizontalScrollBarVisibility="Disabled">
          <ListView.View>
            <GridView>
              <GridViewColumn Width="150" DisplayMemberBinding="{Binding Zeitpunkt}"/>
              <GridViewColumn Width="90"  DisplayMemberBinding="{Binding Alter}"/>
              <GridViewColumn Width="210" DisplayMemberBinding="{Binding Status}"/>
              <GridViewColumn Width="110" DisplayMemberBinding="{Binding Version}"/>
            </GridView>
          </ListView.View>
        </ListView>
        <Border BorderBrush="#C9D6E4" BorderThickness="1" Background="#EEF4FA"
                Padding="9,7" Margin="0,10,0,0">
          <TextBlock x:Name="TxtVolumeNote" TextWrapping="Wrap" Foreground="#2C4A66" FontSize="12"/>
        </Border>
      </StackPanel>
    </GroupBox>

    <GroupBox x:Name="GrpSet" Padding="12" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock x:Name="CapActive" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbActive" Margin="0,4,0,2"/>
        <TextBlock x:Name="LblActive" Foreground="#666" FontSize="11" Margin="0,0,0,12" TextWrapping="Wrap"/>

        <TextBlock x:Name="CapFreq" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbFreq" Margin="0,4,0,2"/>
        <TextBlock x:Name="LblFreq" Foreground="#666" FontSize="11" Margin="0,0,0,12" TextWrapping="Wrap"/>

        <TextBlock x:Name="CapReten" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbReten" Margin="0,4,0,2"/>
        <TextBlock x:Name="LblReten" Foreground="#666" FontSize="11" Margin="0,0,0,12" TextWrapping="Wrap"/>

        <TextBlock x:Name="CapSize" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbSize" Margin="0,4,0,2"/>
        <TextBlock x:Name="LblSize" Foreground="#666" FontSize="11" TextWrapping="Wrap"/>
      </StackPanel>
    </GroupBox>

    <Grid Margin="0,0,0,12">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="Auto"/>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>
      <Button x:Name="BtnReset" Grid.Column="0" Width="170" Height="34" HorizontalAlignment="Left"/>
      <StackPanel Grid.Column="2" Orientation="Horizontal">
        <Button x:Name="BtnRefresh"  Width="120" Height="34" Margin="0,0,8,0"/>
        <Button x:Name="BtnApply"    Width="130" Height="34" Margin="0,0,8,0"/>
        <Button x:Name="BtnApplyNow" Width="230" Height="34"/>
      </StackPanel>
    </Grid>

    <GroupBox x:Name="GrpLog" Padding="8">
      <TextBox x:Name="TxtLog" IsReadOnly="True" TextWrapping="Wrap"
               VerticalScrollBarVisibility="Auto" Height="110"
               BorderThickness="1" BorderBrush="#DDD" Background="White"
               Padding="6" FontFamily="Consolas" FontSize="12"/>
    </GroupBox>

    </StackPanel>
  </ScrollViewer>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$ctl = @{}
foreach ($n in 'TxtHead','TxtSub','TxtIntro','TxtUnofficial','BtnLang',
               'GrpState','CapEdition','TxtEdition','CapLast','TxtLast','CapNext','TxtNext',
               'CapTaskState','TxtTaskState','CapDelta','TxtDelta','TxtIdleNote',
               'GrpPoints','TxtPoints','TxtOldest','TxtStorage','TxtStoreNote','LstPoints',
               'TxtVolumeNote',
               'GrpSet','CapActive','CmbActive','LblActive','CapFreq','CmbFreq','LblFreq',
               'CapReten','CmbReten','LblReten','CapSize','CmbSize','LblSize',
               'BtnReset','BtnRefresh','BtnApply','BtnApplyNow','GrpLog','TxtLog') {
    $ctl[$n] = $window.FindName($n)
}

# ---------------------------------------------------------------- Helpers --
function Write-Log {
    param([string]$Text)
    $stamp = (Get-Date).ToString('HH:mm:ss')
    $ctl.TxtLog.AppendText("[$stamp] $Text`r`n")
    $ctl.TxtLog.ScrollToEnd()
}

# Keeps the window repainting while work is in progress.
function Update-Ui {
    $window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
}

function Add-Choice {
    param($Combo, [string]$Text, $TagValue)
    $i = New-Object System.Windows.Controls.ComboBoxItem
    $i.Content = $Text
    $i.Tag = if ($null -eq $TagValue) { '' } else { [string]$TagValue }
    $Combo.Items.Add($i) | Out-Null
}

function Select-ByTag {
    param($Combo, $TagValue)
    $target = if ($null -eq $TagValue) { '' } else { [string]$TagValue }
    foreach ($item in $Combo.Items) {
        if ([string]$item.Tag -eq $target) { $Combo.SelectedItem = $item; return }
    }
    $Combo.SelectedIndex = 0
}

function Get-SelectedTag {
    param($Combo)
    if (-not $Combo.SelectedItem) { return $null }
    $t = [string]$Combo.SelectedItem.Tag
    if ([string]::IsNullOrEmpty($t)) { return $null }
    return [int]$t
}

# The drop-down lists are built from code so that a language switch can relabel
# them without losing the current selection.
function Build-Choices {
    $keep = @{}
    foreach ($n in 'CmbActive', 'CmbFreq', 'CmbReten', 'CmbSize') {
        $keep[$n] = if ($ctl[$n].SelectedItem) { [string]$ctl[$n].SelectedItem.Tag } else { '' }
        $ctl[$n].Items.Clear()
    }

    Add-Choice $ctl.CmbActive (T 'optNoOver') $null
    Add-Choice $ctl.CmbActive (T 'optOn')  1
    Add-Choice $ctl.CmbActive (T 'optOff') 0

    Add-Choice $ctl.CmbFreq (T 'optStdFreq') $null
    foreach ($h in 1, 2, 4, 6, 8, 12, 16, 24) {
        $u = if ($h -eq 1) { T 'unitHour' } else { T 'unitHours' }
        Add-Choice $ctl.CmbFreq "$h $u" ($h * 60)
    }

    Add-Choice $ctl.CmbReten (T 'optStdRet') $null
    foreach ($d in 1, 2, 3, 4, 5, 6, 7) {
        $du = if ($d -eq 1) { T 'unitDay' } else { T 'unitDays' }
        Add-Choice $ctl.CmbReten "$d $du ($($d * 24) $(T 'unitHours'))" ($d * 1440)
    }

    Add-Choice $ctl.CmbSize (T 'optNoOver') $null
    foreach ($g in 2, 4, 6, 8, 10, 12, 16, 20, 25, 30, 40, 50) {
        Add-Choice $ctl.CmbSize "$g GB" ($g * 1024)
    }

    foreach ($n in 'CmbActive', 'CmbFreq', 'CmbReten', 'CmbSize') {
        Select-ByTag $ctl[$n] $keep[$n]
    }
}

function Apply-Language {
    $window.Title        = T 'winTitle'
    $ctl.TxtHead.Text    = T 'headline'
    $ctl.TxtSub.Text     = "$(T 'subtitle')  ·  Version $Version"
    $ctl.TxtIntro.Text       = T 'intro'
    $ctl.TxtUnofficial.Text  = T 'unofficial'
    $ctl.BtnLang.Content     = T 'btnLang'

    $ctl.GrpState.Header  = T 'grpState'
    $ctl.CapEdition.Text  = T 'capEdition'
    $ctl.CapLast.Text     = T 'capLast'
    $ctl.CapNext.Text      = T 'capNext'
    $ctl.CapTaskState.Text = T 'capTaskSt'
    $ctl.CapDelta.Text     = T 'capDelta'
    $ctl.TxtIdleNote.Text  = T 'noteIdle'

    $ctl.GrpPoints.Header   = T 'grpPoints'
    $ctl.TxtStoreNote.Text  = T 'noteStore'
    $ctl.TxtStorage.ToolTip = T 'tipStore'
    $ctl.TxtVolumeNote.Text = (T 'noteVolume') -f $env:SystemDrive

    $cols = $ctl.LstPoints.View.Columns
    $cols[0].Header = T 'colTime'
    $cols[1].Header = T 'colAge'
    $cols[2].Header = T 'colStatus'
    $cols[3].Header = T 'colBuild'

    $ctl.GrpSet.Header  = T 'grpSet'
    $ctl.CapActive.Text = T 'capActive'
    $ctl.CapFreq.Text   = T 'capFreq'
    $ctl.CapReten.Text  = T 'capReten'
    $ctl.CapSize.Text   = T 'capSize'

    $ctl.BtnReset.Content    = T 'btnReset'
    $ctl.BtnRefresh.Content  = T 'btnRefresh'
    $ctl.BtnApply.Content    = T 'btnApply'
    $ctl.BtnApplyNow.Content = T 'btnApplyNow'
    $ctl.GrpLog.Header       = T 'grpLog'

    Build-Choices
}

function Update-View {
    # Read the values first so the task state can be interpreted against them.
    $a = Get-PitrValue 'Active'
    $f = Get-PitrValue 'SnapshotInterval'
    $r = Get-PitrValue 'MaxTimespan'
    $s = Get-PitrValue 'MaxGlobalSize'
    $effFreq = if ($null -eq $f) { 1440 } else { $f.Value }

    $nt = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $ctl.TxtEdition.Text = "$($nt.ProductName) (EditionID: $($nt.EditionID))"

    # --- Restore points ---
    $punkte = @(Get-RestorePoints)
    $ctl.LstPoints.ItemsSource = $punkte
    $ctl.TxtPoints.Text = "$(T 'lblCount'): $($punkte.Count)"

    # The oldest point shows directly whether the configured retention takes effect.
    $mitZeit = @($punkte | Where-Object { $null -ne $_.AlterStd })
    if ($mitZeit.Count -gt 0) {
        $aeltest = ($mitZeit | Sort-Object AlterStd -Descending)[0]
        $ot = "$(T 'lblOldest'): $($aeltest.Zeitpunkt) ($($aeltest.Alter))"
        if ($aeltest.AlterStd -gt 72.5) {
            $ot += '  —  ' + (T 'proven72')
            $ctl.TxtOldest.Foreground = [System.Windows.Media.Brushes]::DarkGreen
        } else {
            $ctl.TxtOldest.Foreground = [System.Windows.Media.Brushes]::Black
        }
        $ctl.TxtOldest.Text = $ot
    } else {
        $ctl.TxtOldest.Text = "$(T 'lblOldest'): -"
    }

    $st = Get-ShadowStorage
    if ($st) {
        $ctl.TxtStorage.Text = ('{0} {1} — {2} {3:N2} GB · {4} {5:N2} GB · {6} {7:N2} GB' -f
            (T 'lblStorage'), $st.Drive, (T 'stUsed'), ($st.Used / 1GB), (T 'stAlloc'), ($st.Alloc / 1GB),
            (T 'stMax'), ($st.Max / 1GB))
    } else {
        $ctl.TxtStorage.Text = ('{0} {1} — {2}' -f (T 'lblStorage'), $env:SystemDrive, (T 'stNoAdmin'))
    }

    # --- Scheduled task ---
    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        $info = Get-ScheduledTaskInfo -TaskPath $TaskPath -TaskName $TaskName
        $ctl.TxtLast.Text = "$($info.LastRunTime)"

        # Der Lauf findet nur im Leerlauf statt - ein ueberfaelliger Termin ist daher
        # kein Fehler, sondern der Normalfall an einem benutzten Rechner.
        $nextTxt = "$($info.NextRunTime)"
        if ($info.NextRunTime -and $info.NextRunTime -lt (Get-Date)) {
            $due = [math]::Round(((Get-Date) - $info.NextRunTime).TotalMinutes)
            $nextTxt += "  —  $(T 'tsOverdue') $due $(T 'unitMin')"
            $ctl.TxtNext.Foreground = [System.Windows.Media.Brushes]::DarkOrange
        } else {
            $ctl.TxtNext.Foreground = [System.Windows.Media.Brushes]::Black
        }
        $ctl.TxtNext.Text = $nextTxt

        # "Queued" heisst wortwoertlich: Der Lauf ist faellig, wartet aber auf Leerlauf.
        $stateName = "$($task.State)"
        $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::Black
        switch ($stateName) {
            'Ready'    { $ctl.TxtTaskState.Text = T 'tsReady' }
            'Queued'   { $ctl.TxtTaskState.Text = T 'tsQueued'
                         $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::DarkOrange }
            'Running'  { $ctl.TxtTaskState.Text = T 'tsRunning'
                         $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::DarkGreen }
            'Disabled' { $ctl.TxtTaskState.Text = T 'tsDisabled'
                         $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::DarkOrange }
            default    { $ctl.TxtTaskState.Text = $stateName }
        }

        if ($info.LastRunTime -and $info.NextRunTime) {
            $d = [math]::Round(($info.NextRunTime - $info.LastRunTime).TotalMinutes)
            $txt = "$d $(T 'unitMin') = $([math]::Round($d/60,1)) $(T 'unitHours')"
            # PITRTask recalculates its next run only while running. If the scheduled
            # interval differs from the configured frequency, it still stems from the
            # previous setting - not a contradiction, just a carry-over.
            # One minute of tolerance to absorb rounding of seconds.
            if ([math]::Abs($d - $effFreq) -gt 1) {
                $txt += '  —  ' + (T 'carryOver') + " $([math]::Round($effFreq/60,1)) $(T 'unitHours')"
                $ctl.TxtDelta.Foreground = [System.Windows.Media.Brushes]::DarkOrange
            } else {
                $ctl.TxtDelta.Foreground = [System.Windows.Media.Brushes]::Black
            }
            $ctl.TxtDelta.Text = $txt
        } else {
            $ctl.TxtDelta.Text = T 'unknownTxt'
        }
    } catch {
        $ctl.TxtLast.Text      = T 'taskMissing'
        $ctl.TxtNext.Text      = '-'
        $ctl.TxtTaskState.Text = '-'
        $ctl.TxtDelta.Text     = '-'
    }

    # The drop-downs show our own (policy) values only; other levels stay on "default".
    Select-ByTag $ctl.CmbActive $(if ($a -and $a.Level -eq $Level) { $a.Value } else { $null })
    Select-ByTag $ctl.CmbFreq   $(if ($f -and $f.Level -eq $Level) { $f.Value } else { $null })
    Select-ByTag $ctl.CmbReten  $(if ($r -and $r.Level -eq $Level) { $r.Value } else { $null })
    Select-ByTag $ctl.CmbSize   $(if ($s -and $s.Level -eq $Level) { $s.Value } else { $null })

    $eff = T 'effective'
    $src = T 'source'

    $ctl.LblActive.Text = if ($null -eq $a) { "${eff}: $(T 'winDefault')" }
                          else { "${eff}: $(if ($a.Value -eq 1) { T 'optOn' } else { T 'optOff' }) — ${src}: $(Get-LevelLabel $a.Level)" }

    $ctl.LblFreq.Text   = if ($null -eq $f) { "${eff}: 24 $(T 'unitHours') ($(T 'winDefault'))" }
                          else { "${eff}: $(Format-Duration $f.Value) — ${src}: $(Get-LevelLabel $f.Level)" }

    # Retention beyond 72 hours was confirmed in practice (a point aged 3.7 days
    # survived), so no special warning is shown here any more.
    $ctl.LblReten.Text = if ($null -eq $r) { "${eff}: $(Format-Duration $RetentionDefault) ($(T 'winDefault'))" }
                         else { "${eff}: $(Format-Duration $r.Value) — ${src}: $(Get-LevelLabel $r.Level)" }
    $ctl.LblReten.Foreground = [System.Windows.Media.Brushes]::Gray

    $ctl.LblSize.Text   = if ($null -eq $s) { "${eff}: $(T 'sizeStd')" }
                          else { "${eff}: $([math]::Round($s.Value/1024,1)) GB — ${src}: $(Get-LevelLabel $s.Level)" }
}

function Save-Settings {
    $map = @(
        @{ Name = 'Active';           Combo = $ctl.CmbActive; Text = (T 'capActive') }
        @{ Name = 'SnapshotInterval'; Combo = $ctl.CmbFreq;   Text = 'SnapshotInterval' }
        @{ Name = 'MaxTimespan';      Combo = $ctl.CmbReten;  Text = 'MaxTimespan' }
        @{ Name = 'MaxGlobalSize';    Combo = $ctl.CmbSize;   Text = 'MaxGlobalSize' }
    )
    foreach ($m in $map) {
        $val = Get-SelectedTag $m.Combo
        if ($null -eq $val) {
            if (Remove-PitrValue $m.Name) { Write-Log "$($m.Name): $(T 'logCleared')" }
        } else {
            Set-PitrValue $m.Name $val
            Write-Log "$($m.Name)_$Level = $val"
        }
    }
}

function Invoke-TaskNow {
    # PITRTask has RunOnlyIfIdle=True and stays "Queued" while the machine is in use.
    # Lift that condition for exactly one run and restore it reliably afterwards.
    $restored = $false
    try {
        $t = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        $orig = $t.Settings.RunOnlyIfIdle
        $t.Settings.RunOnlyIfIdle = $false
        Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Settings $t.Settings | Out-Null
        Write-Log (T 'logIdleOff')
        Update-Ui

        Start-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        Write-Log (T 'logStarted')
        Update-Ui

        for ($i = 0; $i -lt 60; $i++) {
            Start-Sleep -Milliseconds 1500
            Update-Ui
            if ((Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName).State -eq 'Ready') { break }
        }

        $t2 = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        $t2.Settings.RunOnlyIfIdle = $orig
        Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Settings $t2.Settings | Out-Null
        $restored = $true
        Write-Log (T 'logIdleOn')

        $info = Get-ScheduledTaskInfo -TaskPath $TaskPath -TaskName $TaskName
        Write-Log "$(T 'logDone'): $($info.LastTaskResult), $(T 'logNextRun'): $($info.NextRunTime)"
    } finally {
        if (-not $restored) {
            try {
                $t3 = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
                $t3.Settings.RunOnlyIfIdle = $true
                Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Settings $t3.Settings | Out-Null
                Write-Log (T 'logIdleErr')
            } catch {
                Write-Log (T 'logIdleBad')
            }
        }
    }
}

function Set-Busy {
    param([bool]$On)
    foreach ($b in 'BtnReset','BtnRefresh','BtnApply','BtnApplyNow','BtnLang') { $ctl[$b].IsEnabled = -not $On }
    $window.Cursor = if ($On) { [System.Windows.Input.Cursors]::Wait } else { $null }
    Update-Ui
}

# --------------------------------------------------------------------- Events --
$ctl.BtnLang.Add_Click({
    $script:Lang = if ($script:Lang -eq 'de') { 'en' } else { 'de' }
    try { Apply-Language; Update-View }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

$ctl.BtnRefresh.Add_Click({
    try { Update-View; Write-Log (T 'logRefresh') }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

$ctl.BtnApply.Add_Click({
    Set-Busy $true
    try { Save-Settings; Update-View; Write-Log (T 'logSaved') }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

$ctl.BtnApplyNow.Add_Click({
    Set-Busy $true
    try { Save-Settings; Invoke-TaskNow; Update-View }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

$ctl.BtnReset.Add_Click({
    $answer = [System.Windows.MessageBox]::Show((T 'askReset'), (T 'askResetT'),
        [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
    Set-Busy $true
    try {
        $n = 0
        foreach ($name in 'Active','SnapshotInterval','MaxTimespan','MaxGlobalSize','MaxCount') {
            if (Remove-PitrValue $name) { Write-Log "$(T 'logRemoved'): ${name}_$Level"; $n++ }
        }
        if ($n -eq 0) { Write-Log (T 'logNothing') }
        Update-View
    }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

# ---------------------------------------------------------------------- Start --
Apply-Language
Update-View

if ($SelfTest) {
    foreach ($l in 'de', 'en') {
        $script:Lang = $l
        Apply-Language
        Update-View
        Write-Host "===== Sprache: $l ====="
        Write-Host "  Titel        : $($window.Title)"
        Write-Host "  Untertitel   : $($ctl.TxtSub.Text)"
        Write-Host "  Hoehe/Max    : $($window.Height) / $($window.MaxHeight)"
        Write-Host "  Sprachknopf  : $($ctl.BtnLang.Content)"
        Write-Host "  Hinweisbox   : $($ctl.TxtUnofficial.Text)"
        Write-Host "  Leerlauf-Box : $($ctl.TxtIdleNote.Text)"
        Write-Host "  Laufwerk-Box : $($ctl.TxtVolumeNote.Text)"
        Write-Host "  Aufgabe      : $($ctl.CapTaskState.Text) $($ctl.TxtTaskState.Text)"
        Write-Host "  Naechster    : $($ctl.TxtNext.Text)"
        Write-Host "  Gruppen      : $($ctl.GrpState.Header) | $($ctl.GrpPoints.Header) | $($ctl.GrpSet.Header) | $($ctl.GrpLog.Header)"
        Write-Host "  Spalten      : $(($ctl.LstPoints.View.Columns | ForEach-Object { $_.Header }) -join ' | ')"
        Write-Host "  Knoepfe      : $($ctl.BtnReset.Content) | $($ctl.BtnRefresh.Content) | $($ctl.BtnApply.Content) | $($ctl.BtnApplyNow.Content)"
        Write-Host "  $($ctl.TxtPoints.Text)"
        Write-Host "  $($ctl.TxtOldest.Text)"
        Write-Host "  $($ctl.TxtStorage.Text)"
        Write-Host "  $($ctl.LblFreq.Text)"
        Write-Host "  $($ctl.LblReten.Text)"
        Write-Host "  Haeufigkeit  : $(($ctl.CmbFreq.Items  | ForEach-Object { $_.Content }) -join ' | ')"
        Write-Host "  Aufbewahrung : $(($ctl.CmbReten.Items | ForEach-Object { $_.Content }) -join ' | ')"
        Write-Host "  Auswahl haelt: Freq=$([string]$ctl.CmbFreq.SelectedItem.Tag) Reten=$([string]$ctl.CmbReten.SelectedItem.Tag) Size=$([string]$ctl.CmbSize.SelectedItem.Tag)"
        Write-Host ""
    }
    Write-Host "Erkannte Systemsprache: $((Get-UICulture).Name)"
    Write-Host "Administrator         : $(Test-Admin)"
    Write-Host "Version               : $Version"
    return
}

if (-not (Test-Admin)) { Write-Log (T 'logNoAdmin') }
Write-Log (T 'logReady')
$window.ShowDialog() | Out-Null

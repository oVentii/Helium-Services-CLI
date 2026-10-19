$script:Theme = @{
    Line    = [ConsoleColor]::DarkGray
    Head    = [ConsoleColor]::White
    Body    = [ConsoleColor]::White
    Dim     = [ConsoleColor]::Gray
    OK      = [ConsoleColor]::Green
    Warn    = [ConsoleColor]::Yellow
    Bad     = [ConsoleColor]::Red
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("  ▌ " + $Title.ToUpper()) -ForegroundColor $script:Theme.Head
    Write-Host ("      " + "═" * 62) -ForegroundColor $script:Theme.Line
}

function Write-Field {
    param(
        [string]$Label,
        [string]$Value,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host ("    {0,-22}" -f $Label) -NoNewline -ForegroundColor $script:Theme.Dim
    Write-Host $Value -ForegroundColor $Color
}

function Write-State {
    param(
        [string]$Text,
        [ValidateSet('OK', 'WARN', 'BAD', 'INFO')]
        [string]$Level = 'INFO'
    )
    $glyph = switch ($Level) {
        'OK'   { '●' }
        'WARN' { '▲' }
        'BAD'  { '×' }
        'INFO' { '◆' }
    }
    $color = switch ($Level) {
        'OK'   { $script:Theme.OK }
        'WARN' { $script:Theme.Warn }
        'BAD'  { $script:Theme.Bad }
        'INFO' { $script:Theme.Dim }
    }
    Write-Host ("    $glyph ") -NoNewline -ForegroundColor $color
    Write-Host $Text -ForegroundColor $script:Theme.Body
}

$isAdmin = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor White
    Write-Host "  ║                                                  ║" -ForegroundColor White
    Write-Host "  ║        ADMINISTRATOR PRIVILEGES REQUIRED         ║" -ForegroundColor White
    Write-Host "  ║                                                  ║" -ForegroundColor White
    Write-Host "  ║      Please run Helium Services CLI as Admin     ║" -ForegroundColor White
    Write-Host "  ║                                                  ║" -ForegroundColor White
    Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor White
    Write-Host "  ×  exiting..." -ForegroundColor Red
    Write-Host ""
    exit
}


$banner = @(
    '██╗  ██╗███████╗██╗     ██╗██╗   ██╗███╗   ███╗'
    '██║  ██║██╔════╝██║     ██║██║   ██║████╗ ████║'
    '███████║█████╗  ██║     ██║██║   ██║██╔████╔██║'
    '██╔══██║██╔══╝  ██║     ██║██║   ██║██║╚██╔╝██║'
    '██║  ██║███████╗███████╗██║╚██████╔╝██║ ╚═╝ ██║'
    '╚═╝  ╚═╝╚══════╝╚══════╝╚═╝ ╚═══╝  ╚═╝     ╚═╝'
)
Write-Host ""
foreach ($row in $banner) {
    Write-Host ("  " + $row) -ForegroundColor White
}
Write-Host ""
Write-Host ("      S E R V I C E S   ·   C L I") -ForegroundColor White
Write-Host ("      " + "─" * 46) -ForegroundColor $script:Theme.Line
Write-Host "      made by oVenti " -ForegroundColor Gray
Write-Host ""

try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Host ("      {0}  ·  {1}  ·  {2}" -f $env:COMPUTERNAME, $env:USERNAME, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Gray
    Write-Host ("      {0}" -f $osInfo.Caption) -ForegroundColor DarkGray
} catch {
    Write-Host "      unable to retrieve host information" -ForegroundColor Yellow
}


try {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    Write-Section "System Boot Time"
    Write-Field "Last Boot" $bootTime.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Field "Uptime" ("{0} days, {1:D2}:{2:D2}:{3:D2}" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds)
} catch {
    Write-Section "System Boot Time"
    Write-State "unable to retrieve boot time information" -Level BAD
}


$drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
if ($drives) {
    Write-Section "Connected Drives"
    foreach ($drive in $drives) {
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 1)
        $totalGB = [math]::Round($drive.Size / 1GB, 1)
        Write-Host ("    ● ") -NoNewline -ForegroundColor White
        Write-Host ("{0,-6}" -f $drive.DeviceID) -NoNewline -ForegroundColor White
        Write-Host ("{0,-8}" -f $drive.FileSystem) -NoNewline -ForegroundColor Gray
        Write-Host ("{0,8} GB free / {1,8} GB" -f $freeGB, $totalGB) -ForegroundColor DarkGray
    }
}


Write-Section "Service Status"

$services = @(
    @{Name = "SysMain"; DisplayName = "SysMain"},
    @{Name = "PcaSvc"; DisplayName = "Program Compatibility Assistant Service"},
    @{Name = "DPS"; DisplayName = "Diagnostic Policy Service"},
    @{Name = "EventLog"; DisplayName = "Windows Event Log"},
    @{Name = "Schedule"; DisplayName = "Task Scheduler"},
    @{Name = "Bam"; DisplayName = "Background Activity Moderator"},
    @{Name = "Dusmsvc"; DisplayName = "Data Usage"},
    @{Name = "Appinfo"; DisplayName = "Application Information"},
    @{Name = "CDPSvc"; DisplayName = "Connected Devices Platform Service"},
    @{Name = "DcomLaunch"; DisplayName = "DCOM Server Process Launcher"},
    @{Name = "PlugPlay"; DisplayName = "Plug and Play"},
    @{Name = "wsearch"; DisplayName = "Windows Search"}
)

Write-Host ("    {0,-12} {1,-40} {2}" -f "SERVICE", "DISPLAY NAME", "STATUS / STARTED") -ForegroundColor DarkGray
    Write-Host ("    " + "─" * 62) -ForegroundColor $script:Theme.Line

foreach ($svc in $services) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    $displayName = if ($service) { $service.DisplayName } else { "Not Found" }
    if ($displayName.Length -gt 40) {
        $displayName = $displayName.Substring(0, 37) + "..."
    }

    if (-not $service) {
        Write-Host ("    {0,-12} {1,-40}" -f $svc.Name, $displayName) -NoNewline -ForegroundColor Gray
        Write-Host (" × {0}" -f "Stopped") -ForegroundColor Red
        continue
    }

    if ($service.Status -ne "Running") {
        Write-Host ("    {0,-12} {1,-40}" -f $svc.Name, $displayName) -NoNewline -ForegroundColor Gray
        Write-Host (" × {0}" -f $service.Status) -ForegroundColor Red
        continue
    }

    Write-Host ("    {0,-12} {1,-40}" -f $svc.Name, $displayName) -NoNewline -ForegroundColor White
    Write-Host " │ " -NoNewline -ForegroundColor DarkGray

    if ($svc.Name -eq "Bam") {
        Write-Host "Enabled" -ForegroundColor Yellow
        continue
    }

    $timeText = "N/A"
    try {
        $process = Get-CimInstance Win32_Service -Filter "Name='$($svc.Name)'" | Select-Object ProcessId
        if ($process.ProcessId -gt 0) {
            $proc = Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue
            if ($proc) {
                $timeText = $proc.StartTime.ToString("HH:mm:ss")
            }
        }
    } catch {}
    Write-Host $timeText -ForegroundColor Gray
}


Write-Section "Registry"

$settings = @(
    @{ Name = "CMD"; Path = "HKCU:\Software\Policies\Microsoft\Windows\System"; Key = "DisableCMD"; Warning = "Disabled"; Safe = "Available" },
    @{ Name = "PowerShell Logging"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"; Key = "EnableScriptBlockLogging"; Warning = "Disabled"; Safe = "Enabled" },
    @{ Name = "Activities Cache"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "EnableActivityFeed"; Warning = "Disabled"; Safe = "Enabled" },
    @{ Name = "Prefetch Enabled"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnablePrefetcher"; Warning = "Disabled"; Safe = "Enabled" }
)

foreach ($s in $settings) {
    $status = Get-ItemProperty -Path $s.Path -Name $s.Key -ErrorAction SilentlyContinue
    if ($status -and $status.$($s.Key) -eq 0) {
        Write-Host ("    × ") -NoNewline -ForegroundColor Red
        Write-Host ("{0,-22}" -f $s.Name) -NoNewline -ForegroundColor White
        Write-Host $s.Warning -ForegroundColor Red
    } else {
        Write-Host ("    ● ") -NoNewline -ForegroundColor Green
        Write-Host ("{0,-22}" -f $s.Name) -NoNewline -ForegroundColor White
        Write-Host $s.Safe -ForegroundColor White
    }
}


function Check-EventLog {
    param ($logName, $eventID, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$eventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($event) {
        Write-Host ("    ◆ ") -NoNewline -ForegroundColor Yellow
        Write-Host ("{0,-34}" -f $message) -NoNewline -ForegroundColor White
        Write-Host $event.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor Gray
    } else {
        Write-State "$message - No records found" -Level OK
    }
}

function Check-RecentEventLog {
    param ($logName, $eventIDs, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$($eventIDs -join ' or EventID=')]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($event) {
        Write-Host ("    ◆ ") -NoNewline -ForegroundColor Yellow
        Write-Host ("{0} (ID: {1}) " -f $message, $event.Id) -NoNewline -ForegroundColor White
        Write-Host $event.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor Gray
    } else {
        Write-State "$message - No records found" -Level OK
    }
}

function Check-DeviceDeleted {
    try {
        $event = Get-WinEvent -LogName "Microsoft-Windows-Kernel-PnP/Configuration" -FilterXPath "*[System[EventID=400]]" -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($event) {
            Write-Host ("    ◆ ") -NoNewline -ForegroundColor Yellow
            Write-Host ("{0,-34}" -f "Device configuration changed") -NoNewline -ForegroundColor White
            Write-Host $event.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor Gray
            return
        }
    } catch {}

    try {
        $event = Get-WinEvent -FilterHashtable @{LogName="System"; ID=225} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($event) {
            Write-Host ("    ◆ ") -NoNewline -ForegroundColor Yellow
            Write-Host ("{0,-34}" -f "Device removed") -NoNewline -ForegroundColor White
            Write-Host $event.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor Gray
            return
        }
    } catch {}

    try {
        $events = Get-WinEvent -LogName "System" | Where-Object {$_.Id -eq 225 -or $_.Id -eq 400} | Sort-Object TimeCreated -Descending | Select-Object -First 1
        if ($events) {
            Write-Host ("    ◆ ") -NoNewline -ForegroundColor Yellow
            Write-Host ("{0,-34}" -f "Last device change") -NoNewline -ForegroundColor White
            Write-Host $events.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor Gray
            return
        }
    } catch {}

    Write-State "Device changes - No records found" -Level OK
}

Write-Section "Event Logs"

Check-EventLog "Application" 3079 "USN Journal cleared"
Check-RecentEventLog "System" @(104, 1102) "Event Logs cleared"
Check-EventLog "System" 1074 "Last PC Shutdown"
Check-EventLog "Security" 4616 "System time changed"
Check-EventLog "System" 6005 "Event Log Service started"
Check-DeviceDeleted


$prefetchPath = "$env:SystemRoot\Prefetch"
if (Test-Path $prefetchPath) {
    Write-Section "Prefetch Integrity"

    $files = Get-ChildItem -Path $prefetchPath -Filter *.pf -Force -ErrorAction SilentlyContinue
    if (-not $files) {
        Write-State "No prefetch found?? Check the folder please" -Level WARN
    } else {
        $hashTable = @{}
        $suspiciousFiles = @{}
        $totalFiles = $files.Count

        $hiddenFiles = @()
        $readOnlyFiles = @()
        $hiddenAndReadOnlyFiles = @()
        $errorFiles = @()

        foreach ($file in $files) {
            try {
                $isHidden = $file.Attributes -band [System.IO.FileAttributes]::Hidden
                $isReadOnly = $file.Attributes -band [System.IO.FileAttributes]::ReadOnly

                if ($isHidden -and $isReadOnly) {
                    $hiddenAndReadOnlyFiles += $file
                    if (-not $suspiciousFiles.ContainsKey($file.Name)) {
                        $suspiciousFiles[$file.Name] = "Hidden and Read-only"
                    }
                } elseif ($isHidden) {
                    $hiddenFiles += $file
                    if (-not $suspiciousFiles.ContainsKey($file.Name)) {
                        $suspiciousFiles[$file.Name] = "Hidden file"
                    }
                } elseif ($isReadOnly) {
                    $readOnlyFiles += $file
                    if (-not $suspiciousFiles.ContainsKey($file.Name)) {
                        $suspiciousFiles[$file.Name] = "Read-only file"
                    }
                }

                $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
                if ($hash) {
                    if ($hashTable.ContainsKey($hash.Hash)) {
                        $hashTable[$hash.Hash].Add($file.Name)
                    } else {
                        $hashTable[$hash.Hash] = [System.Collections.Generic.List[string]]::new()
                        $hashTable[$hash.Hash].Add($file.Name)
                    }
                }
            } catch {
                $errorFiles += $file
                if (-not $suspiciousFiles.ContainsKey($file.Name)) {
                    $suspiciousFiles[$file.Name] = "Error analyzing file: $($_.Exception.Message)"
                }
            }
        }

        if ($hiddenAndReadOnlyFiles.Count -gt 0) {
            Write-Host ("    ▲ ") -NoNewline -ForegroundColor Yellow
            Write-Host "Hidden & Read-only Files:" -NoNewline -ForegroundColor White
            Write-Host " $($hiddenAndReadOnlyFiles.Count) found" -ForegroundColor Yellow
            foreach ($file in $hiddenAndReadOnlyFiles) {
                Write-Host ("      {0}" -f $file.Name) -ForegroundColor Gray
            }
        }

        if ($hiddenFiles.Count -gt 0) {
            Write-Host ("    ▲ ") -NoNewline -ForegroundColor Yellow
            Write-Host "Hidden Files:" -NoNewline -ForegroundColor White
            Write-Host " $($hiddenFiles.Count) found" -ForegroundColor Yellow
            foreach ($file in $hiddenFiles) {
                Write-Host ("      {0}" -f $file.Name) -ForegroundColor Gray
            }
        } else {
            Write-State "Hidden Files: None" -Level OK
        }

        if ($readOnlyFiles.Count -gt 0) {
            Write-Host ("    ▲ ") -NoNewline -ForegroundColor Yellow
            Write-Host "Read-Only Files:" -NoNewline -ForegroundColor White
            Write-Host " $($readOnlyFiles.Count)" -ForegroundColor Yellow
            foreach ($file in $readOnlyFiles) {
                Write-Host ("      {0}" -f $file.Name) -ForegroundColor Gray
            }
        } else {
            Write-State "Read-Only Files: None" -Level OK
        }

        $repeatedHashes = $hashTable.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        if ($repeatedHashes) {
            Write-Host ("    ▲ ") -NoNewline -ForegroundColor Yellow
            Write-Host "Duplicate Files:" -NoNewline -ForegroundColor White
            Write-Host " $($repeatedHashes.Count) sets found" -ForegroundColor Yellow
            foreach ($entry in $repeatedHashes) {
                foreach ($file in $entry.Value) {
                    if (-not $suspiciousFiles.ContainsKey($file)) {
                        $suspiciousFiles[$file] = "Duplicate file"
                    }
                }
                Write-Host ("      Duplicate set: {0}" -f ($entry.Value -join ", ")) -ForegroundColor Gray
            }
        } else {
            Write-State "Duplicates: None" -Level OK
        }

        Write-Host ""
        if ($suspiciousFiles.Count -gt 0) {
            Write-Host ("    × ") -NoNewline -ForegroundColor Red
            Write-Host "SUSPICIOUS FILES FOUND:" -NoNewline -ForegroundColor White
            Write-Host " $($suspiciousFiles.Count)/$totalFiles" -ForegroundColor Red
            foreach ($entry in $suspiciousFiles.GetEnumerator() | Sort-Object Key) {
                Write-Host ("      {0} : {1}" -f $entry.Key, $entry.Value) -ForegroundColor Gray
            }
        } else {
            Write-Host ("    ● ") -NoNewline -ForegroundColor Green
            Write-Host "Prefetch integrity: Clean" -NoNewline -ForegroundColor White
            Write-Host " ($totalFiles files checked)" -ForegroundColor Gray
        }
    }
} else {
    Write-Section "Prefetch Integrity"
    Write-State "Couldnt find prefetch folder?? (check yo paths hoe)" -Level BAD
}


try {
    $recycleBinPath = "$env:SystemDrive" + '\$Recycle.Bin'

    Write-Section "Recycle Bin"

    if (Test-Path $recycleBinPath) {
        $recycleBinFolder = Get-Item -LiteralPath $recycleBinPath -Force
        $userFolders = Get-ChildItem -LiteralPath $recycleBinPath -Directory -Force -ErrorAction SilentlyContinue

        if ($userFolders) {
            $allDeletedItems = @()
            $latestModTime = $recycleBinFolder.LastWriteTime

            foreach ($userFolder in $userFolders) {
                if ($userFolder.LastWriteTime -gt $latestModTime) {
                    $latestModTime = $userFolder.LastWriteTime
                }

                $userItems = Get-ChildItem -LiteralPath $userFolder.FullName -File -Force -ErrorAction SilentlyContinue
                if ($userItems) {
                    $allDeletedItems += $userItems

                    $latestFile = $userItems | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                    if ($latestFile -and $latestFile.LastWriteTime -gt $latestModTime) {
                        $latestModTime = $latestFile.LastWriteTime
                    }
                }
            }

            Write-Field "Last Modified" $latestModTime.ToString("yyyy-MM-dd HH:mm:ss") -Color Yellow

            if ($allDeletedItems.Count -gt 0) {
                Write-Field "Total Items" $allDeletedItems.Count -Color Yellow
                $latestItem = $allDeletedItems | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                Write-Field "Latest Item" $latestItem.Name -Color Gray
            } else {
                Write-Field "Status" "Folders present but empty" -Color Green
            }
        } else {
            Write-Field "Status" "Emptyy" -Color Green
            Write-Field "Last Modified" $recycleBinFolder.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") -Color Green
        }

        $clearEvent = Get-WinEvent -FilterHashtable @{LogName="System"; Id=10006} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($clearEvent) {
            Write-Field "Last Cleared (Event)" $clearEvent.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss") -Color Red
        }
    } else {
        Write-Field "Status" "Recycle Bin not found at: $recycleBinPath" -Color Yellow
        Write-Field "Note" "Recycle Bin may be empty or on different drive" -Color Gray
    }

    $consoleHistoryPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
    Write-Section "Console Host History"

    if (Test-Path $consoleHistoryPath) {
        $historyFile = Get-Item -Path $consoleHistoryPath -Force
        Write-Field "Last Modified" $historyFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") -Color Yellow

        $attributes = $historyFile.Attributes
        if ($attributes -ne "Archive") {
            Write-Field "Attributes" $attributes -Color Yellow
        } else {
            Write-Field "Attributes" "Normal" -Color Green
        }

        $fileSize = $historyFile.Length
        Write-Field "File Size" "$([math]::Round($fileSize/1024, 2)) KB" -Color Yellow
    } else {
        Write-Field "Status" "File not found: $consoleHistoryPath" -Color Yellow
        Write-Field "Note" "PowerShell history may be disabled or never used" -Color Gray
    }

} catch {
    Write-State "Error accessing system information: $($_.Exception.Message)" -Level BAD
}


Write-Host ""
Write-Host ("      " + "─" * 46) -ForegroundColor $script:Theme.Line
Write-Host "      CHECK COMPLETE" -ForegroundColor White
Write-Host "      dm oventi.dll on discord if you face any issues." -ForegroundColor Gray
Write-Host ""

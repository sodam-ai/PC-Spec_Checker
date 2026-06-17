@echo off
chcp 65001 >nul 2>&1
set "_SELF=%~f0"
powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "try{$c=[IO.File]::ReadAllText($env:_SELF,[Text.Encoding]::UTF8);$m='#'+'_PS'+'_#';$i=$c.IndexOf($m);if($i-lt0){throw 'Marker not found'};iex $c.Substring($i+6)}catch{Write-Host('Error: '+$_.Exception.Message)-ForegroundColor Red;Read-Host 'Press Enter'}"
if errorlevel 1 (
    echo.
    echo   [!] PowerShell failed to start. Check your system.
    pause
)
goto :eof
#_PS_#
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

# ================================================================
#  pc-spec_checker-kit
#  Single-file deep hardware + dev tool scanner
# ================================================================

# ===== Core Utility Functions =====

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor DarkCyan
    Write-Host "   $Text" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-SubTitle {
    param([string]$Text)
    Write-Host ""
    Write-Host "    [ $Text ]" -ForegroundColor DarkCyan
}

function Write-Bar {
    param([double]$Used, [double]$Total, [string]$Label)
    if ($Total -le 0) { return }
    $pct = [math]::Max(0, [math]::Min(100, [math]::Round(($Used / $Total) * 100)))
    $full = [math]::Floor($pct / 5)
    $empty = 20 - $full
    $bar = ('=' * $full) + (' ' * $empty)
    if ($pct -lt 60) { $clr = 'Green' }
    elseif ($pct -lt 85) { $clr = 'Yellow' }
    else { $clr = 'Red' }
    Write-Host "    $Label [$bar] $pct%" -ForegroundColor $clr
}

function Write-ToolCheck {
    param([string]$Name, [string]$Version)
    $pad = $Name.PadRight(22)
    if ($Version) {
        Write-Host "    [O] $pad : $Version" -ForegroundColor Green
    } else {
        Write-Host "    [X] $pad : not installed" -ForegroundColor DarkGray
    }
}

function Write-InfoLine {
    param([string]$Label, [string]$Value, [string]$Color = 'White')
    $pad = $Label.PadRight(16)
    Write-Host "    $pad : $Value" -ForegroundColor $Color
}

# ================================================================
#  UNIVERSAL DEEP DETECTION ENGINE
# ================================================================

$UP = $env:USERPROFILE
$LAD = $env:LOCALAPPDATA
$AD = $env:APPDATA
$PF = $env:ProgramFiles
$PF86 = ${env:ProgramFiles(x86)}
$PD = $env:ProgramData

function Get-ExeVersion {
    param([string]$ExePath, [string]$Arg)
    if (-not (Test-Path $ExePath)) { return $null }
    try {
        $result = & $ExePath $Arg 2>&1 | Out-String
        $line = $result.Trim().Split("`n")[0].Trim()
        # Filter out error outputs
        if ($line -match 'Traceback|Error:|Exception|fatal:|panic:') {
            try {
                $vi = (Get-Item $ExePath).VersionInfo
                if ($vi.ProductVersion) { return $vi.ProductVersion }
                if ($vi.FileVersion) { return $vi.FileVersion }
            } catch {}
            return '(found)'
        }
        if ($line.Length -gt 80) { $line = $line.Substring(0,80) + '...' }
        return $line
    } catch {
        try {
            $vi = (Get-Item $ExePath).VersionInfo
            if ($vi.ProductVersion) { return $vi.ProductVersion }
            if ($vi.FileVersion) { return $vi.FileVersion }
        } catch {}
        return '(found)'
    }
}

function Find-Tool {
    param(
        [string]$Cmd,
        [string]$VersionArg,
        [string[]]$KnownPaths,
        [switch]$IsGui
    )
    # 1) PATH
    $found = Get-Command $Cmd -ErrorAction SilentlyContinue
    if ($found) {
        if ($IsGui) {
            try {
                $vi = (Get-Item $found.Source).VersionInfo
                if ($vi.ProductVersion) { return $vi.ProductVersion }
                if ($vi.FileVersion) { return $vi.FileVersion }
            } catch {}
            return '(found in PATH)'
        }
        try {
            $ver = & $Cmd $VersionArg 2>&1 | Out-String
            $line = $ver.Trim().Split("`n")[0].Trim()
            if ($line -match 'Traceback|Error:|Exception|fatal:|panic:|unknown command') {
                try {
                    $vi = (Get-Item $found.Source).VersionInfo
                    if ($vi.ProductVersion) { return $vi.ProductVersion }
                    if ($vi.FileVersion) { return $vi.FileVersion }
                } catch {}
                return '(found in PATH)'
            }
            if ($line.Length -gt 80) { $line = $line.Substring(0,80) + '...' }
            if ($line) { return $line }
        } catch {}
        return '(found in PATH)'
    }
    # 2) Known paths
    foreach ($p in $KnownPaths) {
        if (-not $p) { continue }
        # Support wildcard paths
        $resolved = $null
        if ($p -match '\*') {
            $resolved = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -Last 1
            if ($resolved) { $p = $resolved.FullName }
            else { continue }
        }
        if (Test-Path $p) {
            if ($IsGui) {
                try {
                    $vi = (Get-Item $p).VersionInfo
                    if ($vi.ProductVersion) { return "$($vi.ProductVersion)" }
                    if ($vi.FileVersion) { return "$($vi.FileVersion)" }
                } catch {}
                return '(found)'
            }
            return Get-ExeVersion $p $VersionArg
        }
    }
    return $null
}

function Find-GuiApp {
    param([string]$Name, [string[]]$Paths, [string]$RegPattern)
    foreach ($p in $Paths) {
        if ($p -and (Test-Path $p)) {
            try {
                $vi = (Get-Item $p).VersionInfo
                if ($vi.ProductVersion) { return "$Name $($vi.ProductVersion)" }
                if ($vi.FileVersion) { return "$Name $($vi.FileVersion)" }
            } catch {}
            return "$Name (found)"
        }
    }
    if ($RegPattern) {
        $regPaths = @(
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
        foreach ($rp in $regPaths) {
            try {
                $f = Get-ItemProperty $rp -ErrorAction SilentlyContinue |
                     Where-Object { $_.DisplayName -like $RegPattern } |
                     Select-Object -First 1
                if ($f) { return "$($f.DisplayName) $($f.DisplayVersion)" }
            } catch {}
        }
    }
    return $null
}

# ===== Tool-specific finders =====

function Find-Python {
    foreach ($cmd in @('python', 'python3', 'py')) {
        $f = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($f) {
            try {
                $ver = & $cmd --version 2>&1 | Out-String
                $line = $ver.Trim().Split("`n")[0].Trim()
                if ($line -match 'Python') { return $line }
            } catch {}
        }
    }
    $pyPaths = @(
        "$LAD\Programs\Python\Python314\python.exe",
        "$LAD\Programs\Python\Python313\python.exe",
        "$LAD\Programs\Python\Python312\python.exe",
        "$LAD\Programs\Python\Python311\python.exe",
        "$LAD\Programs\Python\Python310\python.exe",
        "$PF\Python314\python.exe",
        "$PF\Python313\python.exe",
        "$PF\Python312\python.exe",
        "$PF\Python311\python.exe",
        "$PF\Python310\python.exe",
        "$LAD\Microsoft\WindowsApps\python3.exe",
        "$UP\miniconda3\python.exe",
        "$UP\anaconda3\python.exe"
    )
    foreach ($p in $pyPaths) {
        if (Test-Path $p) { return Get-ExeVersion $p '--version' }
    }
    return $null
}

function Find-Pip {
    foreach ($cmd in @('pip', 'pip3')) {
        $f = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($f) {
            try {
                $v = & $cmd --version 2>&1 | Out-String
                $line = $v.Trim().Split("`n")[0].Trim()
                if ($line -match 'pip') { return $line }
            } catch {}
        }
    }
    foreach ($py in @('python', 'python3', 'py')) {
        $f = Get-Command $py -ErrorAction SilentlyContinue
        if ($f) {
            try {
                $v = & $py -m pip --version 2>&1 | Out-String
                $line = $v.Trim().Split("`n")[0].Trim()
                if ($line -match 'pip') { return $line }
            } catch {}
        }
    }
    $pipPaths = @(
        "$LAD\Programs\Python\Python314\Scripts\pip.exe",
        "$LAD\Programs\Python\Python313\Scripts\pip.exe",
        "$LAD\Programs\Python\Python312\Scripts\pip.exe",
        "$LAD\Programs\Python\Python311\Scripts\pip.exe",
        "$PF\Python313\Scripts\pip.exe",
        "$PF\Python312\Scripts\pip.exe"
    )
    foreach ($p in $pipPaths) {
        if (Test-Path $p) { return Get-ExeVersion $p '--version' }
    }
    return $null
}

# ================================================================
#  DISPLAY FUNCTIONS
# ================================================================

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ====================================================" -ForegroundColor Cyan
    Write-Host "        pc-spec_checker-kit" -ForegroundColor Yellow
    Write-Host "        Deep Hardware + Dev Tool Scanner" -ForegroundColor DarkGray
    Write-Host "        내 PC 사양 + 개발 도구 검사기 (English / 한국어)" -ForegroundColor DarkGray
    Write-Host "  ====================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host "  Select what to check  /  무엇을 확인할까요?" -ForegroundColor White
    Write-Host ""
    Write-Host "  [ 1] Show ALL (Full Scan)  /  전체 스캔" -ForegroundColor Green
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ 2] Basic Info + Motherboard + BIOS  /  기본 정보 + 메인보드 + BIOS" -ForegroundColor White
    Write-Host "  [ 3] CPU (Detailed)  /  CPU (상세)" -ForegroundColor White
    Write-Host "  [ 4] RAM (Each Stick)  /  RAM 램 (한 개씩)" -ForegroundColor White
    Write-Host "  [ 5] Disk (Type + Health)  /  디스크 (종류 + 건강)" -ForegroundColor White
    Write-Host "  [ 6] GPU (Detailed)  /  GPU 그래픽 (상세)" -ForegroundColor White
    Write-Host "  [ 7] Network + Display  /  네트워크 + 디스플레이" -ForegroundColor White
    Write-Host "  [ 8] Battery / Power  /  배터리 / 전원" -ForegroundColor White
    Write-Host "  [ 9] Security Status  /  보안 상태" -ForegroundColor White
    Write-Host "  [10] Startup Programs  /  시작 프로그램" -ForegroundColor White
    Write-Host "  [11] Audio / USB / Bluetooth  /  오디오 / USB / 블루투스" -ForegroundColor White
    Write-Host "  [12] Installed Apps  /  설치된 앱" -ForegroundColor White
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [13] Dev Tools (Full Deep Scan)  /  개발 도구 (정밀 스캔)" -ForegroundColor Yellow
    Write-Host "  [14] WSL (Linux)  /  WSL (윈도우 속 리눅스)" -ForegroundColor White
    Write-Host "  [15] Score + Recommendations  /  점수 + 추천" -ForegroundColor White
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ 0] Exit  /  종료" -ForegroundColor DarkGray
    Write-Host ""
}

# ================================================================
#  HARDWARE INFO FUNCTIONS
# ================================================================

function Get-BasicInfo {
    Write-Title "Basic Info + Motherboard + BIOS  /  기본 정보 + 메인보드 + BIOS"
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        Write-InfoLine "PC Name" $cs.Name
        Write-InfoLine "User" $cs.UserName
        Write-InfoLine "OS" $os.Caption
        Write-InfoLine "Version" $os.Version
        Write-InfoLine "Arch" $os.OSArchitecture
        Write-InfoLine "Build" $os.BuildNumber
        Write-InfoLine "OS Install" $os.InstallDate.ToString('yyyy-MM-dd')
        Write-InfoLine "System Dir" $os.SystemDirectory
        $up = (Get-Date) - $os.LastBootUpTime
        Write-InfoLine "Uptime" "$($up.Days)d $($up.Hours)h $($up.Minutes)m"
        Write-InfoLine "PC Type" $cs.SystemType
        $totalRAM = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        Write-InfoLine "Total RAM" "${totalRAM} GB"
        # Windows license
        try {
            $lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationId='55c92734-d682-4d71-983e-d6ec3f16059f' AND LicenseStatus=1" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($lic) {
                Write-InfoLine "License" "$($lic.Name)" 'Green'
            } else {
                Write-InfoLine "License" "Not Activated" 'Yellow'
            }
        } catch {}
        # Last Windows Update
        try {
            $lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($lastUpdate -and $lastUpdate.InstalledOn) {
                Write-InfoLine "Last Update" "$($lastUpdate.InstalledOn.ToString('yyyy-MM-dd')) ($($lastUpdate.HotFixID))"
            }
        } catch {}
    } catch {
        Write-Host "    Could not retrieve basic info." -ForegroundColor Red
    }

    Write-Host ""
    Write-SubTitle "Motherboard"
    try {
        $mb = Get-CimInstance Win32_BaseBoard
        Write-InfoLine "Maker" $mb.Manufacturer
        Write-InfoLine "Model" $mb.Product
        if ($mb.SerialNumber -and $mb.SerialNumber -ne 'Default string') {
            Write-InfoLine "Serial" $mb.SerialNumber
        }
    } catch {
        Write-Host "    Could not retrieve motherboard info." -ForegroundColor Red
    }

    Write-Host ""
    Write-SubTitle "BIOS"
    try {
        $bios = Get-CimInstance Win32_BIOS
        Write-InfoLine "Maker" $bios.Manufacturer
        Write-InfoLine "Version" $bios.SMBIOSBIOSVersion
        Write-InfoLine "Date" $bios.ReleaseDate.ToString('yyyy-MM-dd')
    } catch {
        Write-Host "    Could not retrieve BIOS info." -ForegroundColor Red
    }
    Write-Host ""
}

function Get-CPUInfo {
    Write-Title "CPU (Detailed)  /  CPU (상세)"
    try {
        $cpu = Get-CimInstance Win32_Processor
        Write-InfoLine "Name" $cpu.Name.Trim()
        Write-InfoLine "Manufacturer" $cpu.Manufacturer
        Write-InfoLine "Cores" "$($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads"
        $ghz = [math]::Round($cpu.MaxClockSpeed / 1000, 2)
        $curGhz = [math]::Round($cpu.CurrentClockSpeed / 1000, 2)
        Write-InfoLine "Max Speed" "${ghz} GHz"
        Write-InfoLine "Current Speed" "${curGhz} GHz"
        Write-InfoLine "Socket" $cpu.SocketDesignation
        if ($cpu.L2CacheSize) {
            $l2 = if ($cpu.L2CacheSize -ge 1024) { "$([math]::Round($cpu.L2CacheSize/1024,1)) MB" } else { "$($cpu.L2CacheSize) KB" }
            Write-InfoLine "L2 Cache" $l2
        }
        if ($cpu.L3CacheSize) {
            $l3 = if ($cpu.L3CacheSize -ge 1024) { "$([math]::Round($cpu.L3CacheSize/1024,1)) MB" } else { "$($cpu.L3CacheSize) KB" }
            Write-InfoLine "L3 Cache" $l3
        }
        $archName = switch ($cpu.Architecture) { 9 {'x64'} 12 {'ARM64'} 5 {'ARM'} 0 {'x86'} default {"$($cpu.Architecture)"} }
        Write-InfoLine "Architecture" $archName
        Write-InfoLine "Virtualization" $(if($cpu.VirtualizationFirmwareEnabled){'Enabled'}else{'Disabled / Unknown'})

        # CPU Temperature
        try {
            $temp = Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace root/wmi -ErrorAction Stop | Select-Object -First 1
            if ($temp.CurrentTemperature) {
                $celsius = [math]::Round(($temp.CurrentTemperature - 2732) / 10, 1)
                if ($celsius -gt 0 -and $celsius -lt 120) {
                    $tClr = if ($celsius -lt 60) {'Green'} elseif ($celsius -lt 80) {'Yellow'} else {'Red'}
                    Write-InfoLine "Temperature" "${celsius} C" $tClr
                }
            }
        } catch {
            Write-InfoLine "Temperature" "N/A (admin required)" 'DarkGray'
        }

        $load = $cpu.LoadPercentage
        if ($null -ne $load) {
            Write-Bar $load 100 "CPU Usage    "
        }
    } catch {
        Write-Host "    Could not retrieve CPU info." -ForegroundColor Red
    }
    Write-Host ""
}

function Get-RAMInfo {
    Write-Title "RAM (Memory - Each Stick)  /  RAM 메모리 (한 개씩)"
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $usedGB = [math]::Round($totalGB - $freeGB, 1)
        Write-Host "    Total : ${totalGB} GB  |  Used : ${usedGB} GB  |  Free : ${freeGB} GB"
        Write-Bar $usedGB $totalGB "RAM        "
    } catch {
        Write-Host "    Could not retrieve RAM summary." -ForegroundColor Red
    }
    Write-Host ""
    Write-SubTitle "Installed Sticks"
    try {
        $sticks = Get-CimInstance Win32_PhysicalMemory
        $slotNum = 1
        foreach ($s in $sticks) {
            $capGB = [math]::Round($s.Capacity / 1GB, 1)
            $speed = $s.ConfiguredClockSpeed
            if (-not $speed) { $speed = $s.Speed }
            $typeMap = @{0='Unknown';20='DDR';21='DDR2';22='DDR3';24='DDR3';26='DDR4';34='DDR5'}
            $memType = if ($typeMap.ContainsKey([int]$s.SMBIOSMemoryType)) { $typeMap[[int]$s.SMBIOSMemoryType] }
                       elseif ($s.MemoryType -eq 26) { 'DDR4' }
                       elseif ($s.MemoryType -eq 34) { 'DDR5' }
                       else { 'DDR' }
            $ffMap = @{8='DIMM';12='SODIMM'}
            $ff = if ($ffMap.ContainsKey([int]$s.FormFactor)) { $ffMap[[int]$s.FormFactor] } else { '' }
            Write-Host "    Stick $slotNum"
            Write-Host "      Slot     : $($s.DeviceLocator)"
            Write-Host "      Size     : ${capGB} GB"
            Write-Host "      Type     : $memType $ff"
            Write-Host "      Speed    : ${speed} MHz"
            if ($s.Manufacturer -and $s.Manufacturer -ne 'Unknown') {
                Write-Host "      Maker    : $($s.Manufacturer)"
            }
            if ($s.PartNumber) {
                $pn = $s.PartNumber.Trim()
                if ($pn -and $pn -ne 'Unknown') { Write-Host "      Part No  : $pn" }
            }
            Write-Host ""
            $slotNum++
        }
        try {
            $arr = Get-CimInstance Win32_PhysicalMemoryArray
            $maxSlots = $arr.MemoryDevices
            $usedSlots = $slotNum - 1
            Write-Host "    Slots Used : $usedSlots / $maxSlots"
            $maxCapGB = [math]::Round($arr.MaxCapacity / 1MB, 0)
            if ($maxCapGB -gt 0) { Write-Host "    Max Support: ${maxCapGB} GB" }
        } catch {}
    } catch {
        Write-Host "    Could not retrieve stick info." -ForegroundColor Red
    }
    Write-Host ""
}

function Get-DiskInfo {
    Write-Title "Disk (Type + Health)  /  디스크 (종류 + 건강)"
    Write-SubTitle "Physical Drives"
    try {
        $physDisks = Get-CimInstance Win32_DiskDrive | Sort-Object Index
        foreach ($pd in $physDisks) {
            $sizeGB = [math]::Round($pd.Size / 1GB, 1)
            $diskType = 'Unknown'
            $health = 'N/A'; $hClr = 'DarkGray'
            $diskTemp = $null
            try {
                $msftDisk = Get-CimInstance -Namespace root/microsoft/windows/storage -ClassName MSFT_PhysicalDisk |
                            Where-Object { $_.DeviceId -eq $pd.Index }
                if ($msftDisk) {
                    switch ($msftDisk.MediaType) {
                        3 { $diskType = 'HDD' }
                        4 { $diskType = 'SSD' }
                        5 { $diskType = 'SCM' }
                    }
                    switch ($msftDisk.BusType) {
                        17 { $diskType += ' (NVMe)' }
                        11 { $diskType += ' (SATA)' }
                        7  { $diskType += ' (USB)' }
                    }
                    switch ($msftDisk.HealthStatus) {
                        0 { $health = 'Healthy'; $hClr = 'Green' }
                        1 { $health = 'Warning'; $hClr = 'Yellow' }
                        2 { $health = 'Unhealthy'; $hClr = 'Red' }
                    }
                }
            } catch {}
            # Disk temperature via Storage reliability
            try {
                $rel = Get-CimInstance -Namespace root/microsoft/windows/storage -ClassName MSFT_PhysicalDisk |
                       Where-Object { $_.DeviceId -eq $pd.Index }
                if ($rel) {
                    $relCounter = $rel | Invoke-CimMethod -MethodName GetReliabilityCounters -ErrorAction SilentlyContinue
                    if ($relCounter -and $relCounter.Temperature) {
                        $diskTemp = $relCounter.Temperature
                    }
                }
            } catch {}

            Write-Host "    Disk $($pd.Index) : $($pd.Model)"
            Write-Host "      Size     : ${sizeGB} GB"
            Write-Host "      Type     : $diskType"
            Write-Host "      Health   : " -NoNewline; Write-Host "$health" -ForegroundColor $hClr
            Write-Host "      Interface: $($pd.InterfaceType)"
            if ($diskTemp) {
                $dtClr = if ($diskTemp -lt 45) {'Green'} elseif ($diskTemp -lt 55) {'Yellow'} else {'Red'}
                Write-Host "      Temp     : ${diskTemp} C" -ForegroundColor $dtClr
            }
            if ($pd.SerialNumber) {
                Write-Host "      Serial   : $($pd.SerialNumber.Trim())"
            }
            Write-Host ""
        }
    } catch {
        Write-Host "    Could not retrieve physical disk info." -ForegroundColor Red
    }
    Write-SubTitle "Partitions"
    try {
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($d in $disks) {
            $totalGB = [math]::Round($d.Size / 1GB, 1)
            $freeGB = [math]::Round($d.FreeSpace / 1GB, 1)
            $usedGB = [math]::Round($totalGB - $freeGB, 1)
            Write-Host "    [$($d.DeviceID)] Total: ${totalGB}GB | Used: ${usedGB}GB | Free: ${freeGB}GB | $($d.FileSystem)"
            Write-Bar $usedGB $totalGB "  $($d.DeviceID)        "
            Write-Host ""
        }
    } catch {
        Write-Host "    Could not retrieve partition info." -ForegroundColor Red
    }
}

function Get-GPUInfo {
    Write-Title "GPU (Detailed)  /  GPU 그래픽 (상세)"
    try {
        $gpus = Get-CimInstance Win32_VideoController
        $num = 1
        foreach ($g in $gpus) {
            if ($gpus.Count -gt 1) { Write-Host "    GPU $num" -ForegroundColor White }
            Write-InfoLine "Name" $g.Name
            Write-InfoLine "Status" $g.Status
            if ($g.AdapterRAM -and $g.AdapterRAM -gt 0) {
                $vramGB = [math]::Round($g.AdapterRAM / 1GB, 1)
                if ($vramGB -ge 1) { Write-InfoLine "VRAM" "${vramGB} GB" }
                else { $vramMB = [math]::Round($g.AdapterRAM / 1MB); Write-InfoLine "VRAM" "${vramMB} MB" }
            }
            # Try to get real VRAM for dedicated GPUs (Win32_VideoController caps at 4GB)
            try {
                $dxDiag = Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory -ErrorAction SilentlyContinue |
                          Select-Object -First 1
                if ($dxDiag -and $dxDiag.DedicatedUsage) {
                    # This shows usage, not total - note it
                }
            } catch {}
            if ($g.CurrentHorizontalResolution) {
                Write-InfoLine "Resolution" "$($g.CurrentHorizontalResolution) x $($g.CurrentVerticalResolution)"
            }
            if ($g.CurrentRefreshRate) { Write-InfoLine "Refresh Rate" "$($g.CurrentRefreshRate) Hz" }
            if ($g.CurrentBitsPerPixel) { Write-InfoLine "Color Depth" "$($g.CurrentBitsPerPixel) bit" }
            Write-InfoLine "Driver Ver" $g.DriverVersion
            if ($g.DriverDate) { Write-InfoLine "Driver Date" $g.DriverDate.ToString('yyyy-MM-dd') }
            if ($g.VideoProcessor) { Write-InfoLine "Adapter" $g.VideoProcessor }

            # GPU Temperature (via WMI if available)
            try {
                $gpuTemp = Get-CimInstance -Namespace root/OpenHardwareMonitor -ClassName Sensor -ErrorAction Stop |
                           Where-Object { $_.SensorType -eq 'Temperature' -and $_.Name -match 'GPU' } |
                           Select-Object -First 1
                if ($gpuTemp) {
                    $gtClr = if ($gpuTemp.Value -lt 60) {'Green'} elseif ($gpuTemp.Value -lt 80) {'Yellow'} else {'Red'}
                    Write-InfoLine "Temperature" "$([math]::Round($gpuTemp.Value))C" $gtClr
                }
            } catch {}
            Write-Host ""
            $num++
        }
    } catch {
        Write-Host "    Could not retrieve GPU info." -ForegroundColor Red
    }
}

function Get-NetworkInfo {
    Write-Title "Network (Internet)  /  네트워크 (인터넷)"
    try {
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
        foreach ($a in $adapters) {
            Write-Host "    Adapter  : $($a.Description)"
            if ($a.IPAddress) {
                Write-Host "    IPv4     : $($a.IPAddress[0])"
                if ($a.IPAddress.Count -gt 1) { Write-Host "    IPv6     : $($a.IPAddress[1])" }
            }
            Write-Host "    MAC      : $($a.MACAddress)"
            if ($a.DefaultIPGateway) { Write-Host "    Gateway  : $($a.DefaultIPGateway[0])" }
            if ($a.DNSServerSearchOrder) { Write-Host "    DNS      : $($a.DNSServerSearchOrder -join ', ')" }
            if ($a.DHCPEnabled) { Write-Host "    DHCP     : Enabled" }
            Write-Host ""
        }
    } catch {
        Write-Host "    Could not retrieve network info." -ForegroundColor Red
    }
    Write-Host "    Testing internet..." -ForegroundColor DarkGray
    try {
        $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction Stop
        $ms = $ping.ResponseTime
        if ($null -eq $ms) { $ms = 0 }
        if ($ms -lt 50) { $clr = 'Green'; $eval = 'Very Fast!' }
        elseif ($ms -lt 100) { $clr = 'Yellow'; $eval = 'Normal' }
        else { $clr = 'Red'; $eval = 'Slow' }
        Write-Host "    Internet : Connected (${ms}ms) - $eval" -ForegroundColor $clr
    } catch {
        Write-Host "    Internet : Not Connected" -ForegroundColor Red
    }
    Write-Host ""
    Write-SubTitle "Display (Monitors)"
    try {
        $monitors = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction Stop
        $num = 1
        foreach ($m in $monitors) {
            $mfr = ($m.ManufacturerName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''
            $mdl = ($m.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''
            $ser = ($m.SerialNumberID | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''
            Write-Host "    Monitor $num"
            if ($mdl) { Write-Host "      Name   : $mdl" }
            if ($mfr) { Write-Host "      Maker  : $mfr" }
            if ($ser) { Write-Host "      Serial : $ser" }
            Write-Host ""
            $num++
        }
    } catch {
        Write-Host "    Could not retrieve monitor info (may need admin)." -ForegroundColor DarkGray
        Write-Host ""
    }
}

# ================================================================
#  NEW SECTIONS
# ================================================================

function Get-BatteryInfo {
    Write-Title "Battery / Power  /  배터리 / 전원"
    try {
        $batteries = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if (-not $batteries) {
            Write-Host "    No battery detected (Desktop PC)" -ForegroundColor DarkGray
            Write-Host ""
            # Show power plan instead
            try {
                $plan = Get-CimInstance -Namespace root/cimv2/power -ClassName Win32_PowerPlan -ErrorAction SilentlyContinue |
                        Where-Object { $_.IsActive } | Select-Object -First 1
                if ($plan) {
                    Write-InfoLine "Power Plan" $plan.ElementName
                }
            } catch {}
            Write-Host ""
            return
        }
        foreach ($b in $batteries) {
            Write-InfoLine "Name" $b.Name
            Write-InfoLine "Status" $b.Status
            if ($b.EstimatedChargeRemaining) {
                $bClr = if ($b.EstimatedChargeRemaining -gt 50) {'Green'} elseif ($b.EstimatedChargeRemaining -gt 20) {'Yellow'} else {'Red'}
                Write-InfoLine "Charge" "$($b.EstimatedChargeRemaining)%" $bClr
                Write-Bar $b.EstimatedChargeRemaining 100 "Battery    "
            }
            if ($b.EstimatedRunTime -and $b.EstimatedRunTime -lt 71582788) {
                $hrs = [math]::Floor($b.EstimatedRunTime / 60)
                $mins = $b.EstimatedRunTime % 60
                Write-InfoLine "Remaining" "${hrs}h ${mins}m"
            }
            $statusMap = @{1='Discharging';2='AC Power';3='Fully Charged';4='Low';5='Critical'}
            if ($statusMap.ContainsKey([int]$b.BatteryStatus)) {
                Write-InfoLine "Power State" $statusMap[[int]$b.BatteryStatus]
            }
        }
        # Detailed battery report via WMI
        try {
            $fullCharge = Get-CimInstance -Namespace root/wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop | Select-Object -First 1
            $design = Get-CimInstance -Namespace root/wmi -ClassName BatteryStaticData -ErrorAction Stop | Select-Object -First 1
            if ($fullCharge -and $design -and $design.DesignedCapacity -gt 0) {
                $healthPct = [math]::Round(($fullCharge.FullChargedCapacity / $design.DesignedCapacity) * 100, 1)
                Write-InfoLine "Design Cap" "$($design.DesignedCapacity) mWh"
                Write-InfoLine "Current Cap" "$($fullCharge.FullChargedCapacity) mWh"
                $bhClr = if ($healthPct -gt 80) {'Green'} elseif ($healthPct -gt 50) {'Yellow'} else {'Red'}
                Write-InfoLine "Health" "${healthPct}%" $bhClr
                if ($design.CycleCount -and $design.CycleCount -gt 0) {
                    Write-InfoLine "Cycles" $design.CycleCount
                }
            }
        } catch {}
    } catch {
        Write-Host "    Could not retrieve battery info." -ForegroundColor Red
    }
    Write-Host ""
}

function Get-SecurityInfo {
    Write-Title "Security Status  /  보안 상태"
    # Windows Defender / Antivirus
    try {
        $av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop
        foreach ($a in $av) {
            $state = '{0:X6}' -f $a.productState
            $enabled = $state.Substring(2,2) -in @('10','11')
            $upToDate = $state.Substring(4,2) -eq '00'
            $eClr = if ($enabled) {'Green'} else {'Red'}
            $uClr = if ($upToDate) {'Green'} else {'Yellow'}
            Write-InfoLine "Antivirus" $a.displayName
            Write-InfoLine "Active" $(if($enabled){'Yes'}else{'No'}) $eClr
            Write-InfoLine "Up to Date" $(if($upToDate){'Yes'}else{'No'}) $uClr
        }
    } catch {
        Write-Host "    Could not query antivirus status." -ForegroundColor DarkGray
    }
    Write-Host ""
    # Firewall
    Write-SubTitle "Firewall"
    try {
        $fw = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($profile in $fw) {
            $fClr = if ($profile.Enabled) {'Green'} else {'Red'}
            Write-InfoLine "$($profile.Name)" $(if($profile.Enabled){'ON'}else{'OFF'}) $fClr
        }
    } catch {
        Write-Host "    Could not query firewall status." -ForegroundColor DarkGray
    }
    Write-Host ""
    # UAC
    Write-SubTitle "UAC (User Account Control)"
    try {
        $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction Stop
        $uacEnabled = $uac.EnableLUA -eq 1
        $uClr = if ($uacEnabled) {'Green'} else {'Red'}
        Write-InfoLine "UAC" $(if($uacEnabled){'Enabled'}else{'Disabled'}) $uClr
    } catch {}
    # BitLocker
    try {
        $bl = Get-CimInstance -Namespace root/cimv2/Security/MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume -ErrorAction SilentlyContinue |
              Where-Object { $_.DriveLetter -eq 'C:' } | Select-Object -First 1
        if ($bl) {
            $blStatus = switch ($bl.ProtectionStatus) { 0 {'OFF'} 1 {'ON'} 2 {'Unknown'} default {'Unknown'} }
            $blClr = if ($bl.ProtectionStatus -eq 1) {'Green'} else {'Yellow'}
            Write-InfoLine "BitLocker C:" $blStatus $blClr
        }
    } catch {}
    Write-Host ""
}

function Get-StartupInfo {
    Write-Title "Startup Programs  /  시작 프로그램"
    $count = 0
    try {
        # Registry: Current User
        Write-SubTitle "Current User (Registry)"
        $ruPaths = @(
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
        )
        foreach ($rp in $ruPaths) {
            try {
                $items = Get-ItemProperty $rp -ErrorAction SilentlyContinue
                if ($items) {
                    $items.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                        $val = $_.Value
                        if ($val.Length -gt 70) { $val = $val.Substring(0,70) + '...' }
                        Write-Host "    $($_.Name)" -ForegroundColor White -NoNewline
                        Write-Host " : $val" -ForegroundColor DarkGray
                        $count++
                    }
                }
            } catch {}
        }
        # Registry: All Users
        Write-SubTitle "All Users (Registry)"
        $rlPaths = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
        )
        foreach ($rp in $rlPaths) {
            try {
                $items = Get-ItemProperty $rp -ErrorAction SilentlyContinue
                if ($items) {
                    $items.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                        $val = $_.Value
                        if ($val.Length -gt 70) { $val = $val.Substring(0,70) + '...' }
                        Write-Host "    $($_.Name)" -ForegroundColor White -NoNewline
                        Write-Host " : $val" -ForegroundColor DarkGray
                        $count++
                    }
                }
            } catch {}
        }
        # Startup folder
        Write-SubTitle "Startup Folder"
        $startupPath = [System.IO.Path]::Combine($AD, 'Microsoft\Windows\Start Menu\Programs\Startup')
        if (Test-Path $startupPath) {
            $files = Get-ChildItem $startupPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }
            if ($files) {
                foreach ($f in $files) {
                    Write-Host "    $($f.Name)" -ForegroundColor White
                    $count++
                }
            } else {
                Write-Host "    (empty)" -ForegroundColor DarkGray
            }
        }
        # Task Scheduler startup tasks
        Write-SubTitle "Scheduled at Logon"
        try {
            $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
                     Where-Object { $_.Triggers -and ($_.Triggers | Where-Object { $_ -is [CimInstance] -and $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }) -and $_.State -ne 'Disabled' } |
                     Select-Object -First 15
            if ($tasks) {
                foreach ($t in $tasks) {
                    Write-Host "    $($t.TaskName)" -ForegroundColor White -NoNewline
                    Write-Host " ($($t.TaskPath))" -ForegroundColor DarkGray
                    $count++
                }
            } else {
                Write-Host "    (none found)" -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "    Could not query scheduled tasks." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "    Could not retrieve startup info." -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "    Total startup items: $count" -ForegroundColor $(if($count -lt 10){'Green'}elseif($count -lt 20){'Yellow'}else{'Red'})
    Write-Host ""
}

function Get-AudioUsbInfo {
    Write-Title "Audio / USB / Bluetooth  /  오디오 / USB / 블루투스"

    Write-SubTitle "Audio Devices"
    try {
        $audio = Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue
        if ($audio) {
            foreach ($a in $audio) {
                Write-InfoLine "Device" $a.Name
                Write-InfoLine "Status" $a.Status $(if($a.Status -eq 'OK'){'Green'}else{'Yellow'})
                if ($a.Manufacturer -and $a.Manufacturer -ne '(Generic audio driver)') {
                    Write-InfoLine "Maker" $a.Manufacturer
                }
                Write-Host ""
            }
        } else {
            Write-Host "    No audio devices found." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "    Could not retrieve audio info." -ForegroundColor Red
    }

    Write-SubTitle "USB Controllers"
    try {
        $usb = Get-CimInstance Win32_USBController -ErrorAction SilentlyContinue
        if ($usb) {
            foreach ($u in $usb) {
                Write-Host "    $($u.Name)" -ForegroundColor White
            }
        }
    } catch {}

    Write-Host ""
    Write-SubTitle "Connected USB Devices"
    try {
        $usbDevices = Get-CimInstance Win32_USBHub -ErrorAction SilentlyContinue
        if ($usbDevices) {
            $shown = 0
            foreach ($ud in $usbDevices) {
                if ($ud.Name -and $shown -lt 20) {
                    Write-Host "    $($ud.Name)" -ForegroundColor White
                    $shown++
                }
            }
            if ($usbDevices.Count -gt 20) {
                Write-Host "    ... and $($usbDevices.Count - 20) more" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "    No USB devices found." -ForegroundColor DarkGray
        }
    } catch {}

    Write-Host ""
    Write-SubTitle "Bluetooth"
    try {
        $bt = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -match 'Bluetooth' -and $_.Status -eq 'OK' }
        if ($bt) {
            foreach ($b in ($bt | Select-Object -First 10)) {
                Write-Host "    $($b.Name)" -ForegroundColor White
            }
        } else {
            Write-Host "    No Bluetooth devices found (or Bluetooth off)." -ForegroundColor DarkGray
        }
    } catch {}
    Write-Host ""
}

function Get-InstalledApps {
    Write-Title "Installed Apps (Major)  /  설치된 앱 (주요)"
    Write-Host "    Scanning registry..." -ForegroundColor DarkGray
    Write-Host ""
    $regPaths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $allApps = @()
    foreach ($rp in $regPaths) {
        try {
            $apps = Get-ItemProperty $rp -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -and $_.DisplayName.Length -gt 1 } |
                    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
            if ($apps) { $allApps += $apps }
        } catch {}
    }
    $allApps = $allApps | Sort-Object DisplayName -Unique

    # Categorize
    $categories = [ordered]@{
        'Browsers'     = 'Chrome|Firefox|Edge|Brave|Opera|Vivaldi|Arc|Safari|Waterfox|Tor Browser'
        'Office'       = 'Microsoft Office|Microsoft 365|LibreOffice|OpenOffice|WPS Office|Hancom|Google Docs'
        'Communication'= 'Slack|Discord|Telegram|Zoom|Microsoft Teams|KakaoTalk|LINE|Skype|WhatsApp|Signal|Notion'
        'Media'        = 'VLC|Spotify|iTunes|foobar|MPC-HC|PotPlayer|KMPlayer|OBS Studio|Audacity|HandBrake|DaVinci'
        'Graphics'     = 'Adobe|Figma|GIMP|Inkscape|Blender|Paint\.NET|Canva|Sketch|Affinity|Photoshop|Illustrator|Premiere'
        'Cloud/Backup' = 'Dropbox|Google Drive|OneDrive|iCloud|Synology|Backblaze|pCloud|MEGA'
        'Security'     = 'Norton|McAfee|Kaspersky|Avast|AVG|Bitdefender|Malwarebytes|ESET|Sophos'
        'Utilities'    = '7-Zip|WinRAR|PowerToys|Everything|AutoHotkey|CCleaner|TreeSize|Greenshot|ShareX|Rainmeter|f\.lux|Wox|Flow Launcher'
    }

    foreach ($cat in $categories.Keys) {
        $pattern = $categories[$cat]
        $matched = $allApps | Where-Object { $_.DisplayName -match $pattern }
        if ($matched) {
            Write-SubTitle $cat
            foreach ($m in ($matched | Select-Object -First 15)) {
                $ver = if ($m.DisplayVersion) { " v$($m.DisplayVersion)" } else { '' }
                Write-Host "    $($m.DisplayName)$ver" -ForegroundColor White
            }
        }
    }

    Write-Host ""
    Write-Host "    Total installed programs: $($allApps.Count)" -ForegroundColor Cyan
    Write-Host ""
}

# ================================================================
#  DEV TOOLS - MASSIVE DEEP SCAN (120+ tools)
# ================================================================

function Get-DevToolsInfo {
    Write-Title "Dev Tools (Full Deep Scan)  /  개발 도구 (정밀 스캔)"
    Write-Host "    Scanning PATH + known paths + registry..." -ForegroundColor DarkGray
    Write-Host ""

    # ==================== Runtime / Language ====================
    Write-SubTitle "Runtime / Language"

    Write-ToolCheck 'Python' (Find-Python)

    Write-ToolCheck 'Node.js' (Find-Tool 'node' '--version' @(
        "$PF\nodejs\node.exe",
        "$LAD\fnm_multishells\*\node.exe",
        "$AD\nvm\*\node.exe",
        "$UP\.nvm\versions\node\*\bin\node.exe",
        "$UP\.volta\bin\node.exe",
        "$UP\.nodenv\shims\node.exe"
    ))

    Write-ToolCheck 'Bun' (Find-Tool 'bun' '--version' @(
        "$UP\.bun\bin\bun.exe",
        "$LAD\bun\bun.exe",
        "$UP\scoop\apps\bun\current\bun.exe"
    ))

    Write-ToolCheck 'Deno' (Find-Tool 'deno' '--version' @(
        "$UP\.deno\bin\deno.exe",
        "$LAD\deno\deno.exe",
        "$UP\scoop\apps\deno\current\deno.exe"
    ))

    Write-ToolCheck 'Java' (Find-Tool 'java' '-version' @(
        "$PF\Java\*\bin\java.exe",
        "$PF\Eclipse Adoptium\*\bin\java.exe",
        "$PF\Amazon Corretto\*\bin\java.exe",
        "$PF\Zulu\*\bin\java.exe",
        "$PF\Microsoft\jdk-*\bin\java.exe",
        "$PF\BellSoft\LibericaJDK-*\bin\java.exe"
    ))

    Write-ToolCheck 'Go' (Find-Tool 'go' 'version' @(
        "$PF\Go\bin\go.exe",
        "$UP\go\bin\go.exe",
        "$UP\sdk\go*\bin\go.exe"
    ))

    Write-ToolCheck 'Rust (rustc)' (Find-Tool 'rustc' '--version' @(
        "$UP\.cargo\bin\rustc.exe",
        "$UP\.rustup\toolchains\stable-*\bin\rustc.exe"
    ))

    Write-ToolCheck 'Ruby' (Find-Tool 'ruby' '--version' @(
        "$PF\Ruby*\bin\ruby.exe",
        "$UP\scoop\apps\ruby\current\bin\ruby.exe"
    ))

    Write-ToolCheck 'PHP' (Find-Tool 'php' '--version' @(
        "$PF\PHP\php.exe",
        "$UP\scoop\apps\php\current\php.exe",
        "C:\php\php.exe",
        "C:\xampp\php\php.exe",
        "C:\wamp64\bin\php\*\php.exe"
    ))

    Write-ToolCheck 'Perl' (Find-Tool 'perl' '--version' @(
        "$PF\Perl64\bin\perl.exe",
        "C:\Strawberry\perl\bin\perl.exe"
    ))

    Write-ToolCheck 'Dart' (Find-Tool 'dart' '--version' @(
        "$LAD\Pub\Cache\bin\dart.exe",
        "$PF\Dart\dart-sdk\bin\dart.exe"
    ))

    Write-ToolCheck 'Kotlin' (Find-Tool 'kotlin' '-version' @(
        "$PF\kotlinc\bin\kotlin.bat"
    ))

    Write-ToolCheck 'Scala' (Find-Tool 'scala' '-version' @(
        "$PF\scala\bin\scala.bat"
    ))

    Write-ToolCheck 'Elixir' (Find-Tool 'elixir' '--version' @(
        "$PF\Elixir\bin\elixir.bat",
        "$UP\scoop\apps\elixir\current\bin\elixir.bat"
    ))

    Write-ToolCheck 'Erlang' (Find-Tool 'erl' '+V' @(
        "$PF\erl-*\bin\erl.exe"
    ))

    Write-ToolCheck 'Lua' (Find-Tool 'lua' '-v' @(
        "$PF\Lua\lua.exe",
        "$UP\scoop\apps\lua\current\lua.exe"
    ))

    Write-ToolCheck 'R' (Find-Tool 'Rscript' '--version' @(
        "$PF\R\*\bin\Rscript.exe"
    ))

    Write-ToolCheck 'Julia' (Find-Tool 'julia' '--version' @(
        "$LAD\Programs\Julia-*\bin\julia.exe",
        "$UP\scoop\apps\julia\current\bin\julia.exe"
    ))

    Write-ToolCheck 'Swift' (Find-Tool 'swift' '--version' @(
        "$PF\Swift\Toolchains\*\usr\bin\swift.exe"
    ))

    Write-ToolCheck 'Zig' (Find-Tool 'zig' 'version' @(
        "$UP\scoop\apps\zig\current\zig.exe",
        "$PF\zig\zig.exe"
    ))

    Write-ToolCheck 'Nim' (Find-Tool 'nim' '--version' @(
        "$UP\.nimble\bin\nim.exe"
    ))

    Write-ToolCheck 'Haskell (GHC)' (Find-Tool 'ghc' '--version' @(
        "$UP\ghcup\bin\ghc.exe",
        "$PF\Haskell\*\bin\ghc.exe",
        "$LAD\Programs\stack\*\ghc.exe"
    ))

    Write-ToolCheck 'OCaml' (Find-Tool 'ocaml' '--version' @())

    Write-ToolCheck 'Clojure' (Find-Tool 'clojure' '--version' @())

    Write-ToolCheck '.NET SDK' (Find-Tool 'dotnet' '--version' @(
        "$PF\dotnet\dotnet.exe"
    ))

    Write-ToolCheck 'GCC (MinGW)' (Find-Tool 'gcc' '--version' @(
        "$PF\mingw64\bin\gcc.exe",
        "C:\msys64\mingw64\bin\gcc.exe",
        "C:\mingw64\bin\gcc.exe",
        "$UP\scoop\apps\gcc\current\bin\gcc.exe"
    ))

    Write-ToolCheck 'Clang/LLVM' (Find-Tool 'clang' '--version' @(
        "$PF\LLVM\bin\clang.exe"
    ))

    Write-ToolCheck 'MSVC (cl)' (Find-Tool 'cl' '' @())

    Write-ToolCheck 'WASM (wasmtime)' (Find-Tool 'wasmtime' '--version' @(
        "$UP\.wasmtime\bin\wasmtime.exe"
    ))

    # ==================== Node Version Managers ====================
    Write-SubTitle "Node Version Manager"

    Write-ToolCheck 'nvm-windows' (Find-Tool 'nvm' 'version' @(
        "$AD\nvm\nvm.exe",
        "$PF\nvm\nvm.exe"
    ))

    Write-ToolCheck 'fnm' (Find-Tool 'fnm' '--version' @(
        "$UP\.fnm\fnm.exe",
        "$LAD\fnm_multishells\fnm.exe",
        "$UP\scoop\apps\fnm\current\fnm.exe",
        "$AD\fnm\fnm.exe"
    ))

    Write-ToolCheck 'Volta' (Find-Tool 'volta' '--version' @(
        "$UP\.volta\volta.exe",
        "$UP\.volta\bin\volta.exe"
    ))

    # ==================== Python Tools ====================
    Write-SubTitle "Python Tools"

    Write-ToolCheck 'pip' (Find-Pip)

    Write-ToolCheck 'pipx' (Find-Tool 'pipx' '--version' @(
        "$UP\.local\bin\pipx.exe",
        "$LAD\Programs\Python\*\Scripts\pipx.exe"
    ))

    Write-ToolCheck 'poetry' (Find-Tool 'poetry' '--version' @(
        "$AD\Python\Scripts\poetry.exe",
        "$AD\pypoetry\venv\Scripts\poetry.exe",
        "$UP\.local\bin\poetry.exe"
    ))

    Write-ToolCheck 'pipenv' (Find-Tool 'pipenv' '--version' @(
        "$LAD\Programs\Python\*\Scripts\pipenv.exe"
    ))

    Write-ToolCheck 'uv' (Find-Tool 'uv' '--version' @(
        "$UP\.cargo\bin\uv.exe",
        "$UP\.local\bin\uv.exe",
        "$LAD\uv\uv.exe"
    ))

    Write-ToolCheck 'ruff' (Find-Tool 'ruff' '--version' @(
        "$UP\.cargo\bin\ruff.exe",
        "$LAD\Programs\Python\*\Scripts\ruff.exe"
    ))

    Write-ToolCheck 'mypy' (Find-Tool 'mypy' '--version' @(
        "$LAD\Programs\Python\*\Scripts\mypy.exe"
    ))

    Write-ToolCheck 'black' (Find-Tool 'black' '--version' @(
        "$LAD\Programs\Python\*\Scripts\black.exe"
    ))

    Write-ToolCheck 'pyenv-win' (Find-Tool 'pyenv' '--version' @(
        "$UP\.pyenv\pyenv-win\bin\pyenv.bat"
    ))

    Write-ToolCheck 'Conda' (Find-Tool 'conda' '--version' @(
        "$UP\miniconda3\Scripts\conda.exe",
        "$UP\anaconda3\Scripts\conda.exe",
        "$UP\Miniconda3\Scripts\conda.exe",
        "$UP\Anaconda3\Scripts\conda.exe",
        "$PF\Miniconda3\Scripts\conda.exe"
    ))

    Write-ToolCheck 'virtualenv' (Find-Tool 'virtualenv' '--version' @(
        "$LAD\Programs\Python\*\Scripts\virtualenv.exe"
    ))

    # ==================== Package Manager ====================
    Write-SubTitle "Package Manager"

    Write-ToolCheck 'npm' (Find-Tool 'npm' '--version' @(
        "$PF\nodejs\npm.cmd",
        "$AD\npm\npm.cmd"
    ))

    Write-ToolCheck 'pnpm' (Find-Tool 'pnpm' '--version' @(
        "$LAD\pnpm\pnpm.exe",
        "$UP\scoop\apps\pnpm\current\pnpm.exe",
        "$AD\npm\pnpm.cmd"
    ))

    Write-ToolCheck 'yarn' (Find-Tool 'yarn' '--version' @(
        "$PF\Yarn\bin\yarn.cmd",
        "$UP\scoop\apps\yarn\current\bin\yarn.cmd",
        "$AD\npm\yarn.cmd"
    ))

    Write-ToolCheck 'Cargo' (Find-Tool 'cargo' '--version' @(
        "$UP\.cargo\bin\cargo.exe"
    ))

    Write-ToolCheck 'Composer' (Find-Tool 'composer' '--version' @(
        "$AD\Composer\vendor\bin\composer.bat",
        "$UP\scoop\apps\composer\current\composer.bat"
    ))

    Write-ToolCheck 'gem (Ruby)' (Find-Tool 'gem' '--version' @(
        "$PF\Ruby*\bin\gem.cmd"
    ))

    Write-ToolCheck 'NuGet' (Find-Tool 'nuget' 'help' @(
        "$UP\.nuget\nuget.exe",
        "$PF\NuGet\nuget.exe"
    ))

    Write-ToolCheck 'Homebrew' (Find-Tool 'brew' '--version' @())
    Write-ToolCheck 'Chocolatey' (Find-Tool 'choco' '--version' @(
        "$PF\Chocolatey\bin\choco.exe",
        "C:\ProgramData\chocolatey\bin\choco.exe"
    ))
    Write-ToolCheck 'Scoop' $(
        $s = Find-Tool 'scoop' '--version' @("$UP\scoop\apps\scoop\current\bin\scoop.ps1")
        if ($s) { $s } else { $null }
    )
    Write-ToolCheck 'winget' (Find-Tool 'winget' '--version' @(
        "$LAD\Microsoft\WindowsApps\winget.exe"
    ))

    # ==================== Version Control ====================
    Write-SubTitle "Version Control"

    Write-ToolCheck 'Git' (Find-Tool 'git' '--version' @(
        "$PF\Git\cmd\git.exe",
        "$PF86\Git\cmd\git.exe",
        "$UP\scoop\apps\git\current\cmd\git.exe"
    ))

    Write-ToolCheck 'GitHub CLI (gh)' (Find-Tool 'gh' '--version' @(
        "$PF\GitHub CLI\gh.exe",
        "$UP\scoop\apps\gh\current\bin\gh.exe"
    ))

    Write-ToolCheck 'Git LFS' (Find-Tool 'git-lfs' '--version' @(
        "$PF\Git LFS\git-lfs.exe",
        "$PF\Git\mingw64\bin\git-lfs.exe"
    ))

    Write-ToolCheck 'GitLab CLI (glab)' (Find-Tool 'glab' '--version' @(
        "$UP\scoop\apps\glab\current\glab.exe"
    ))

    Write-ToolCheck 'Mercurial (hg)' (Find-Tool 'hg' '--version' @(
        "$PF\Mercurial\hg.exe"
    ))

    Write-ToolCheck 'SVN' (Find-Tool 'svn' '--version' @(
        "$PF\TortoiseSVN\bin\svn.exe"
    ))

    # ==================== Editor / IDE ====================
    Write-SubTitle "Editor / IDE"

    Write-ToolCheck 'VS Code' (Find-GuiApp 'VS Code' @(
        "$LAD\Programs\Microsoft VS Code\Code.exe",
        "$PF\Microsoft VS Code\Code.exe",
        "$PF86\Microsoft VS Code\Code.exe"
    ) '*Visual Studio Code*')

    Write-ToolCheck 'VS Code Insiders' (Find-GuiApp 'VS Code Insiders' @(
        "$LAD\Programs\Microsoft VS Code Insiders\Code - Insiders.exe"
    ) '*Visual Studio Code Insiders*')

    Write-ToolCheck 'Cursor' (Find-GuiApp 'Cursor' @(
        "$LAD\Programs\cursor\Cursor.exe",
        "$LAD\cursor\Cursor.exe"
    ) '*Cursor*')

    Write-ToolCheck 'Windsurf' (Find-GuiApp 'Windsurf' @(
        "$LAD\Programs\Windsurf\Windsurf.exe",
        "$LAD\Programs\windsurf\Windsurf.exe"
    ) '*Windsurf*')

    Write-ToolCheck 'Trae' (Find-GuiApp 'Trae' @(
        "$LAD\Programs\Trae\Trae.exe"
    ) '*Trae*')

    Write-ToolCheck 'Zed' (Find-GuiApp 'Zed' @(
        "$LAD\Programs\Zed\Zed.exe",
        "$LAD\Zed\zed.exe"
    ) '*Zed*')

    Write-ToolCheck 'Visual Studio' (Find-GuiApp 'Visual Studio' @(
        "$PF\Microsoft Visual Studio\*\Community\Common7\IDE\devenv.exe",
        "$PF\Microsoft Visual Studio\*\Professional\Common7\IDE\devenv.exe",
        "$PF\Microsoft Visual Studio\*\Enterprise\Common7\IDE\devenv.exe"
    ) '*Visual Studio 20*')

    Write-ToolCheck 'IntelliJ IDEA' (Find-GuiApp 'IntelliJ' @(
        "$PF\JetBrains\IntelliJ IDEA*\bin\idea64.exe",
        "$LAD\JetBrains\Toolbox\apps\IDEA-*\bin\idea64.exe"
    ) '*IntelliJ IDEA*')

    Write-ToolCheck 'WebStorm' (Find-GuiApp 'WebStorm' @(
        "$PF\JetBrains\WebStorm*\bin\webstorm64.exe",
        "$LAD\JetBrains\Toolbox\apps\WebStorm*\bin\webstorm64.exe"
    ) '*WebStorm*')

    Write-ToolCheck 'PyCharm' (Find-GuiApp 'PyCharm' @(
        "$PF\JetBrains\PyCharm*\bin\pycharm64.exe",
        "$LAD\JetBrains\Toolbox\apps\PyCharm*\bin\pycharm64.exe"
    ) '*PyCharm*')

    Write-ToolCheck 'GoLand' (Find-GuiApp 'GoLand' @(
        "$PF\JetBrains\GoLand*\bin\goland64.exe"
    ) '*GoLand*')

    Write-ToolCheck 'CLion' (Find-GuiApp 'CLion' @(
        "$PF\JetBrains\CLion*\bin\clion64.exe"
    ) '*CLion*')

    Write-ToolCheck 'Rider' (Find-GuiApp 'Rider' @(
        "$PF\JetBrains\Rider*\bin\rider64.exe"
    ) '*JetBrains Rider*')

    Write-ToolCheck 'DataGrip' (Find-GuiApp 'DataGrip' @(
        "$PF\JetBrains\DataGrip*\bin\datagrip64.exe"
    ) '*DataGrip*')

    Write-ToolCheck 'Android Studio' (Find-GuiApp 'Android Studio' @(
        "$PF\Android\Android Studio\bin\studio64.exe"
    ) '*Android Studio*')

    Write-ToolCheck 'Xcode (via WSL)' $null  # Not applicable on Windows

    Write-ToolCheck 'Sublime Text' (Find-GuiApp 'Sublime Text' @(
        "$PF\Sublime Text\sublime_text.exe",
        "$PF\Sublime Text 3\sublime_text.exe"
    ) '*Sublime Text*')

    Write-ToolCheck 'Notepad++' (Find-GuiApp 'Notepad++' @(
        "$PF\Notepad++\notepad++.exe",
        "$PF86\Notepad++\notepad++.exe"
    ) '*Notepad++*')

    Write-ToolCheck 'Vim' (Find-Tool 'vim' '--version' @(
        "$PF\Vim\*\vim.exe"
    ))

    Write-ToolCheck 'Neovim' (Find-Tool 'nvim' '--version' @(
        "$PF\Neovim\bin\nvim.exe",
        "$UP\scoop\apps\neovim\current\bin\nvim.exe"
    ))

    Write-ToolCheck 'Emacs' (Find-Tool 'emacs' '--version' @(
        "$PF\Emacs\*\bin\emacs.exe",
        "$UP\scoop\apps\emacs\current\bin\emacs.exe"
    ))

    Write-ToolCheck 'Helix' (Find-Tool 'hx' '--version' @(
        "$UP\scoop\apps\helix\current\hx.exe"
    ))

    # ==================== AI Coding Tools ====================
    Write-SubTitle "AI Coding Tools"

    Write-ToolCheck 'Claude Code' (Find-Tool 'claude' '--version' @(
        "$AD\npm\claude.cmd",
        "$LAD\pnpm\claude.cmd",
        "$UP\.npm-global\claude.cmd"
    ))

    Write-ToolCheck 'Gemini CLI' (Find-Tool 'gemini' '--version' @(
        "$AD\npm\gemini.cmd",
        "$LAD\pnpm\gemini.cmd"
    ))

    Write-ToolCheck 'GitHub Copilot CLI' (Find-Tool 'github-copilot-cli' '--version' @(
        "$AD\npm\github-copilot-cli.cmd"
    ))

    Write-ToolCheck 'OpenAI CLI' (Find-Tool 'openai' '--version' @(
        "$LAD\Programs\Python\*\Scripts\openai.exe"
    ))

    Write-ToolCheck 'Codex CLI' (Find-Tool 'codex' '--version' @(
        "$AD\npm\codex.cmd",
        "$LAD\pnpm\codex.cmd"
    ))

    Write-ToolCheck 'Aider' (Find-Tool 'aider' '--version' @(
        "$UP\.local\bin\aider.exe",
        "$LAD\Programs\Python\*\Scripts\aider.exe",
        "$UP\scoop\apps\aider\current\aider.exe"
    ))

    Write-ToolCheck 'Continue' (Find-GuiApp 'Continue' @() '*Continue*')

    Write-ToolCheck 'Cody CLI' (Find-Tool 'cody' '--version' @(
        "$AD\npm\cody.cmd"
    ))

    Write-ToolCheck 'Tabnine' (Find-GuiApp 'Tabnine' @() '*Tabnine*')

    # ==================== Container / Infra ====================
    Write-SubTitle "Container / Infra"

    $dockerVer = Find-Tool 'docker' '--version' @(
        "$PF\Docker\Docker\resources\bin\docker.exe"
    )
    if (-not $dockerVer) {
        $dockerVer = Find-GuiApp 'Docker Desktop' @(
            "$PF\Docker\Docker\Docker Desktop.exe"
        ) '*Docker Desktop*'
    }
    Write-ToolCheck 'Docker' $dockerVer

    $dcVer = $null
    if (Get-Command 'docker-compose' -ErrorAction SilentlyContinue) {
        $dcVer = Get-ExeVersion (Get-Command 'docker-compose').Source '--version'
    } elseif (Get-Command 'docker' -ErrorAction SilentlyContinue) {
        try { $dc = & docker compose version 2>&1 | Out-String; if ($dc -match 'version') { $dcVer = $dc.Trim().Split("`n")[0].Trim() } } catch {}
    }
    Write-ToolCheck 'Docker Compose' $dcVer

    Write-ToolCheck 'Podman' (Find-Tool 'podman' '--version' @(
        "$PF\RedHat\Podman\podman.exe"
    ))

    Write-ToolCheck 'kubectl' (Find-Tool 'kubectl' 'version --client' @(
        "$UP\.kube\kubectl.exe",
        "$PF\kubectl\kubectl.exe"
    ))

    Write-ToolCheck 'Helm' (Find-Tool 'helm' 'version --short' @(
        "$UP\scoop\apps\helm\current\helm.exe"
    ))

    Write-ToolCheck 'minikube' (Find-Tool 'minikube' 'version --short' @(
        "$UP\scoop\apps\minikube\current\minikube.exe"
    ))

    Write-ToolCheck 'k9s' (Find-Tool 'k9s' 'version --short' @(
        "$UP\scoop\apps\k9s\current\k9s.exe"
    ))

    Write-ToolCheck 'Terraform' (Find-Tool 'terraform' '--version' @(
        "$UP\scoop\apps\terraform\current\terraform.exe",
        "$PF\Terraform\terraform.exe"
    ))

    Write-ToolCheck 'Pulumi' (Find-Tool 'pulumi' 'version' @(
        "$UP\.pulumi\bin\pulumi.exe"
    ))

    Write-ToolCheck 'Ansible' (Find-Tool 'ansible' '--version' @())

    Write-ToolCheck 'Vagrant' (Find-Tool 'vagrant' '--version' @(
        "$PF\HashiCorp\Vagrant\bin\vagrant.exe"
    ))

    # ==================== Cloud CLI ====================
    Write-SubTitle "Cloud CLI"

    Write-ToolCheck 'AWS CLI' (Find-Tool 'aws' '--version' @(
        "$PF\Amazon\AWSCLIV2\aws.exe"
    ))

    Write-ToolCheck 'Azure CLI' (Find-Tool 'az' '--version' @(
        "$PF\Microsoft SDKs\Azure\CLI2\wbin\az.cmd",
        "$PF86\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
    ))

    Write-ToolCheck 'Google Cloud' (Find-Tool 'gcloud' '--version' @(
        "$LAD\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
        "$PF\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
    ))

    Write-ToolCheck 'Vercel CLI' (Find-Tool 'vercel' '--version' @(
        "$AD\npm\vercel.cmd"
    ))

    Write-ToolCheck 'Netlify CLI' (Find-Tool 'netlify' '--version' @(
        "$AD\npm\netlify.cmd"
    ))

    Write-ToolCheck 'Cloudflare (wrangler)' (Find-Tool 'wrangler' '--version' @(
        "$AD\npm\wrangler.cmd"
    ))

    Write-ToolCheck 'Fly.io (flyctl)' (Find-Tool 'flyctl' 'version' @(
        "$UP\.fly\bin\flyctl.exe"
    ))

    Write-ToolCheck 'Railway CLI' (Find-Tool 'railway' '--version' @(
        "$AD\npm\railway.cmd"
    ))

    Write-ToolCheck 'Render CLI' (Find-Tool 'render' '--version' @())

    Write-ToolCheck 'Heroku CLI' (Find-Tool 'heroku' '--version' @(
        "$LAD\heroku\bin\heroku.cmd"
    ))

    # ==================== Database ====================
    Write-SubTitle "Database Client / Tools"

    Write-ToolCheck 'Supabase CLI' (Find-Tool 'supabase' '--version' @(
        "$UP\scoop\apps\supabase\current\supabase.exe",
        "$AD\npm\supabase.cmd"
    ))

    Write-ToolCheck 'Firebase CLI' (Find-Tool 'firebase' '--version' @(
        "$AD\npm\firebase.cmd"
    ))

    Write-ToolCheck 'MySQL' (Find-Tool 'mysql' '--version' @(
        "$PF\MySQL\*\bin\mysql.exe",
        "C:\xampp\mysql\bin\mysql.exe",
        "C:\wamp64\bin\mysql\*\bin\mysql.exe"
    ))

    Write-ToolCheck 'PostgreSQL (psql)' (Find-Tool 'psql' '--version' @(
        "$PF\PostgreSQL\*\bin\psql.exe"
    ))

    Write-ToolCheck 'SQLite' (Find-Tool 'sqlite3' '--version' @(
        "$UP\scoop\apps\sqlite\current\sqlite3.exe"
    ))

    Write-ToolCheck 'Redis CLI' (Find-Tool 'redis-cli' '--version' @())

    Write-ToolCheck 'MongoDB (mongosh)' (Find-Tool 'mongosh' '--version' @(
        "$LAD\Programs\mongosh\mongosh.exe"
    ))

    Write-ToolCheck 'DBeaver' (Find-GuiApp 'DBeaver' @(
        "$PF\DBeaver\dbeaver.exe",
        "$LAD\Programs\DBeaver\dbeaver.exe"
    ) '*DBeaver*')

    Write-ToolCheck 'pgAdmin' (Find-GuiApp 'pgAdmin' @(
        "$PF\pgAdmin 4\*\runtime\pgAdmin4.exe"
    ) '*pgAdmin*')

    Write-ToolCheck 'MongoDB Compass' (Find-GuiApp 'MongoDB Compass' @(
        "$LAD\MongoDBCompass\MongoDBCompass.exe"
    ) '*MongoDB Compass*')

    Write-ToolCheck 'TablePlus' (Find-GuiApp 'TablePlus' @(
        "$PF\TablePlus\TablePlus.exe"
    ) '*TablePlus*')

    # ==================== Build / Framework ====================
    Write-SubTitle "Build / Framework / Bundler"

    Write-ToolCheck 'Make' (Find-Tool 'make' '--version' @(
        "$PF\GnuWin32\bin\make.exe",
        "$UP\scoop\apps\make\current\bin\make.exe",
        "C:\msys64\usr\bin\make.exe"
    ))

    Write-ToolCheck 'CMake' (Find-Tool 'cmake' '--version' @(
        "$PF\CMake\bin\cmake.exe"
    ))

    Write-ToolCheck 'Ninja' (Find-Tool 'ninja' '--version' @(
        "$UP\scoop\apps\ninja\current\ninja.exe"
    ))

    Write-ToolCheck 'Gradle' (Find-Tool 'gradle' '--version' @(
        "$PF\Gradle\*\bin\gradle.bat"
    ))

    Write-ToolCheck 'Maven (mvn)' (Find-Tool 'mvn' '--version' @(
        "$PF\Apache\Maven\*\bin\mvn.cmd"
    ))

    Write-ToolCheck 'Flutter' (Find-Tool 'flutter' '--version' @(
        "$UP\flutter\bin\flutter.bat",
        "$UP\dev\flutter\bin\flutter.bat",
        "$UP\fvm\default\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat"
    ))

    Write-ToolCheck 'React Native CLI' (Find-Tool 'react-native' '--version' @(
        "$AD\npm\react-native.cmd"
    ))

    Write-ToolCheck 'Expo CLI' (Find-Tool 'expo' '--version' @(
        "$AD\npm\expo.cmd"
    ))

    Write-ToolCheck 'Vite' (Find-Tool 'vite' '--version' @(
        "$AD\npm\vite.cmd"
    ))

    Write-ToolCheck 'Webpack' (Find-Tool 'webpack' '--version' @(
        "$AD\npm\webpack.cmd"
    ))

    Write-ToolCheck 'esbuild' (Find-Tool 'esbuild' '--version' @(
        "$AD\npm\esbuild.cmd"
    ))

    Write-ToolCheck 'Turbo (Turborepo)' (Find-Tool 'turbo' '--version' @(
        "$AD\npm\turbo.cmd"
    ))

    Write-ToolCheck 'nx' (Find-Tool 'nx' '--version' @(
        "$AD\npm\nx.cmd"
    ))

    Write-ToolCheck 'Bazel' (Find-Tool 'bazel' '--version' @(
        "$UP\scoop\apps\bazel\current\bazel.exe"
    ))

    # ==================== Linters / Formatters ====================
    Write-SubTitle "Linter / Formatter / Testing"

    Write-ToolCheck 'ESLint' (Find-Tool 'eslint' '--version' @(
        "$AD\npm\eslint.cmd"
    ))

    Write-ToolCheck 'Prettier' (Find-Tool 'prettier' '--version' @(
        "$AD\npm\prettier.cmd"
    ))

    Write-ToolCheck 'Biome' (Find-Tool 'biome' '--version' @(
        "$AD\npm\biome.cmd"
    ))

    Write-ToolCheck 'oxlint' (Find-Tool 'oxlint' '--version' @(
        "$AD\npm\oxlint.cmd"
    ))

    Write-ToolCheck 'Jest' (Find-Tool 'jest' '--version' @(
        "$AD\npm\jest.cmd"
    ))

    Write-ToolCheck 'Vitest' (Find-Tool 'vitest' '--version' @(
        "$AD\npm\vitest.cmd"
    ))

    Write-ToolCheck 'Playwright' (Find-Tool 'playwright' '--version' @(
        "$AD\npm\playwright.cmd"
    ))

    Write-ToolCheck 'Cypress' (Find-Tool 'cypress' '--version' @(
        "$AD\npm\cypress.cmd"
    ))

    Write-ToolCheck 'pytest' (Find-Tool 'pytest' '--version' @(
        "$LAD\Programs\Python\*\Scripts\pytest.exe"
    ))

    Write-ToolCheck 'golangci-lint' (Find-Tool 'golangci-lint' '--version' @(
        "$UP\go\bin\golangci-lint.exe"
    ))

    Write-ToolCheck 'shellcheck' (Find-Tool 'shellcheck' '--version' @(
        "$UP\scoop\apps\shellcheck\current\shellcheck.exe"
    ))

    Write-ToolCheck 'hadolint' (Find-Tool 'hadolint' '--version' @(
        "$UP\scoop\apps\hadolint\current\hadolint.exe"
    ))

    # ==================== Networking / API / Utility ====================
    Write-SubTitle "Network / API / Utility"

    Write-ToolCheck 'curl' (Find-Tool 'curl' '--version' @(
        "C:\Windows\System32\curl.exe"
    ))

    Write-ToolCheck 'wget' (Find-Tool 'wget' '--version' @(
        "$UP\scoop\apps\wget\current\wget.exe"
    ))

    Write-ToolCheck 'httpie' (Find-Tool 'http' '--version' @(
        "$LAD\Programs\Python\*\Scripts\http.exe"
    ))

    Write-ToolCheck 'jq' (Find-Tool 'jq' '--version' @(
        "$UP\scoop\apps\jq\current\jq.exe"
    ))

    Write-ToolCheck 'yq' (Find-Tool 'yq' '--version' @(
        "$UP\scoop\apps\yq\current\yq.exe"
    ))

    Write-ToolCheck 'fzf' (Find-Tool 'fzf' '--version' @(
        "$UP\scoop\apps\fzf\current\fzf.exe"
    ))

    Write-ToolCheck 'ripgrep (rg)' (Find-Tool 'rg' '--version' @(
        "$UP\scoop\apps\ripgrep\current\rg.exe",
        "$UP\.cargo\bin\rg.exe"
    ))

    Write-ToolCheck 'fd' (Find-Tool 'fd' '--version' @(
        "$UP\scoop\apps\fd\current\fd.exe",
        "$UP\.cargo\bin\fd.exe"
    ))

    Write-ToolCheck 'bat' (Find-Tool 'bat' '--version' @(
        "$UP\scoop\apps\bat\current\bat.exe",
        "$UP\.cargo\bin\bat.exe"
    ))

    Write-ToolCheck 'eza (ls)' (Find-Tool 'eza' '--version' @(
        "$UP\scoop\apps\eza\current\eza.exe",
        "$UP\.cargo\bin\eza.exe"
    ))

    Write-ToolCheck 'delta (diff)' (Find-Tool 'delta' '--version' @(
        "$UP\scoop\apps\delta\current\delta.exe",
        "$UP\.cargo\bin\delta.exe"
    ))

    Write-ToolCheck 'zoxide (cd)' (Find-Tool 'zoxide' '--version' @(
        "$UP\scoop\apps\zoxide\current\zoxide.exe",
        "$UP\.cargo\bin\zoxide.exe"
    ))

    Write-ToolCheck 'ngrok' (Find-Tool 'ngrok' 'version' @(
        "$UP\scoop\apps\ngrok\current\ngrok.exe",
        "$UP\ngrok\ngrok.exe"
    ))

    Write-ToolCheck 'Postman' (Find-GuiApp 'Postman' @(
        "$LAD\Postman\Postman.exe"
    ) '*Postman*')

    Write-ToolCheck 'Insomnia' (Find-GuiApp 'Insomnia' @(
        "$LAD\insomnia\Insomnia.exe"
    ) '*Insomnia*')

    Write-ToolCheck 'Bruno' (Find-GuiApp 'Bruno' @(
        "$LAD\Programs\bruno\Bruno.exe"
    ) '*Bruno*')

    # ==================== Shell / Terminal ====================
    Write-SubTitle "Shell / Terminal"

    Write-ToolCheck 'PowerShell' (Find-Tool 'pwsh' '--version' @(
        "$PF\PowerShell\7\pwsh.exe"
    ))

    Write-ToolCheck 'Windows Terminal' (Find-GuiApp 'Windows Terminal' @(
        "$LAD\Microsoft\WindowsApps\wt.exe"
    ) '*Windows Terminal*')

    Write-ToolCheck 'Warp' (Find-GuiApp 'Warp' @(
        "$LAD\Programs\Warp\Warp.exe"
    ) '*Warp*')

    Write-ToolCheck 'Alacritty' (Find-Tool 'alacritty' '--version' @(
        "$UP\scoop\apps\alacritty\current\alacritty.exe",
        "$PF\Alacritty\alacritty.exe"
    ))

    Write-ToolCheck 'WezTerm' (Find-GuiApp 'WezTerm' @(
        "$PF\WezTerm\wezterm-gui.exe"
    ) '*WezTerm*')

    Write-ToolCheck 'Hyper' (Find-GuiApp 'Hyper' @(
        "$LAD\hyper\Hyper.exe"
    ) '*Hyper*')

    Write-ToolCheck 'Tabby' (Find-GuiApp 'Tabby' @(
        "$LAD\Programs\Tabby\Tabby.exe"
    ) '*Tabby*')

    Write-ToolCheck 'tmux (WSL)' $null

    Write-ToolCheck 'starship' (Find-Tool 'starship' '--version' @(
        "$UP\scoop\apps\starship\current\starship.exe",
        "$UP\.cargo\bin\starship.exe"
    ))

    Write-ToolCheck 'oh-my-posh' (Find-Tool 'oh-my-posh' '--version' @(
        "$LAD\Programs\oh-my-posh\bin\oh-my-posh.exe",
        "$UP\scoop\apps\oh-my-posh\current\oh-my-posh.exe"
    ))

    # ==================== Design / Collaboration ====================
    Write-SubTitle "Design / Collaboration"

    Write-ToolCheck 'Figma' (Find-GuiApp 'Figma' @(
        "$LAD\Figma\Figma.exe"
    ) '*Figma*')

    Write-ToolCheck 'Slack' (Find-GuiApp 'Slack' @(
        "$LAD\slack\slack.exe"
    ) '*Slack*')

    Write-ToolCheck 'Discord' (Find-GuiApp 'Discord' @(
        "$LAD\Discord\Update.exe"
    ) '*Discord*')

    Write-ToolCheck 'Notion' (Find-GuiApp 'Notion' @(
        "$LAD\Notion\Notion.exe"
    ) '*Notion*')

    Write-ToolCheck 'Obsidian' (Find-GuiApp 'Obsidian' @(
        "$LAD\Obsidian\Obsidian.exe"
    ) '*Obsidian*')

    # ==================== Security / Crypto ====================
    Write-SubTitle "Security / Crypto"

    Write-ToolCheck 'OpenSSL' (Find-Tool 'openssl' 'version' @(
        "$PF\OpenSSL-Win64\bin\openssl.exe",
        "$PF\Git\usr\bin\openssl.exe"
    ))

    Write-ToolCheck 'SSH' (Find-Tool 'ssh' '-V' @(
        "C:\Windows\System32\OpenSSH\ssh.exe"
    ))

    Write-ToolCheck 'GPG' (Find-Tool 'gpg' '--version' @(
        "$PF\GnuPG\bin\gpg.exe",
        "$PF86\GnuPG\bin\gpg.exe"
    ))

    Write-ToolCheck 'age' (Find-Tool 'age' '--version' @(
        "$UP\scoop\apps\age\current\age.exe"
    ))

    Write-ToolCheck 'sops' (Find-Tool 'sops' '--version' @(
        "$UP\scoop\apps\sops\current\sops.exe"
    ))

    # ==================== Media / Misc ====================
    Write-SubTitle "Media / Misc Dev Tools"

    Write-ToolCheck 'FFmpeg' (Find-Tool 'ffmpeg' '-version' @(
        "$UP\scoop\apps\ffmpeg\current\bin\ffmpeg.exe",
        "$PF\FFmpeg\bin\ffmpeg.exe"
    ))

    Write-ToolCheck 'ImageMagick' (Find-Tool 'magick' '--version' @(
        "$PF\ImageMagick-*\magick.exe"
    ))

    Write-ToolCheck 'Pandoc' (Find-Tool 'pandoc' '--version' @(
        "$LAD\Pandoc\pandoc.exe",
        "$UP\scoop\apps\pandoc\current\pandoc.exe"
    ))

    Write-ToolCheck 'Hugo' (Find-Tool 'hugo' 'version' @(
        "$UP\scoop\apps\hugo\current\hugo.exe"
    ))

    Write-ToolCheck 'LaTeX (pdflatex)' (Find-Tool 'pdflatex' '--version' @(
        "$PF\MiKTeX\miktex\bin\x64\pdflatex.exe",
        "C:\texlive\*\bin\windows\pdflatex.exe"
    ))

    Write-ToolCheck 'Graphviz (dot)' (Find-Tool 'dot' '-V' @(
        "$PF\Graphviz\bin\dot.exe"
    ))

    Write-ToolCheck 'Mermaid CLI' (Find-Tool 'mmdc' '--version' @(
        "$AD\npm\mmdc.cmd"
    ))

    Write-Host ""
}

# ================================================================
#  WSL
# ================================================================

function Get-WSLInfo {
    Write-Title "WSL (Windows Subsystem for Linux)  /  WSL (윈도우 속 리눅스)"
    $wslExists = Get-Command 'wsl' -ErrorAction SilentlyContinue
    if (-not $wslExists) {
        Write-Host "    [X] WSL is NOT installed" -ForegroundColor Red
        Write-Host ""
        Write-Host "    To install: Run 'wsl --install' in admin terminal" -ForegroundColor DarkGray
        Write-Host ""
        return
    }
    Write-Host "    [O] WSL command found" -ForegroundColor Green
    Write-Host ""
    try {
        $wslVer = & wsl --version 2>&1 | Out-String
        $lines = $wslVer.Trim().Split("`n")
        foreach ($line in $lines) {
            $line = $line.Trim()
            if ($line.Length -gt 0) { Write-Host "    $line" -ForegroundColor White }
        }
    } catch {
        Write-Host "    Could not get WSL version info" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-SubTitle "Installed Distros"
    try {
        $distros = & wsl --list --verbose 2>&1 | Out-String
        $lines = $distros.Trim().Split("`n")
        $hasDistro = $false
        foreach ($line in $lines) {
            $line = $line.Trim() -replace '\x00', ''
            if ($line.Length -gt 2) { Write-Host "    $line"; $hasDistro = $true }
        }
        if (-not $hasDistro) {
            Write-Host "    No distros installed" -ForegroundColor Yellow
            Write-Host "    To install Ubuntu: wsl --install -d Ubuntu" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "    Could not list distros" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-SubTitle "Dev Tools inside WSL"
    try {
        $wslTools = @(
            @{Name='gcc'; Label='GCC (C Compiler)'},
            @{Name='g++'; Label='G++ (C++)'},
            @{Name='python3'; Label='Python3'},
            @{Name='pip3'; Label='pip3'},
            @{Name='node'; Label='Node.js'},
            @{Name='npm'; Label='npm'},
            @{Name='bun'; Label='Bun'},
            @{Name='deno'; Label='Deno'},
            @{Name='go'; Label='Go'},
            @{Name='rustc'; Label='Rust'},
            @{Name='java'; Label='Java'},
            @{Name='ruby'; Label='Ruby'},
            @{Name='git'; Label='Git'},
            @{Name='docker'; Label='Docker'},
            @{Name='make'; Label='Make'},
            @{Name='cmake'; Label='CMake'},
            @{Name='curl'; Label='curl'},
            @{Name='wget'; Label='wget'},
            @{Name='ssh'; Label='SSH'},
            @{Name='tmux'; Label='tmux'},
            @{Name='zsh'; Label='Zsh'},
            @{Name='fish'; Label='Fish'}
        )
        foreach ($t in $wslTools) {
            $check = & wsl which $t.Name 2>&1 | Out-String
            $check = $check.Trim()
            if ($check -match '/' -and $check -notmatch 'not found') {
                $ver = & wsl $t.Name --version 2>&1 | Out-String
                $ver = $ver.Trim().Split("`n")[0].Trim()
                if ($ver.Length -gt 60) { $ver = $ver.Substring(0,60) + '...' }
                if ($ver -match 'not recognized|error|unknown') { $ver = $check }
                $pad = $t.Label.PadRight(18)
                Write-Host "    [O] $pad : $ver" -ForegroundColor Green
            } else {
                $pad = $t.Label.PadRight(18)
                Write-Host "    [X] $pad : not found" -ForegroundColor DarkGray
            }
        }
    } catch {
        Write-Host "    Could not check WSL tools (no default distro?)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# ================================================================
#  SCORE + RECOMMENDATIONS
# ================================================================

function Get-Score {
    Write-Title "SCORE + Recommendations  /  점수 + 추천"
    $score = 0
    $weaknesses = @()

    # --- CPU (max 20) ---
    try {
        $cpu = Get-CimInstance Win32_Processor
        $cores = $cpu.NumberOfCores
        $threads = $cpu.NumberOfLogicalProcessors
        if ($cores -ge 8) { $cpuScore = 20 }
        elseif ($cores -ge 6) { $cpuScore = 16 }
        elseif ($cores -ge 4) { $cpuScore = 12 }
        elseif ($cores -ge 2) { $cpuScore = 6 }
        else { $cpuScore = 3 }
        if ($cores -lt 4) { $weaknesses += "CPU: Only $cores cores. 4+ recommended for dev work." }
    } catch { $cpuScore = 0; $cores = '?'; $threads = '?' }
    Write-Host "    CPU ($cores cores/$threads threads) : $cpuScore / 20"
    $score += $cpuScore

    # --- RAM (max 20) ---
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB)
        if ($ramGB -ge 64) { $ramScore = 20 }
        elseif ($ramGB -ge 32) { $ramScore = 18 }
        elseif ($ramGB -ge 16) { $ramScore = 14 }
        elseif ($ramGB -ge 8) { $ramScore = 8 }
        else { $ramScore = 3 }
        if ($ramGB -lt 16) { $weaknesses += "RAM: ${ramGB}GB. 16GB+ recommended for modern dev." }
    } catch { $ramScore = 0; $ramGB = '?' }
    Write-Host "    RAM (${ramGB}GB)              : $ramScore / 20"
    $score += $ramScore

    # --- Storage (max 15) ---
    $storScore = 0
    try {
        $hasSSD = $false; $hasNVMe = $false
        $msftDisks = Get-CimInstance -Namespace root/microsoft/windows/storage -ClassName MSFT_PhysicalDisk -ErrorAction SilentlyContinue
        foreach ($md in $msftDisks) {
            if ($md.MediaType -eq 4) { $hasSSD = $true }
            if ($md.BusType -eq 17) { $hasNVMe = $true }
        }
        if ($hasNVMe) { $storScore = 15 }
        elseif ($hasSSD) { $storScore = 12 }
        else { $storScore = 5; $weaknesses += "Storage: No SSD detected. SSD greatly improves dev speed." }
        # Check free space on C:
        $cDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        if ($cDrive) {
            $freeGB = [math]::Round($cDrive.FreeSpace / 1GB)
            if ($freeGB -lt 30) { $storScore = [math]::Max($storScore - 3, 0); $weaknesses += "Storage: Only ${freeGB}GB free on C:. Consider cleanup." }
        }
    } catch {}
    $storLabel = if ($hasNVMe) {'NVMe SSD'} elseif ($hasSSD) {'SSD'} else {'HDD'}
    Write-Host "    Storage ($storLabel)        : $storScore / 15"
    $score += $storScore

    # --- GPU (max 10) ---
    $gpuScore = 0
    try {
        $gpus = Get-CimInstance Win32_VideoController
        $hasDedicated = $false
        foreach ($g in $gpus) {
            if ($g.AdapterRAM -and $g.AdapterRAM -gt 1GB) {
                $hasDedicated = $true
                $vramGB = [math]::Round($g.AdapterRAM / 1GB)
                if ($vramGB -ge 8) { $gpuScore = [math]::Max($gpuScore, 10) }
                elseif ($vramGB -ge 4) { $gpuScore = [math]::Max($gpuScore, 8) }
                elseif ($vramGB -ge 2) { $gpuScore = [math]::Max($gpuScore, 5) }
            }
        }
        if (-not $hasDedicated) { $gpuScore = 3 }
    } catch {}
    Write-Host "    GPU                       : $gpuScore / 10"
    $score += $gpuScore

    # --- Dev Tools (max 35) ---
    $toolScore = 0

    # Core tools (5 pts each, max 15)
    if (Find-Python) { $toolScore += 5 } else { $weaknesses += "Dev: Python not found. Essential for many dev tasks." }
    $nodeVer = Find-Tool 'node' '--version' @("$PF\nodejs\node.exe","$UP\.volta\bin\node.exe")
    if ($nodeVer) { $toolScore += 5 } else { $weaknesses += "Dev: Node.js not found. Needed for web development." }
    $gitVer = Find-Tool 'git' '--version' @("$PF\Git\cmd\git.exe")
    if ($gitVer) { $toolScore += 5 } else { $weaknesses += "Dev: Git not found. Essential for version control." }

    # Package managers (2 pts each, max 6)
    $pmScore = 0
    if (Find-Tool 'npm' '--version' @("$PF\nodejs\npm.cmd")) { $pmScore += 2 }
    if (Find-Tool 'pnpm' '--version' @("$LAD\pnpm\pnpm.exe")) { $pmScore += 2 }
    if (Find-Pip) { $pmScore += 2 }
    if ($pmScore -gt 6) { $pmScore = 6 }
    $toolScore += $pmScore

    # Editors (max 4)
    $edScore = 0
    if (Find-GuiApp 'VS Code' @("$LAD\Programs\Microsoft VS Code\Code.exe") '*Visual Studio Code*') { $edScore += 2 }
    if (Find-GuiApp 'Cursor' @("$LAD\Programs\cursor\Cursor.exe") '*Cursor*') { $edScore += 2 }
    if (Find-GuiApp 'IntelliJ' @("$PF\JetBrains\IntelliJ IDEA*\bin\idea64.exe") '*IntelliJ*') { $edScore += 2 }
    if (Find-Tool 'nvim' '--version' @("$PF\Neovim\bin\nvim.exe")) { $edScore += 2 }
    if ($edScore -gt 4) { $edScore = 4 }
    $toolScore += $edScore
    if ($edScore -eq 0) { $weaknesses += "Dev: No code editor/IDE detected." }

    # AI tools (max 4)
    $aiScore = 0
    if (Find-Tool 'claude' '--version' @("$AD\npm\claude.cmd")) { $aiScore += 2 }
    if (Find-Tool 'gemini' '--version' @("$AD\npm\gemini.cmd")) { $aiScore += 2 }
    if (Find-Tool 'codex' '--version' @("$AD\npm\codex.cmd")) { $aiScore += 2 }
    if (Find-Tool 'aider' '--version' @("$UP\.local\bin\aider.exe")) { $aiScore += 2 }
    if ($aiScore -gt 4) { $aiScore = 4 }
    $toolScore += $aiScore

    # Extra tools (1 pt each, max 6)
    $extraScore = 0
    if (Find-Tool 'docker' '--version' @("$PF\Docker\Docker\resources\bin\docker.exe")) { $extraScore += 1 }
    if (Find-Tool 'gh' '--version' @("$PF\GitHub CLI\gh.exe")) { $extraScore += 1 }
    if (Find-Tool 'bun' '--version' @("$UP\.bun\bin\bun.exe")) { $extraScore += 1 }
    if (Find-Tool 'rustc' '--version' @("$UP\.cargo\bin\rustc.exe")) { $extraScore += 1 }
    if (Find-Tool 'go' 'version' @("$PF\Go\bin\go.exe")) { $extraScore += 1 }
    if (Find-Tool 'make' '--version' @("$PF\GnuWin32\bin\make.exe")) { $extraScore += 1 }
    if (Find-Tool 'terraform' '--version' @()) { $extraScore += 1 }
    if (Find-Tool 'kubectl' 'version' @()) { $extraScore += 1 }
    if (Find-Tool 'aws' '--version' @("$PF\Amazon\AWSCLIV2\aws.exe")) { $extraScore += 1 }
    if (Find-Tool 'rg' '--version' @("$UP\.cargo\bin\rg.exe")) { $extraScore += 1 }
    if ($extraScore -gt 6) { $extraScore = 6 }
    $toolScore += $extraScore

    if ($toolScore -gt 35) { $toolScore = 35 }
    Write-Host "    Dev Tools                 : $toolScore / 35"
    $score += $toolScore

    # --- Total ---
    Write-Host ""
    Write-Host "    ================================================" -ForegroundColor Cyan
    if ($score -ge 85) { $clr = 'Green'; $grade = 'S' }
    elseif ($score -ge 70) { $clr = 'Green'; $grade = 'A' }
    elseif ($score -ge 55) { $clr = 'Yellow'; $grade = 'B' }
    elseif ($score -ge 40) { $clr = 'Yellow'; $grade = 'C' }
    else { $clr = 'Red'; $grade = 'D' }
    Write-Host "    TOTAL : $score / 100  (Grade: $grade)" -ForegroundColor $clr
    Write-Host "    ================================================" -ForegroundColor Cyan

    if ($score -ge 85) { Write-Host "    >> Excellent dev machine!" -ForegroundColor Green }
    elseif ($score -ge 70) { Write-Host "    >> Great setup for development!" -ForegroundColor Green }
    elseif ($score -ge 55) { Write-Host "    >> Decent setup. Some room to improve." -ForegroundColor Yellow }
    elseif ($score -ge 40) { Write-Host "    >> Needs improvement for serious dev work." -ForegroundColor Yellow }
    else { Write-Host "    >> Consider upgrading hardware + installing dev tools." -ForegroundColor Red }

    # --- Recommendations ---
    if ($weaknesses.Count -gt 0) {
        Write-Host ""
        Write-SubTitle "Recommendations"
        foreach ($w in $weaknesses) {
            Write-Host "    [!] $w" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# ================================================================
#  MAIN LOOP
# ================================================================
try {
    $running = $true
    while ($running) {
        Show-Header
        Show-Menu
        $choice = Read-Host "  Enter number / 번호 입력 (0-15)"
        switch ($choice) {
            '1' {
                Show-Header
                Write-Host "  Full system scan... please wait!  /  전체 스캔 중... 잠시만 기다려 주세요!" -ForegroundColor Yellow
                Write-Host ""
                Get-BasicInfo
                Get-CPUInfo
                Get-RAMInfo
                Get-DiskInfo
                Get-GPUInfo
                Get-NetworkInfo
                Get-BatteryInfo
                Get-SecurityInfo
                Get-StartupInfo
                Get-AudioUsbInfo
                Get-InstalledApps
                Get-DevToolsInfo
                Get-WSLInfo
                Get-Score
                $null = Read-Host "  [Enter] Back to menu / 메뉴로"
            }
            '2'  { Show-Header; Get-BasicInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '3'  { Show-Header; Get-CPUInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '4'  { Show-Header; Get-RAMInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '5'  { Show-Header; Get-DiskInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '6'  { Show-Header; Get-GPUInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '7'  { Show-Header; Get-NetworkInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '8'  { Show-Header; Get-BatteryInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '9'  { Show-Header; Get-SecurityInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '10' { Show-Header; Get-StartupInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '11' { Show-Header; Get-AudioUsbInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '12' { Show-Header; Get-InstalledApps; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '13' { Show-Header; Get-DevToolsInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '14' { Show-Header; Get-WSLInfo; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '15' { Show-Header; Get-Score; $null = Read-Host "  [Enter] Back to menu / 메뉴로" }
            '0'  { $running = $false }
            default {
                Write-Host "  Please enter 0-15!  /  0~15 사이 숫자를 입력하세요!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    Write-Host ""
    Write-Host "  Goodbye!  /  안녕히 가세요!" -ForegroundColor Cyan
    Start-Sleep -Seconds 1
} catch {
    Write-Host ""
    Write-Host "  [!] Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

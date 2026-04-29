<#
.SYNOPSIS
    Main Repop script. Reads the config, finds the browser, and pops the URL.
#>

# --- P/Invoke for Foreground Window ---
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    public class WindowHelper {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowTextLength(IntPtr hWnd);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

        private const int SW_RESTORE = 9;

        public static string GetActiveWindowTitle() {
            IntPtr hWnd = GetForegroundWindow();
            if (hWnd == IntPtr.Zero) return null;

            int length = GetWindowTextLength(hWnd);
            if (length == 0) return null;

            StringBuilder sb = new StringBuilder(length + 1);
            GetWindowText(hWnd, sb, sb.Capacity);
            return sb.ToString();
        }

        public static bool ActivateWindow(IntPtr hWnd, bool restore) {
            if (hWnd == IntPtr.Zero) return false;
            if (restore) {
                ShowWindowAsync(hWnd, SW_RESTORE);
            }
            return SetForegroundWindow(hWnd);
        }

        public static bool ActivateWindow(IntPtr hWnd) {
            return ActivateWindow(hWnd, true);
        }

        public static string GetWindowTitle(IntPtr hWnd) {
            if (hWnd == IntPtr.Zero) return null;
            int length = GetWindowTextLength(hWnd);
            if (length <= 0) return null;
            StringBuilder sb = new StringBuilder(length + 1);
            GetWindowText(hWnd, sb, sb.Capacity);
            return sb.ToString();
        }
    }
"@

# --- Helper Function to Find Browser ---
function Find-BrowserPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BrowserName,

        [Parameter(Mandatory=$false)]
        [string]$ManualPath
    )

    # 1. If a manual path is provided and valid, use it.
    if (-not ([string]::IsNullOrWhiteSpace($ManualPath)) -and (Test-Path -Path $ManualPath)) {
        return $ManualPath
    }

    # 2. Otherwise, search common locations.
    $basePaths = @(
        [System.Environment]::GetFolderPath('ProgramFiles'),
        [System.Environment]::GetFolderPath('ProgramFilesX86')
    ) | Get-Unique

    $browserPaths = @{
        firefox = @("Mozilla Firefox\firefox.exe")
        chrome  = @("Google\Chrome\Application\chrome.exe")
        msedge  = @("Microsoft\Edge\Application\msedge.exe")
        brave   = @("BraveSoftware\Brave-Browser\Application\brave.exe")
    }

    if ($browserPaths.ContainsKey($BrowserName)) {
        foreach ($base in $basePaths) {
            foreach ($subPath in $browserPaths[$BrowserName]) {
                $fullPath = Join-Path -Path $base -ChildPath $subPath
                if (Test-Path -Path $fullPath) {
                    return $fullPath
                }
            }
        }
    }

    # 3. If not found, return null.
    return $null
}

# --- Helper for safely sending keystrokes ---
function ConvertTo-SendKeysLiteral {
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputText
    )

    $output = $InputText
    $replacements = @{
        "{" = "{{}"
        "}" = "{}}"
        "+" = "{+}"
        "%" = "{%}"
        "^" = "{^}"
        "~" = "{~}"
    }

    foreach ($key in $replacements.Keys) {
        $output = $output.Replace($key, $replacements[$key])
    }

    return $output
}

function Get-BrowserMainProcess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName,

        [Parameter(Mandatory=$false)]
        [string]$WindowTitleSearch
    )

    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    foreach ($proc in $processes) {
        try {
            $title = $proc.MainWindowTitle
            $handle = $proc.MainWindowHandle
        }
        catch {
            continue
        }

        if ($handle -eq 0) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($WindowTitleSearch) -or $title -like "*$WindowTitleSearch*") {
            return $proc
        }
    }

    return $null
}

function Get-TargetHostTokens {
    param(
        [Parameter(Mandatory=$true)]
        [System.Uri]$Uri
    )

    $hostSegments = $Uri.Host.Split('.') | Where-Object { $_ -and $_ -notin @('www','com','org','net','co','io') }

    $pathSegments = @()
    if ($Uri.AbsolutePath -and $Uri.AbsolutePath -ne '/') {
        $pathSegments = $Uri.AbsolutePath.Trim('/').Split('/') | Where-Object { $_ }
    }

    return ($hostSegments + $pathSegments) | Where-Object { $_ } | Select-Object -Unique
}

function Test-WindowTitleMatchesTarget {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string[]]$Tokens,

        [Parameter(Mandatory=$false)]
        [string]$WindowTitleSearch
    )

    if ([string]::IsNullOrWhiteSpace($Title)) {
        return $false
    }

    if (-not [string]::IsNullOrWhiteSpace($WindowTitleSearch) -and $Title -notlike "*$WindowTitleSearch*") {
        return $false
    }

    foreach ($token in $Tokens) {
        if ($Title -like "*$token*") {
            return $true
        }
    }

    return $false
}

function Invoke-BrowserNavigation {
    param(
        [Parameter(Mandatory=$true)]
        [System.Diagnostics.Process]$BrowserProcess,

        [Parameter(Mandatory=$true)]
        [string]$TargetUrl
    )

    try {
        $shell = New-Object -ComObject WScript.Shell
    }
    catch {
        return $false
    }

    $windowHandle = $BrowserProcess.MainWindowHandle
    if (-not [WindowHelper]::ActivateWindow($windowHandle)) {
        return $false
    }

    # Give the window a moment to surface before interacting with it.
    Start-Sleep -Milliseconds 200

    # Focus the address bar, type the target URL, and navigate without spawning a new tab.
    $shell.SendKeys("^l")
    Start-Sleep -Milliseconds 150
    $shell.SendKeys((ConvertTo-SendKeysLiteral -InputText $TargetUrl))
    Start-Sleep -Milliseconds 100
    $shell.SendKeys("{ENTER}")

    return $true
}

# --- Main Script Logic ---

$ScriptDir = $PSScriptRoot
$ConfigPath = Join-Path -Path $ScriptDir -ChildPath "config.ps1"

# 1. Load config.ps1
if (-not (Test-Path -Path $ConfigPath)) {
    # Fail silently; this is a background task. Add logging here in the future if needed.
    exit 1
}
try {
    . $ConfigPath
}
catch {
    exit 1 # Fail silently on config syntax error.
}

$focusBehavior = 'foreground'
if ($Config.ContainsKey('FocusBehavior') -and -not [string]::IsNullOrWhiteSpace($Config.FocusBehavior)) {
    $focusBehavior = $Config.FocusBehavior
}

switch ($focusBehavior.ToLowerInvariant()) {
    'restoreprevious' { $focusBehavior = 'restoreprevious' }
    'foreground'      { $focusBehavior = 'foreground' }
    default           { $focusBehavior = 'foreground' }
}

$focusReturnDelaySeconds = 2.0
if ($Config.ContainsKey('FocusReturnDelaySeconds')) {
    $rawDelay = $Config.FocusReturnDelaySeconds
    if ($rawDelay -is [double] -or $rawDelay -is [float] -or $rawDelay -is [int] -or $rawDelay -is [long]) {
        $focusReturnDelaySeconds = [Math]::Max(0, [double]$rawDelay)
    }
    else {
        $parsedDelay = 0.0
        if ([double]::TryParse([string]$rawDelay, [ref]$parsedDelay)) {
            $focusReturnDelaySeconds = [Math]::Max(0, $parsedDelay)
        }
    }
}

$focusReturnDelayMs = [int]([Math]::Round($focusReturnDelaySeconds * 1000))

$targetUri = [System.Uri]$Config.URL
$hostTokens = Get-TargetHostTokens -Uri $targetUri

# 2. Check current active window to avoid unnecessary work when already focused on the right tab.
$activeWindowTitle = [WindowHelper]::GetActiveWindowTitle()
if (-not ([string]::IsNullOrWhiteSpace($activeWindowTitle))) {
    if (Test-WindowTitleMatchesTarget -Title $activeWindowTitle -Tokens $hostTokens -WindowTitleSearch $Config.WindowTitleSearch) {
        exit 0
    }
}

# 3. Find browser executable
$browserExePath = Find-BrowserPath -BrowserName $Config.BrowserExeName -ManualPath $Config.BrowserExePath
if (-not $browserExePath) {
    # Browser not found, can't continue.
    exit 1
}

# 4. Bring the browser forward without spawning redundant tabs.
$processName = [System.IO.Path]::GetFileNameWithoutExtension($Config.BrowserExeName)
if ([string]::IsNullOrWhiteSpace($processName)) {
    $processName = $Config.BrowserExeName
}

$lastRunFile = Join-Path $PSScriptRoot 'last_run.txt'

$previousWindowHandle = [IntPtr]::Zero
if ($focusBehavior -eq 'restoreprevious') {
    $previousWindowHandle = [WindowHelper]::GetForegroundWindow()
}

$browserProcess = Get-BrowserMainProcess -ProcessName $processName -WindowTitleSearch $Config.WindowTitleSearch
$browserMainHandle = [IntPtr]::Zero
$navigationSucceeded = $false

if ($browserProcess) {
    $browserMainHandle = $browserProcess.MainWindowHandle
    $browserTitle = $browserProcess.MainWindowTitle
    $matchesTarget = Test-WindowTitleMatchesTarget -Title $browserTitle -Tokens $hostTokens -WindowTitleSearch $Config.WindowTitleSearch

    if ($matchesTarget) {
        $navigationSucceeded = [WindowHelper]::ActivateWindow($browserMainHandle, $true)
    }
    else {
        $navigationSucceeded = Invoke-BrowserNavigation -BrowserProcess $browserProcess -TargetUrl $Config.URL
    }
}

if (-not $navigationSucceeded) {
    Start-Process -FilePath $browserExePath -ArgumentList $Config.URL
    Start-Sleep -Seconds 3
    $browserProcess = Get-BrowserMainProcess -ProcessName $processName -WindowTitleSearch $Config.WindowTitleSearch
    if ($browserProcess) {
        $browserMainHandle = $browserProcess.MainWindowHandle
        Invoke-BrowserNavigation -BrowserProcess $browserProcess -TargetUrl $Config.URL | Out-Null
    }
}
elseif ($browserProcess -and -not $browserMainHandle) {
    $browserMainHandle = $browserProcess.MainWindowHandle
}

if ($focusBehavior -eq 'restoreprevious' -and $previousWindowHandle -ne [IntPtr]::Zero) {
    if ($browserMainHandle -ne [IntPtr]::Zero -and $browserMainHandle -ne $previousWindowHandle) {
        if ($focusReturnDelayMs -gt 0) {
            Start-Sleep -Milliseconds $focusReturnDelayMs
        }
        [WindowHelper]::ActivateWindow($previousWindowHandle, $false) | Out-Null
    }
}

try {
    (Get-Date).ToString('o') | Out-File $lastRunFile -Encoding UTF8
}
catch {
    # Ignore logging failures; best-effort only.
}
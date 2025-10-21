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

        public static string GetActiveWindowTitle() {
            IntPtr hWnd = GetForegroundWindow();
            if (hWnd == IntPtr.Zero) return null;

            int length = GetWindowTextLength(hWnd);
            if (length == 0) return null;

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

# 2.2. Implement "Snooze" / Intelligent Interruption
$activeWindowTitle = [WindowHelper]::GetActiveWindowTitle()
if (-not ([string]::IsNullOrWhiteSpace($activeWindowTitle))) {
    # Check if the active window is already the target browser AND contains "Trello"
    if ($activeWindowTitle -like "*Trello*" -and $activeWindowTitle -like "*$($Config.WindowTitleSearch)*") {
        # Already on Trello in the target browser, so snooze.
        exit 0
    }
}

# 2. Find browser executable
$browserExePath = Find-BrowserPath -BrowserName $Config.BrowserExeName -ManualPath $Config.BrowserExePath
if (-not $browserExePath) {
    # Browser not found, can't continue.
    exit 1
}

# 3. Launch browser/new tab with URL
# This will open a new tab if the browser is already running.
Start-Process -FilePath $browserExePath -ArgumentList $Config.URL

# 4. Find browser window and bring it to the foreground
Start-Sleep -Seconds 2 # Give the browser a moment to open/focus the tab
$shell = New-Object -ComObject WScript.Shell
# AppActivate will find a window whose title *contains* the search string.
$shell.AppActivate($Config.WindowTitleSearch)
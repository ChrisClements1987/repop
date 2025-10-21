<#
.SYNOPSIS
    Installs or updates the Repop scheduled task based on config.ps1.
#>

#Requires -RunAsAdministrator

$TaskName = "Repop"
$ScriptDir = $PSScriptRoot
$ConfigPath = Join-Path -Path $ScriptDir -ChildPath "config.ps1"
$RepopScriptPath = Join-Path -Path $ScriptDir -ChildPath "repop.ps1"

Write-Host "--- Repop Installer ---"

# 1. Load config.ps1
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "Configuration file not found at '$ConfigPath'. Aborting."
    exit 1
}
try {
    . $ConfigPath
    Write-Host "Successfully loaded configuration."
}
catch {
    Write-Error "Failed to load or parse '$ConfigPath'. Please check for syntax errors."
    exit 1
}

# 2. Check if task "Repop" exists and delete it for a clean install
Write-Host "Checking for existing scheduled task '$TaskName'..."
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Write-Host "Found existing task. Removing it to apply new settings..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# 3. Create new scheduled task with settings from config
Write-Host "Creating new scheduled task..."

# Define the action to run repop.ps1 silently
$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$RepopScriptPath`""

# Define the trigger based on the configured frequency
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $Config.FrequencyMinutes) -RepetitionDuration (New-TimeSpan -Days 9999)

# Define settings to make it robust (e.g., run on battery)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

# Register the task to run as the current user
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Periodically brings a specific browser tab to the foreground." -RunLevel Limited

Write-Host "✅ Success! Repop task '$TaskName' has been created/updated to run every $($Config.FrequencyMinutes) minutes."
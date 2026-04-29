<#
.SYNOPSIS
    Re-registers the Repop scheduled task pointing at the current script location.
    Use this if the task was registered from a different path and needs updating.
#>

#Requires -RunAsAdministrator

$TaskName = "Repop"
$CurrentDir = $PSScriptRoot
$RepopScriptPath = Join-Path -Path $CurrentDir -ChildPath "repop.ps1"
$ConfigPath = Join-Path -Path $CurrentDir -ChildPath "config.ps1"

Write-Host "--- Fixing Repop Task ---"
Write-Host "Script location: $RepopScriptPath"

# Load config
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

# Remove existing task
Write-Host "Checking for existing scheduled task '$TaskName'..."
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Write-Host "Found existing task. Removing it..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create new task with correct path
Write-Host "Creating new scheduled task with correct path..."

$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$RepopScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $Config.FrequencyMinutes) -RepetitionDuration (New-TimeSpan -Days 9999)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Periodically brings a specific browser tab to the foreground." -RunLevel Limited

Write-Host "✅ Success! Repop task '$TaskName' has been created."
Write-Host "Task will run every $($Config.FrequencyMinutes) minutes."
Write-Host "Script path: $RepopScriptPath"

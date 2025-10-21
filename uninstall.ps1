<#
.SYNOPSIS
    Uninstalls the Repop scheduled task.
#>

$TaskName = "Repop"

Write-Host "Repop Uninstaller - Checking for scheduled task '$TaskName'..."

# Find the scheduled task
$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($Task) {
    Write-Host "Found task '$TaskName'. Removing..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Repop task '$TaskName' has been removed."
} else {
    Write-Host "Repop task '$TaskName' was not found. Nothing to do."
}
# Import a power plan from a .pow file in PowerShell

param(
    [Parameter(Mandatory=$true)]
    [string]$PowFilePath
)

if (-not (Test-Path $PowFilePath)) {
    Write-Error "File not found: $PowFilePath"
    exit 1
}

# Import the power plan and capture the output
$importOutput = powercfg -import "$PowFilePath"
Start-Sleep -Seconds 1

# Get the GUID of the most recently imported plan
$plans = powercfg -list
$importedPlan = ($plans | Select-String -Pattern "Power Scheme GUID: ([a-fA-F0-9\-]+) \((.+)\)").Matches | 
    Sort-Object { $_.Groups[2].Value } -Descending | Select-Object -First 1

if (-not $importedPlan) {
    Write-Error "Could not find imported power plan."
    exit 1
}

$guid = $importedPlan.Groups[1].Value
Write-Host "Imported plan GUID: $guid"

# Set the imported plan as active (for current user)
powercfg -setactive $guid

# Set as default for all users (requires admin)
# This sets the active scheme in the default user registry hive
reg load HKU\DefaultUser C:\Users\Default\NTUSER.DAT
reg add "HKU\DefaultUser\Control Panel\PowerCfg" /v CurrentPowerPolicy /t REG_SZ /d $guid /f
reg unload HKU\DefaultUser

Write-Host "Power plan set as active for current and default users."
Write-Host "Stopping Outlook if running..."
Stop-Process -Name OUTLOOK -Force -ErrorAction SilentlyContinue

Write-Host "Removing Outlook profiles from registry..."

# Remove all profiles under current user
$profilePath = "HKCU:\Software\Microsoft\Office"
Get-ChildItem $profilePath -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "Outlook\\Profiles" } |
    ForEach-Object {
        try {
            Remove-Item $_.PsPath -Recurse -Force
            Write-Host "Removed: $($_.PsPath)"
        } catch {
            Write-Warning "Failed to remove: $($_.PsPath)"
        }
    }

# Remove Outlook auto-discover cache
$autodiscoverPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\AutoDiscover"
if (Test-Path $autodiscoverPath) {
    Remove-Item -Path $autodiscoverPath -Recurse -Force
    Write-Host "Cleared AutoDiscover cache."
}

# Remove identity info (newer Outlook builds)
$identityPath = "HKCU:\Software\Microsoft\Office\16.0\Common\Identity"
if (Test-Path $identityPath) {
    Remove-Item -Path $identityPath -Recurse -Force
    Write-Host "Cleared Identity registry info."
}

# Remove old Outlook profile list (may be used in some builds)
$profileListPath = "HKCU:\Software\Microsoft\Office\Outlook\Profiles"
if (Test-Path $profileListPath) {
    Remove-Item -Path $profileListPath -Recurse -Force
    Write-Host "Removed fallback profile list."
}

Write-Host "Outlook profiles removed. A fresh profile will be created on next launch."

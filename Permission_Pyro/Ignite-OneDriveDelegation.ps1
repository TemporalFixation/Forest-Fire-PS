# Ensure SharePoint Online module is available
if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Write-Host "SharePoint Online module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force -Scope CurrentUser
}
Import-Module Microsoft.Online.SharePoint.PowerShell

# Prompt for information
$tenant = Read-Host "Enter your Microsoft 365 tenant (e.g., contoso)"
$user = Read-Host "Enter the user whose OneDrive you want to share (e.g., user@contoso.com)"
$delegate = Read-Host "Enter the delegate's email address (e.g., manager@contoso.com)"

# Connect to SharePoint Online
$adminUrl = "https://$tenant-admin.sharepoint.com"
Write-Host "`nConnecting to SharePoint Online at $adminUrl..." -ForegroundColor Cyan
Connect-SPOService -Url $adminUrl

# Format OneDrive site URL correctly (no extra tenant suffix)
$onedriveUserPart = $user.Replace("@", "_").Replace(".", "_")
$onedriveUrl = "https://$tenant-my.sharepoint.com/personal/$onedriveUserPart"
$onedriveLink = "$onedriveUrl/_layouts/15/onedrive.aspx"

# Grant delegate Site Collection Admin rights
Write-Host "Granting $delegate access to $user's OneDrive..." -ForegroundColor Yellow
Set-SPOUser -Site $onedriveUrl -LoginName $delegate -IsSiteCollectionAdmin $true

# Output result
Write-Host "`nDelegate access granted." -ForegroundColor Green
Write-Host "`nDelegate can access the user's OneDrive at:" -ForegroundColor Green
Write-Host $onedriveLink -ForegroundColor White

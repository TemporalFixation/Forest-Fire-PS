# Ensure Exchange Online module is available
if (-not (Get-Module -Name ExchangeOnlineManagement)) {
    try {
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
    } catch {
        Write-Error "❌ ExchangeOnlineManagement module not found. Run 'Install-Module ExchangeOnlineManagement' first."
        exit
    }
}

# Prompt for user email/UPN
$userUPN = Read-Host "🔹 Enter the user's email address (UPN)"

# Connect to Exchange Online if not already connected
try {
    if (-not (Get-ConnectionInformation)) {
        Write-Host "🔌 Connecting to Exchange Online..."
        Connect-ExchangeOnline -ShowBanner:$false
    }
} catch {
    Write-Error "❌ Could not connect to Exchange Online: $_"
    exit
}

Write-Host "`n🔍 Scanning shared mailboxes for permissions assigned to: $userUPN"
Write-Host "--------------------------------------------------"

$found = $false
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

foreach ($mbx in $sharedMailboxes) {
    $sendAs = $null
    $sob = $null
    $fullAccess = $null

    # Check Send As
    try {
        $sendAs = Get-RecipientPermission -Identity $mbx.Identity -ErrorAction Stop | Where-Object {
            $_.Trustee -match $userUPN -and $_.AccessRights -contains 'SendAs'
        }
    } catch { }

    # Check Send on Behalf
    try {
        $sob = (Get-Mailbox $mbx.Identity -ErrorAction Stop).GrantSendOnBehalfTo | Where-Object {
            $_.PrimarySmtpAddress -eq $userUPN -or $_.Name -eq $userUPN
        }
    } catch { }

    # Check Full Access
    try {
        $fullAccess = Get-MailboxPermission -Identity $mbx.Identity -ErrorAction Stop | Where-Object {
            $_.User.ToString() -eq $userUPN -and $_.AccessRights -contains "FullAccess"
        }
    } catch { }

    if ($sendAs -or $sob -or $fullAccess) {
        $found = $true
        Write-Host "`n📬 $($mbx.DisplayName) <$($mbx.PrimarySmtpAddress)>"
        if ($sendAs)     { Write-Host "  ✔ Send As" }
        if ($sob)        { Write-Host "  ✔ Send on Behalf" }
        if ($fullAccess) { Write-Host "  ✔ Full Access" }
    }
}

if (-not $found) {
    Write-Host "`n⚠️  No permissions found for $userUPN on any shared mailbox."
} else {
    Write-Host "`n✅ Done scanning."
}

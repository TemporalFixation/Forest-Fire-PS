
param(
    [switch]$DryRun
)

# Prompt for Domain Controller FQDN
$domainController = Read-Host "Enter the FQDN of the Domain Controller (e.g., dc01.local.org)"

# Prompt for AzureAD/Entra Sync Server FQDN
$syncServer = Read-Host "Enter the FQDN of the AzureAD/Entra Sync Server (e.g., svc1.local.org)"

# Load AD module
Import-Module ActiveDirectory

# Prompt for Organization Name
$orgName = Read-Host "Enter the name of the Organization (e.g., School of Rock) for the Auto Reply"

# Prompt for UPN (email)
$upn = Read-Host "Enter the UPN (email address) of the user to offboard"

# Prompt for Domain Admin credentials
$creds = Get-Credential

# Prompt for target OU in LDAP format
$targetOU = Read-Host "Enter the full LDAP path for the target OU (e.g., OU=Disabled_Users,OU=Sites,DC=local,DC=fehb,DC=org)"

# Get AD user
try {
    $adUser = Get-ADUser -Server $domainController -Credential $creds -Filter { UserPrincipalName -eq $upn } -Properties DistinguishedName, MemberOf, DisplayName, Manager
} catch {
    Write-Warning "Could not find AD user for $upn"
    return
}

$displayName = $adUser.DisplayName
$currentOU = ($adUser.DistinguishedName -replace '^CN=.*?,', '')

# Move to target OU if needed
if ($currentOU -ieq $targetOU) {
    Write-Output "✔ $upn is already in the target OU. Skipping move."
} else {
    if (-not $DryRun) {
        Move-ADObject -Server $domainController -Credential $creds -Identity $adUser.DistinguishedName -TargetPath $targetOU
        Write-Output "✅ Moved $upn to $targetOU"
    } else {
        Write-Output "[DryRun] Would run: Move-ADObject -Server $domainController -Credential $creds -Identity $adUser.DistinguishedName -TargetPath $targetOU"
        Write-Output "[DryRun] Would report: Move to $targetOU"
    }
}

# Remove all groups except Domain Users
$groupsToRemove = $adUser.MemberOf | Where-Object {
    (Get-ADGroup -Server $domainController -Identity $_ -Credential $creds).Name -ne "Domain Users"
}
foreach ($groupDN in $groupsToRemove) {
    try {
        if (-not $DryRun) {
            Remove-ADGroupMember -Server $domainController -Credential $creds -Identity $groupDN -Members $adUser -Confirm:$false
            Write-Output "🚫 Removed $upn from group: $groupDN"
        } else {
            Write-Output "[DryRun] Would run: Remove-ADGroupMember -Server $domainController -Credential $creds -Identity $groupDN -Members $adUser -Confirm:$false"
            Write-Output "[DryRun] Would report: Remove $upn from $groupDN"
        }
    } catch {
        Write-Warning ("⚠ Failed to remove " + $upn + " from group " + $groupDN + ": " + $_.Exception.Message)
    }
}

# Get manager info
$manager = $null
if ($adUser.Manager) {
    $manager = Get-ADUser -Server $domainController -Identity $adUser.Manager -Properties DisplayName, UserPrincipalName
    $supervisorName = $manager.DisplayName
    $supervisorEmail = $manager.UserPrincipalName
} else {
    $supervisorName = Read-Host "Manager not found in AD. Enter supervisor's display name"
    $supervisorEmail = Read-Host "Enter supervisor's email"
}


# Trigger AAD Sync remotely
Write-Output "🔄 Triggering AD sync on $syncServer..."
try {
    Invoke-Command -ComputerName $syncServer -Credential $creds -ArgumentList $DryRun -ScriptBlock {
        param($dryRun)
        Import-Module ADSync
        if (-not $dryRun) {
            Start-ADSyncSyncCycle -PolicyType Delta
        } else {
            Write-Output "[DryRun] Would run: Start-ADSyncSyncCycle -PolicyType Delta"
        }
    }
    Write-Output "✅ Sync started. Waiting 120 seconds for sync to complete..."
    Start-Sleep -Seconds 120
} catch {
    Write-Warning "❌ Failed to trigger AD sync: " + $_.Exception.Message
}


# Convert to shared mailbox
try {
    if (-not $DryRun) {
        Set-Mailbox -Identity $upn -Type Shared
    } else {
        Write-Output "[DryRun] Would run: Set-Mailbox -Identity $upn -Type Shared"
    }
    Write-Output "✅ Converted $upn to shared mailbox"
} catch {
    Write-Warning "❌ Failed to convert mailbox for ${upn} " + $_.Exception.Message
}

# Rename mailbox display name
$newDisplayName = "$displayName (Departed)"
try {
    if (-not $DryRun) {
        Set-Mailbox -Identity $upn -DisplayName $newDisplayName
    } else {
        Write-Output "[DryRun] Would run: Set-Mailbox -Identity $upn -DisplayName $newDisplayName"
    }
    Write-Output "✏️ Renamed mailbox to '$newDisplayName'"
} catch {
    Write-Warning "❌ Failed to rename mailbox: " + $_.Exception.Message
}

# Hide mailbox from the Global Address List
try {
    if (-not $DryRun) {
        Set-Mailbox -Identity $upn -HiddenFromAddressListsEnabled $true
    } else {
        Write-Output "[DryRun] Would run: Set-Mailbox -Identity $upn -HiddenFromAddressListsEnabled $true"
    }
    Write-Output "🙈 Mailbox hidden from the Global Address List"
} catch {
    Write-Warning "❌ Failed to hide mailbox: " + $_.Exception.Message
}

# Grant full access to supervisor
try {
    if (-not $DryRun) {
        Add-MailboxPermission -Identity $upn -User $supervisorEmail -AccessRights FullAccess -InheritanceType All
    } else {
        Write-Output "[DryRun] Would run: Add-MailboxPermission -Identity $upn -User $supervisorEmail -AccessRights FullAccess -InheritanceType All"
    }
    Write-Output "✅ Granted mailbox access to $supervisorEmail"
} catch {
    Write-Warning "❌ Failed to assign delegate: " + $_.Exception.Message
}

# Set auto-reply via Graph
$autoReply = @{
    Status = "AlwaysEnabled"
    InternalReplyMessage = "Thank you for contacting $orgName. We regret to inform you that $displayName is no longer employed here. Please direct any future correspondence to $supervisorName at $supervisorEmail. This is an automated reply. For your convenience, this email has been automatically forwarded to $supervisorName."
    ExternalReplyMessage = "Thank you for contacting $orgName. We regret to inform you that $displayName is no longer employed here. Please direct any future correspondence to $supervisorName at $supervisorEmail. This is an automated reply. For your convenience, this email has been automatically forwarded to $supervisorName."
}

try {
    Set-MgUserMailboxSettings -UserId $upn -AutomaticRepliesSetting $autoReply
    Write-Output "📬 Auto-reply message configured"
} catch {
    Write-Warning "❌ Failed to set auto-reply: " + $_.Exception.Message
}

# Set email forwarding to supervisor
try {
    if (-not $DryRun) {
        Set-Mailbox -Identity $upn -ForwardingSMTPAddress $supervisorEmail -DeliverToMailboxAndForward $true
    } else {
        Write-Output "[DryRun] Would run: Set-Mailbox -Identity $upn -ForwardingSMTPAddress $supervisorEmail -DeliverToMailboxAndForward $true"
    }
    Write-Output "📨 Forwarding enabled to $supervisorEmail"
} catch {
    Write-Warning "❌ Failed to configure forwarding: " + $_.Exception.Message
}

# Remove direct licenses
try {
    $skuIds = (Get-MgUserLicenseDetail -UserId $upn).SkuId
    if ($skuIds.Count -gt 0) {
        Set-MgUserLicense -UserId $upn -RemoveLicenses $skuIds -AddLicenses @()
        Write-Output "🧹 Removed direct licenses from $upn"
    } else {
        Write-Output "ℹ️ No direct licenses found to remove"
    }
} catch {
    Write-Warning "❌ Failed to remove licenses: " + $_.Exception.Message
}

Write-Output "`n🎉 Offboarding complete for $upn"

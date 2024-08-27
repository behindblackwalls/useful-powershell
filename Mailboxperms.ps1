# Import the ExchangeOnlineManagement module and connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Function to fetch mailbox permissions
function Get-MailboxPermissions {
    param (
        [string]$Mailbox
    )

    $results = @()

    # Fetch Full Access permissions
    $fullAccessPerms = Get-MailboxPermission -Identity $Mailbox | Where-Object { $_.AccessRights -contains "FullAccess" -and -not $_.IsInherited -and $_.User -notlike "NT AUTHORITY\*" }
    foreach ($perm in $fullAccessPerms) {
        $results += [PSCustomObject]@{
            Mailbox        = $Mailbox
            User           = $perm.User.ToString()
            PermissionType = "Read and Manage"
        }
    }

    # Fetch Send As permissions
    $sendAsPerms = Get-Mailbox -Identity $Mailbox | Select-Object -ExpandProperty GrantSendOnBehalfTo
    foreach ($user in $sendAsPerms) {
        $results += [PSCustomObject]@{
            Mailbox        = $Mailbox
            User           = $user
            PermissionType = "Send As"
        }
    }

    # Fetch Send On Behalf permissions
    $sendOnBehalfPerms = Get-RecipientPermission -Identity $Mailbox | Where-Object { $_.Trustee -like "*@*" }
    foreach ($perm in $sendOnBehalfPerms) {
        $results += [PSCustomObject]@{
            Mailbox        = $Mailbox
            User           = $perm.Trustee
            PermissionType = "Send On Behalf"
        }
    }

    return $results
}

# Get all user mailboxes and their permissions
$mailboxes = Get-Mailbox -ResultSize Unlimited
$allPermissions = foreach ($mailbox in $mailboxes) {
    Get-MailboxPermissions -Mailbox $mailbox.PrimarySmtpAddress
}

# Output the results
$allPermissions | Format-Table -AutoSize -Property Mailbox, User, PermissionType

# Disconnect the session
Disconnect-ExchangeOnline -Confirm:$false

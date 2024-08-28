# Connect to Exchange Online
Connect-ExchangeOnline 

$mailboxes = Get-Mailbox -ResultSize Unlimited
foreach ($mailbox in $mailboxes) {
    $rules = Get-InboxRule -Mailbox $mailbox.UserPrincipalName
    foreach ($rule in $rules) {
        if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo) {
            $external = $false
            foreach ($address in $rule.ForwardTo + $rule.ForwardAsAttachmentTo) {
                if ($address.ToString() -notmatch "elephantsdeli.com") {
                    $external = $true
                }
            }
            if ($external -eq $true) {
                Write-Host "Suspicious rule found in mailbox:" $mailbox.UserPrincipalName
                Write-Host $rule.Name, $rule.Enabled, $rule.Description
            }
        }
    }
}


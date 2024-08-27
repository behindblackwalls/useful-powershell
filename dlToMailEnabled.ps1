# Function to simulate text being typed out
function Write-Slowly {
    param(
        [string]$Text,
        [int]$Delay = 10,
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::Green
    )

    $Text.ToCharArray() | ForEach-Object {
        Write-Host -NoNewline $_ -ForegroundColor $ForegroundColor
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

# Function to display 'How To Use' information
function Show-HowToUse {
    Write-Slowly "Welcome to GroupHug! A Group Migration Tool for Exchange Online!" -ForegroundColor Green
    Write-Slowly "=====================================" -ForegroundColor Green
    Write-Slowly "This tool is designed to assist in migrating AzureAD groups from Distribution Lists to Security-Enabled Mailboxes."
    Write-Slowly "Follow the on-screen instructions to migrate a group."
    Write-Slowly ""
    Write-Slowly "Instructions:" -ForegroundColor Green
    Write-Slowly "--------------"
    Write-Slowly "1. Choose 'Migrate Group' to start the migration process."
    Write-Slowly "2. You'll be asked to provide the name of the old group, make sure to type it exactly as it appears."
    Write-Slowly "3. The script will then automate the migration process."
    Write-Slowly "4. You'll be notified upon successful or unsuccessful completion."
    Write-Slowly "5. Choose 'Exit' to close the program."
    Write-Slowly ""
    Write-Slowly "Press any key to continue..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


# Import required modules if not already imported
Import-Module AzureAD
Import-Module ExchangeOnlineManagement

# Connect to Azure AD and Exchange Online
$UserCredential = Get-Credential
Connect-AzureAD -Credential $UserCredential
Connect-ExchangeOnline -Credential $UserCredential

while ($true) {
    # Display ASCII Art
    Write-Slowly "   _______________                        |*\_/*|________" -ForegroundColor DarkGreen
    Write-Slowly "  |  ___________  |     .-.     .-.      ||_/-\_|______  |" -ForegroundColor DarkGreen
    Write-Slowly "  | |           | |    .****. .****.     | |           | |" -ForegroundColor DarkGreen
    Write-Slowly "  | |   0   0   | |    .*****.*****.     | |   0   0   | |" -ForegroundColor DarkGreen
    Write-Slowly "  | |     -     | |     .*********.      | |     -     | |" -ForegroundColor DarkGreen
    Write-Slowly "  | |   \___/   | |      .*******.       | |   \___/   | |" -ForegroundColor DarkGreen
    Write-Slowly "  | |___     ___| |       .*****.        | |___________| |" -ForegroundColor DarkGreen
    Write-Slowly "  |_____|\_/|_____|        .***.         |_______________|" -ForegroundColor DarkGreen
    Write-Slowly "    _|__|/ \|_|_.............*.............._|________|_" -ForegroundColor DarkGreen
    Write-Slowly "   / ********** \                          / ********** \ " -ForegroundColor DarkGreen
    Write-Slowly " /  ************  \                      /  ************  \ " -ForegroundColor DarkGreen
    Write-Slowly "--------------------                    --------------------" -ForegroundColor DarkGreen

    # Menu
    while ($true) {
        # Display ASCII Art and menu
        # Your existing ASCII art code goes here...
    
        Write-Host "1. Migrate Group" -ForegroundColor Cyan
        Write-Host "2. Help" -ForegroundColor Cyan
        Write-Host "3. Exit" -ForegroundColor Cyan
        $menuChoice = Read-Host "Please select an option"
    
        if ($menuChoice -eq "1") {
            # Migrate group code here...
            break
        } elseif ($menuChoice -eq "2") {
            Show-HowToUse
        } elseif ($menuChoice -eq "3") {
            Write-Host "Exiting the program." -ForegroundColor Red
            exit
        } else {
            Write-Host "Invalid option. Please select again." -ForegroundColor Red
        }
    }

    # Initialize variables
    $oldGroupName = Read-Host "Please enter the name of the old group exactly as it appears"
    $newGroupName = $oldGroupName
    $memberMigrationSuccess = $true
    $ownerMigrationSuccess = $true

    # Fetch details of the old group
    $oldGroup = Get-AzureADGroup -SearchString $oldGroupName
    $oldGroupMembers = Get-AzureADGroupMember -ObjectId $oldGroup.ObjectId -All $true
    $oldGroupExchangeDetails = Get-DistributionGroup -Identity $oldGroup.ObjectId

    # Store ownership information in a variable
    $oldGroupOwners = $oldGroupExchangeDetails.ManagedBy

    # Decide on initial owners for the new group
    $initialOwners = if ($oldGroupOwners -eq $null -or $oldGroupOwners.Count -eq 0) {
        $UserCredential.UserName
    } else {
        $oldGroupOwners | Select-Object -Unique
    }

    # Fetch settings of the old group
    $oldPrimarySmtpAddress = $oldGroupExchangeDetails.PrimarySmtpAddress
    $externalSendersAllowed = $oldGroupExchangeDetails.RequireSenderAuthenticationEnabled -eq $false

    # Rename the old group in Exchange Online
    $newOldGroupName = "$oldGroupName-old"
    Set-DistributionGroup -Identity $oldGroup.ObjectId -DisplayName $newOldGroupName

    # Delete the old group to free up the email
    Remove-DistributionGroup -Identity $oldGroup.ObjectId -Confirm:$false

    # Create new mail-enabled security group in Exchange Online
    $newGroup = New-DistributionGroup -Name $newGroupName -Type "Security" -PrimarySmtpAddress $oldPrimarySmtpAddress -ManagedBy $initialOwners

    # Fetch the newly created group to get its ObjectId
    $newGroupExchangeDetails = Get-DistributionGroup -Identity $newGroupName
    $newGroupObjectId = $newGroupExchangeDetails.ExternalDirectoryObjectId

    # Apply settings
    Set-DistributionGroup -Identity $newGroupObjectId -RequireSenderAuthenticationEnabled (-not $externalSendersAllowed)

 # Migrate members
# Temporarily add yourself as an owner
Set-DistributionGroup -Identity $newGroupObjectId -ManagedBy $UserCredential.UserName -BypassSecurityGroupManagerCheck

foreach ($member in $oldGroupMembers) {
    try {
        Add-DistributionGroupMember -Identity $newGroupObjectId -Member $member.ObjectId
    } catch {
        $memberMigrationSuccess = $false
        Write-Host "Failed to add member: $($member.UserPrincipalName)"
    }
}

# Validate old owners and migrate
if ($oldGroupOwners -eq $null -or $oldGroupOwners.Count -eq 0) {
    # New Logic: If no old owners, then set yourself as an owner (This part has changed)
    try {
        Set-DistributionGroup -Identity $newGroupObjectId -ManagedBy $UserCredential.UserName -BypassSecurityGroupManagerCheck
        Write-Host "No old owners found. You have been set as the owner."
        $ownerMigrationSuccess = $true
    } catch {
        $ownerMigrationSuccess = $false
        Write-Host "Failed to set yourself as the owner."
    }
} else {
    try {
        # If old owners are found, set the ManagedBy attribute directly to them.
        Set-DistributionGroup -Identity $newGroupObjectId -ManagedBy $oldGroupOwners -BypassSecurityGroupManagerCheck
        Write-Host "All old owners added successfully."
        $ownerMigrationSuccess = $true
    } catch {
        $ownerMigrationSuccess = $false
        Write-Host "Failed to set ManagedBy attribute for the new distribution group."
    }

   # Remove yourself as an owner if you were not an owner of the old group (This part remains unchanged)
   $wasOldOwner = $oldGroupOwners -contains $UserCredential.UserName
   if (-not $wasOldOwner) {
       $currentOwners = Get-DistributionGroup -Identity $newGroupObjectId | Select-Object -ExpandProperty ManagedBy
       $newOwners = $currentOwners | Where-Object {$_ -ne $UserCredential.UserName}
       Set-DistributionGroup -Identity $newGroupObjectId -ManagedBy $newOwners -BypassSecurityGroupManagerCheck
       Write-Host "You were not an owner in the old group. Removed yourself."
   }
}
    # Sleep for 30 seconds to allow changes to propagate.
    Write-Slowly "Propagating..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45

    # Summary
    if ($memberMigrationSuccess -and $ownerMigrationSuccess) {
        Write-Host "Migration completed successfully."
    } else {
        Write-Host "Migration completed with errors."
    }

    # Ask if user wants to continue
    $continue = Read-Host "Do you want to migrate another group? (Yes/No)"
    if ($continue -eq 'No') {
        break
    }
}

# Disconnect from Exchange Online and Azure AD
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-AzureAD

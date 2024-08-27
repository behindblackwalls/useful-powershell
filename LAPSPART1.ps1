# Name of the local admin account
$adminAccountName = "CHANGEME"

# Check if the account already exists
$adminAccount = Get-LocalUser -Name $adminAccountName -ErrorAction SilentlyContinue

if ($null -eq $adminAccount) {
    # Generate a random password
    $password = New-Object -TypeName System.Security.SecureString
    $rand = New-Object -TypeName System.Random
    1..16 | ForEach-Object { $password.AppendChar([char]$rand.Next(33, 126)) } | Out-Null
    
    # Create the local admin account
    New-LocalUser -Name $adminAccountName -Password $password -UserMayNotChangePassword -PasswordNeverExpires -FullName "CHANGEME" -Description "CHANGEME"

    # Add the new account to the Administrators group
    Add-LocalGroupMember -Group "Administrators" -Member $adminAccountName
    Write-Host "Local admin account '$adminAccountName' has been created with a randomly generated password."
} else {
    Write-Host "Local admin account '$adminAccountName' already exists."
}

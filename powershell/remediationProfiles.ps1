$Profile_age = 60 # max profile age in days

Try {
    # Get all User profile folders older than X days
    $LastAccessedFolder = Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notlike "*Windows*" -and $_.Name -notlike "*default*" -and $_.Name -notlike "*Public*" -and $_.Name -notlike "*Admin*" -and $_.LastWriteTime -lt (Get-Date).AddDays(-$Profile_age) }

    # Filter the list of folders to only include those that are not associated with local user accounts
    $Profiles_notLocal = $LastAccessedFolder | Where-Object { $_.Name -notin (Get-LocalUser).Name }

    # Retrieve a list of user profiles and filter to only include the old ones
    $Profiles_2remove = Get-CimInstance -Class Win32_UserProfile | Where-Object { $_.LocalPath -in $Profiles_notLocal.FullName }

    if ($Profiles_2remove) {
        # Removing all old profiles
        $Profiles_2remove | Remove-CimInstance
        Write-Output "Old profiles removed."
        exit 0
    } else {
        Write-Output "No profiles older than $Profile_age days found."
        exit 0
    }
} 
Catch {
    Write-Error $_
    exit 1
}


# One-Liner if you need it for removing individual profiles
# $username = Read-Host "Enter username"; Get-CimInstance -Class Win32_UserProfile | Where-Object { $_.LocalPath -eq "C:\Users\$username" } | Remove-CimInstance
# When deploying, run the script in a 64 bit powershell host or else it won't work.
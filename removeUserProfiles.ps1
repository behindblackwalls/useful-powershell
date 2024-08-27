Function ProfileLastUsed {
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,Position=0)]
        [string]$ProfileFolder
    )

    $TestFiles = @(
        "AppData\Local\Microsoft\Windows\WebCache\V01.chk",
        "AppData\Local\Microsoft\Windows\INetCache\*",
        "AppData\Local\Microsoft\Windows\Notifications\wpndatabase.db",
        "AppData\Roaming\Microsoft\Windows\Recent\*",
        "AppData\Local\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\Settings\settings.dat"
    )

    $LatestWriteTime = Get-Date -Year 1900 # Initialize with a very old date

    foreach ($TestFile in $TestFiles) {
        $FullPath = Join-Path -Path $ProfileFolder -ChildPath $TestFile
        $Files = Get-ChildItem -Path $FullPath -File -ErrorAction SilentlyContinue -Recurse
        foreach ($File in $Files) {
            if ($File.LastWriteTime -gt $LatestWriteTime) {
                $LatestWriteTime = $File.LastWriteTime
            }
        }
    }

    If ($LatestWriteTime -eq (Get-Date -Year 1900)) {
        $LatestWriteTime = $null
    }

    return $LatestWriteTime
}

$Profile_age = 60 # max profile age in days

Try {
    # Get all User profile folders excluding system profiles
    $UserFolders = Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notlike "*Windows*" -and $_.Name -notlike "*default*" -and $_.Name -notlike "*eledeli*" -and $_.Name -notlike "*wsadmin*" -and $_.Name -notlike "*Public*" -and $_.Name -notlike "*Administrator* " }
    Write-Output "Found $(($UserFolders).Count) user folders for evaluation."

    foreach ($Folder in $UserFolders) {
        $lastUsedDate = ProfileLastUsed -ProfileFolder $Folder.FullName
        if ($lastUsedDate -and ($lastUsedDate -lt (Get-Date).AddDays(-$Profile_age))) {
            Write-Output "Attempting to remove profile `$($Folder.Name)` last used on $lastUsedDate."
            $Profile = Get-CimInstance -Class Win32_UserProfile | Where-Object { $_.LocalPath -eq $Folder.FullName }
            if ($Profile) {
                Try {
                    $Profile | Remove-CimInstance
                    Write-Output "Successfully removed profile at $($Folder.FullName)."
                } Catch {
                    Write-Warning "Failed to remove profile at $($Folder.FullName): $_"
                }
            }
        } else {
            Write-Output "Profile `$($Folder.Name)` last used on $lastUsedDate and will NOT be removed."
        }
    }
} Catch {
    Write-Warning "An error occurred: $_"
}

Write-Output "Script execution completed. Check the output for profiles removed."

function Uninstall-TeamsClassic($TeamsPath) {
    try {
        $process = Start-Process -FilePath "$TeamsPath\Update.exe" -ArgumentList "--uninstall /s" -PassThru -Wait -ErrorAction STOP

        if ($process.ExitCode -ne 0) {
            Write-Error "Uninstallation failed with exit code $($process.ExitCode)."
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

# Remove Teams Machine-Wide Installer
Write-Host "Removing Teams Machine-wide Installer"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$MachineWide = Get-ItemProperty -Path $registryPath\* | Where-Object -Property DisplayName -eq "Teams Machine-Wide Installer"

if ($MachineWide) {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x ""$($MachineWide.PSChildName)"" /qn" -NoNewWindow -Wait
}
else {
    Write-Host "Teams Machine-Wide Installer not found"
}

# Get all Users
$AllUsers = Get-ChildItem -Path "$($ENV:SystemDrive)\Users"

# Process all Users
foreach ($User in $AllUsers) {
    Write-Host "Processing user: $($User.Name)"

    # Load user hive
    $userHivePath = "$($User.FullName)\NTUSER.DAT"
    if (Test-Path $userHivePath) {
        try {
            $loadHiveCmd = "reg load HKU\$($User.Name) `"$userHivePath`""
            Write-Host "Executing: $loadHiveCmd"
            Invoke-Expression $loadHiveCmd
            Write-Host "  Loaded hive for user $($User.Name)"

            # Query registry key using reg.exe
            $teamsKeyPath = "HKU\$($User.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
            $queryCmd = "reg query $teamsKeyPath"
            Write-Host "Executing: $queryCmd"
            $queryResult = Invoke-Expression $queryCmd

            if ($queryResult -match "Teams") {
                Write-Host "Found registry key: $teamsKeyPath"
                # Removing registry key using reg.exe
                $removeCmd = "reg delete $teamsKeyPath /f"
                Write-Host "Executing: $removeCmd"
                Invoke-Expression $removeCmd
                Write-Host "  Removed Teams registry key for user $($User.Name)"
            } else {
                Write-Host "  Teams registry key not found for user $($User.Name)"
            }

            # Unload user hive
            $unloadHiveCmd = "reg unload HKU\$($User.Name)"
            Write-Host "Executing: $unloadHiveCmd"
            Invoke-Expression $unloadHiveCmd
            Write-Host "  Unloaded hive for user $($User.Name)"
        }
        catch {
            Write-Error "  Failed to load/unload hive for user $($User.Name): $_"
        }
    }
    else {
        Write-Host "  NTUSER.DAT not found for user $($User.Name)"
    }

    # Locate installation folder
    $localAppData = "$($ENV:SystemDrive)\Users\$($User.Name)\AppData\Local\Microsoft\Teams"
    $programData = "$($env:ProgramData)\$($User.Name)\Microsoft\Teams"

    if (Test-Path "$localAppData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $localAppData
    }
    elseif (Test-Path "$programData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $programData
    }
    else {
        Write-Host "  Teams installation not found for user $($User.Name)"
    }
}

# Remove old Teams folders and icons
$TeamsFolder_old = "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\Teams"
$TeamsIcon_old = "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams*.lnk"
Get-Item $TeamsFolder_old -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-Item $TeamsIcon_old -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

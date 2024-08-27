$packageName = "DellInc.DellSupportAssistforPCs"
$installLocation = "C:\Program Files\WindowsApps\DellInc.DellSupportAssistforPCs_3.5.13.0_x64__htrsf667h5kn2"
$uninstallKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

Try {
    # Attempt to get and uninstall Dell Command Update package
    $package = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $packageName }

    if ($package) {
        Remove-AppxPackage -AllUsers -Package $package.PackageFullName
        Write-Host "Dell Command Update has been uninstalled."
    } else {
        Write-Host "Dell Command Update package is not installed."
    }

    # Search for and remove the uninstall registry keys
    $uninstallKeys = Get-ChildItem $uninstallKeyPath -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.InstallLocation -eq $installLocation }

    if ($uninstallKeys) {
        foreach ($key in $uninstallKeys) {
            $keyPath = "$uninstallKeyPath\$($key.PSChildName)"
            Remove-Item $keyPath -Force
            Write-Host "Removed registry key at '$keyPath' with InstallLocation '$installLocation'."
        }
    } else {
        Write-Host "No registry key with InstallLocation '$installLocation' for Dell Command Update found."
    }
}
Catch {
    Write-Error "Error encountered: $_"
}

# PowerShell script to set the DisableDomainCreds registry value

# Define the path and value
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$valueName = "DisableDomainCreds"
$newValue = 1

# Check if the registry path exists
if (-not (Test-Path $path)) {
    Write-Host "Registry path does not exist: $path"
    exit
}

# Set the registry value
Set-ItemProperty -Path $path -Name $valueName -Value $newValue -Type DWORD

# Confirm the change
if ((Get-ItemProperty -Path $path).$valueName -eq $newValue) {
    Write-Host "Registry value $valueName set to $newValue successfully."
} else {
    Write-Host "Failed to set the registry value $valueName."
}

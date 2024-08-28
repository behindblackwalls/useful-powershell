$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$propertyName = "LmCompatibilityLevel"
$newPropertyValue = 5 # Send NTLMv2 response only. Refuse LM and NTLM

# Check if the registry path exists
if (-not (Test-Path $registryPath)) {
    # If the registry path does not exist, create it
    New-Item -Path $registryPath -Force
    Set-ItemProperty -Path $registryPath -Name $propertyName -Value $newPropertyValue
    Write-Output "Registry path and value created: $propertyName = $newPropertyValue"
} else {
    # If the registry path exists, set the property value
    Set-ItemProperty -Path $registryPath -Name $propertyName -Value $newPropertyValue
    Write-Output "Registry value set: $propertyName = $newPropertyValue"
}

# Additional message
Write-Output "Find me!:!:@:@"
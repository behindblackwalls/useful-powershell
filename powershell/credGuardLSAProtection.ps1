# Define the registry paths and properties
$regPathsAndValues = @(
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Name = "EnableVirtualizationBasedSecurity"; Value = 1 },
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; Name = "RequirePlatformSecurityFeatures"; Value = 3 },
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name = "LsaCfgFlags"; Value = 2 },
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name = "RunAsPPL"; Value = 1 }
)

foreach ($item in $regPathsAndValues) {
    # Check if the registry key exists
    if (Test-Path $item.Path) {
        # Get the current value of the property
        $currentValue = Get-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction SilentlyContinue

        if ($currentValue -ne $null) {
            # Check if the value is already set to the desired value
            if ($currentValue.$($item.Name) -ne $item.Value) {
                # Set the value to the desired value
                Set-ItemProperty -Path $item.Path -Name $item.Name -Value $item.Value
                Write-Output "$($item.Name) was not $($item.Value). It has been set to $($item.Value)."
            } else {
                Write-Output "$($item.Name) is already set to $($item.Value)."
            }
        } else {
            Write-Output "$($item.Name) does not exist at the specified path."
        }
    } else {
        Write-Output "The specified registry path $($item.Path) does not exist."
    }
}

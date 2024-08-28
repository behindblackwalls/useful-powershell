Connect-AzureAD 

# Function to simulate text being typed out
function Write-Slowly {
    param(
        [string]$Text,
        [int]$Delay = 2,
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::Green
    )

    $Text.ToCharArray() | ForEach-Object {
        Write-Host -NoNewline $_ -ForegroundColor $ForegroundColor
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

function Audit-StaleDevices {

    # Display the prompt slowly
    Write-Slowly "Enter the number of days of inactivity to consider a device as stale"

    # Prompt for the number of days of inactivity and store the input
    $inactiveDays = Read-Host "Please enter the number now"

    # Get all devices
    $allDevices = Get-AzureADDevice -All $true

    # Initialize an array to hold stale devices
    $staleDevices = @()

    # Get the current date
    $currentDate = Get-Date

    # Loop through the devices
    foreach ($device in $allDevices) {
        # Get the last activity date
        $lastActivity = $device.ApproximateLastLogonTimestamp

        # If last activity date is not null, calculate the days of inactivity
        if ($lastActivity -ne $null) {
            $daysInactive = ($currentDate - $lastActivity).Days

            # Check if the device has been inactive for more than the specified days
            if ($daysInactive -gt $inactiveDays) {
                $staleDevices += $device
            }
        }
    }

    # Sort by DisplayName and output the stale devices
    Write-Host "Stale Devices:"
    $staleDevices | Sort-Object DisplayName -Descending | Select-Object ObjectId, DisplayName, ApproximateLastLogonTimestamp | Format-Table

    # Output the total count of stale devices
    Write-Host ("Total number of stale devices: " + $staleDevices.Count)

    # Ask if you want to proceed with deletion
    $response = Read-Host "Do you want to delete these stale devices? (y/n)"

    if ($response -eq 'y') {
        foreach ($device in $staleDevices) {
            # Show similar devices
            $similarDevices = Get-AzureADDevice -Filter "startswith(DisplayName, '$($device.DisplayName)')"
            Write-Host "Similar Devices:"
            $similarDevices | Select-Object ObjectId, DisplayName, ApproximateLastLogonTimestamp | Format-Table

            $secondResponse = Read-Host ("Do you really want to delete " + $device.DisplayName + " with ObjectId " + $device.ObjectId + "? (y/n)")
            
            if ($secondResponse -eq 'y') {
                Write-Host ("Deleting device: " + $device.DisplayName)
                Remove-AzureADDevice -ObjectId $device.ObjectId
            } else {
                Write-Host ("Skipped deletion of: " + $device.DisplayName)
            }
        }
        Write-Host "Deletion complete."
    } else {
        Write-Host "Deletion cancelled."
    }


}

Audit-StaleDevices
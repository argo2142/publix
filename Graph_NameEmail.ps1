<#
.SYNOPSIS
    This script retrieves primary user information for a list of devices from a text file.

.DESCRIPTION
    This script reads a list of device names, one per line, from a text file.
    It then uses the Microsoft Graph PowerShell SDK to query Intune for each device's
    primary user and exports the results to a CSV file.

.NOTES
    Make sure you have connected to Microsoft Graph using Connect-MgGraph
    with the necessary permissions (e.g., DeviceManagementManagedDevices.Read.All).
#>

# Step 1: Define file paths
$inputTxtPath = "C:\temp\device_list2.txt"
$outputCsvPath = "C:\temp\IntuneDevicePrimaryUsers.csv"

# Step 2: Check for input file and read device names
if (-not (Test-Path $inputTxtPath)) {
    Write-Host "Error: Input text file not found at '$inputTxtPath'. Please create a text file with one device name per line." -ForegroundColor Red
    return
}

$deviceNames = Get-Content -Path $inputTxtPath | Where-Object { -not [string]::IsNullOrEmpty($_.Trim()) }

# Step 3: Initialize output array
$results = @()

# Step 4: Process each device
Write-Host "Processing $($deviceNames.Count) devices..." -ForegroundColor Yellow
foreach ($deviceName in $deviceNames) {
    # Initialize variables for each device
    $userDisplayName = "Not Found"
    $userEmail = "Not Found"
    $statusMessage = "Device '$deviceName' not found in Intune."
    $foregroundColor = "Red"

    # Use a try/catch block for robust error handling
    try {
        # Query for the device in Intune
        $intuneDevice = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$($deviceName.Trim())'" -All | Select-Object -First 1
        
        # Check if the device was found and update variables
        if ($intuneDevice) {
            $userDisplayName = $intuneDevice.userDisplayName
            $userEmail = $intuneDevice.userPrincipalName
            $statusMessage = "Found user for '$($deviceName)': $($userDisplayName) ($($userEmail))"
            $foregroundColor = "Green"
        }
    } catch {
        # Catch any API or other errors and update variables
        $errorMessage = $_.Exception.Message
        $userDisplayName = "Error"
        $userEmail = "Error: $($errorMessage)"
        $statusMessage = "An error occurred for '$($deviceName)': $($errorMessage)"
        $foregroundColor = "Red"
    }

    # Create and add a custom object to the results array
    $deviceObject = [PSCustomObject]@{
        DeviceName = $deviceName
        PrimaryUserDisplayName = $userDisplayName
        PrimaryUserEmail = $userEmail
    }
    $results += $deviceObject
    Write-Host $statusMessage -ForegroundColor $foregroundColor
}

# Step 5: Export results to a new CSV file
$results | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Host "Processing complete. Results saved to '$outputCsvPath'." -ForegroundColor Green

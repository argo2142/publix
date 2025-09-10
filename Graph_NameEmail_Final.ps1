# Configuration
$tenantId = "" # App Overview Page "Directory (tenant) ID"
$clientId = "" # App Overview Page "Application (client) ID"
$clientSecret = ""
$inputTxtPath = "C:\temp\device_list.txt"
$outputCsvPath = "C:\temp\IntuneDevicePrimaryUsers.csv"
# Permission Required: DeviceManagementManagedDevices.Read.All

try {
    # Authenticate
    $secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($clientId, $secureSecret)
    Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential

    # Read devices and get all Intune devices
    $deviceNames = Get-Content $inputTxtPath | Where-Object { $_.Trim() }
    $allDevices = Get-MgDeviceManagementManagedDevice -All -Property "deviceName,userDisplayName,userPrincipalName"
    $deviceLookup = @{}; $allDevices | ForEach-Object { if ($_.DeviceName) { $deviceLookup[$_.DeviceName.ToLower()] = $_ } }

    # Process and export
    $results = @(); $found = 0
    foreach ($name in $deviceNames) {
        $device = $deviceLookup[$name.ToLower()]
        if ($device) { $found++ }
        $results += [PSCustomObject]@{
            DeviceName = $name
            PrimaryUserDisplayName = if ($device) { if ($device.userDisplayName) { $device.userDisplayName } else { "No Primary User" } } else { "Not Found" }
            PrimaryUserEmail = if ($device) { if ($device.userPrincipalName) { $device.userPrincipalName } else { "No Email" } } else { "Not Found" }
        }
    }
    
    $results | Export-Csv -Path $outputCsvPath -NoTypeInformation
    Write-Host "Complete: $found/$($deviceNames.Count) found -> $outputCsvPath" -ForegroundColor Green
}
catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }

finally { Disconnect-MgGraph -ErrorAction SilentlyContinue }

# Microsoft Graph API Batch Request to find device users from a text file

# --- Prerequisite Setup ---
# Before running:
# Install-Module Microsoft.Graph.DeviceManagement, Microsoft.Graph -Scope CurrentUser
# Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "User.Read.All"

# --- Configuration ---
# Set the path to your text file, with one device name per line.
$filePath = "C:\temp\device_list.txt"

# Set the path for the output CSV file.
$outputPath = "C:\temp\IntuneDeviceUsers.csv"

# --- Main Script ---
try {
    $deviceNames = Get-Content -Path $filePath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    # Process devices in batches of 20.
    $results = @()
    $batchSize = 20
    $batches = [Math]::Ceiling($deviceNames.Count / $batchSize)

    for ($i = 0; $i -lt $deviceNames.Count; $i += $batchSize) {
        Write-Host "Processing batch $(($i / $batchSize) + 1) of $batches..."
        $batch = $deviceNames[$i..([Math]::Min($i + $batchSize - 1, $deviceNames.Count - 1))]

        $requests = @()
        for ($j = 0; $j -lt $batch.Count; $j++) {
            $requests += @{
                id = ($j + 1).ToString()
                method = "GET"
                url = "/deviceManagement/managedDevices?`$filter=deviceName eq '$($batch[$j])'&`$select=id,deviceName,userDisplayName,emailAddress"
            }
        }

        $batchResponse = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/`$batch" -Body @{ requests = $requests }

        foreach ($response in $batchResponse.responses) {
            if ($response.status -eq 200 -and $response.body.value.Count -gt 0) {
                $results += $response.body.value | Select-Object @{N='DeviceName';E={$_.deviceName}}, @{N='UserDisplayName';E={$_.userDisplayName}}, @{N='UserEmail';E={$_.emailAddress}}
            }
        }
        Start-Sleep -Milliseconds 200
    }

    # Export results and show a summary.
    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $outputPath -NoTypeInformation
        Write-Host "Success! Found user data for $($results.Count) devices. Results saved to '$outputPath'."
        $results | Format-Table -AutoSize
    } else {
        Write-Warning "No user data found for the devices in the list."
    }

} catch {
    Write-Error "An error occurred: $_"
}
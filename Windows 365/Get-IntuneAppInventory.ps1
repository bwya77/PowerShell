<#
.SYNOPSIS
    Retrieves all detected apps from Microsoft Intune (Graph beta) and the devices each app is installed on.

.DESCRIPTION
    Authenticates to Microsoft Graph using an app registration (client credentials flow),
    pulls every record from /deviceManagement/detectedApps (handling pagination), then for
    each app queries /deviceManagement/detectedApps('{id}')/managedDevices (also paginated)
    to build a flattened App <-> Device inventory.

    Output can be written to the console as a table, exported to CSV, or both.

.PARAMETER TenantId
    Azure AD tenant ID (GUID) or verified domain name.

.PARAMETER ClientId
    App registration (application) client ID. Must have DeviceManagementManagedDevices.Read.All
    (and DeviceManagementApps.Read.All if required) application permissions, admin consented.

.PARAMETER ClientSecret
    App registration client secret. Pass as a SecureString where possible.

.PARAMETER OutputPath
    Optional path to a .csv file. When provided, results are exported to CSV.

.PARAMETER AsTable
    When set (or when -OutputPath is omitted), prints a formatted table to the console.

.PARAMETER AppSummaryOnly
    Only return one row per app (displayName, version, publisher, platform, deviceCount) —
    skips the per-app device lookup entirely. Fast path for just listing apps.

.PARAMETER UseBatch
    Use Microsoft Graph's $batch endpoint to look up devices for up to 20 apps per HTTP call
    instead of one call per app. Much faster on large app inventories and generally throttles
    less than the sequential path, though Intune's own per-app rate limit still applies underneath.

.EXAMPLE
    .\Get-IntuneAppInventory.ps1 -TenantId "contoso.onmicrosoft.com" -ClientId "xxxx" -ClientSecret "yyyy" -OutputPath "C:\Temp\AppInventory.csv"

.EXAMPLE
    .\Get-IntuneAppInventory.ps1 -TenantId $tenantId -ClientId $clientId -ClientSecret $secret -AsTable

.EXAMPLE
    .\Get-IntuneAppInventory.ps1 -TenantId $tenantId -ClientId $clientId -ClientSecret $secret -AppSummaryOnly -AsTable

.EXAMPLE
    .\Get-IntuneAppInventory.ps1 -TenantId $tenantId -ClientId $clientId -ClientSecret $secret -UseBatch -OutputPath "C:\Temp\AppInventory.csv"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$ClientSecret,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$AsTable,

    [Parameter(Mandatory = $false)]
    [switch]$AppSummaryOnly,

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = "https://graph.microsoft.com/beta",

    [Parameter(Mandatory = $false)]
    [int]$AppDelayMs = 1000,

    [Parameter(Mandatory = $false)]
    [switch]$UseBatch,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 20)]
    [int]$BatchSize = 20,

    [Parameter(Mandatory = $false)]
    [int]$BatchDelayMs = 500,

    [Parameter(Mandatory = $false)]
    [int]$MaxBatchRounds = 6
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# 1. Authenticate - client credentials flow
# ---------------------------------------------------------------------------
function Get-GraphAccessToken {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret
    )

    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

    Write-Verbose "Requesting access token from $tokenUri"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $tokenUri -Body $body -ContentType "application/x-www-form-urlencoded"
    }
    catch {
        throw "Failed to acquire access token. $($_.Exception.Message)"
    }

    if (-not $response.access_token) {
        throw "Token response did not contain an access_token."
    }

    return $response.access_token
}

# ---------------------------------------------------------------------------
# 2. Generic paged Graph GET with basic 429/5xx retry handling
# ---------------------------------------------------------------------------
function Invoke-GraphGet {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [int]$MaxRetries = 8,
        [int]$BaseBackoffSeconds = 5,
        [int]$MaxBackoffSeconds = 90
    )

    $attempt = 0
    while ($true) {
        $attempt++
        try {
            return Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            $isThrottleOrServerError = ($statusCode -eq 429) -or ($statusCode -ge 500 -and $statusCode -lt 600)

            if ($isThrottleOrServerError -and $attempt -le $MaxRetries) {
                # Honor Retry-After when the service provides it (detectedApps' per-app device
                # lookups frequently throttle WITHOUT a Retry-After header, unlike most Graph
                # endpoints) -- fall back to exponential backoff with jitter so repeated 429s
                # don't all retry at exactly the same fixed interval and re-trip the limit.
                $retryAfter = $null
                if ($_.Exception.Response -and $_.Exception.Response.Headers["Retry-After"]) {
                    $retryAfter = [int]$_.Exception.Response.Headers["Retry-After"]
                }

                if (-not $retryAfter) {
                    $exponential = [Math]::Min($MaxBackoffSeconds, $BaseBackoffSeconds * [Math]::Pow(2, $attempt - 1))
                    $jitter = Get-Random -Minimum 0 -Maximum ([Math]::Max(1, [int]($exponential * 0.25)))
                    $retryAfter = [int]$exponential + $jitter
                }

                Write-Warning "Graph request throttled/failed (status $statusCode). Retry $attempt/$MaxRetries after $retryAfter sec..."
                Start-Sleep -Seconds $retryAfter
                continue
            }

            throw
        }
    }
}

function Get-AllGraphPages {
    param(
        [Parameter(Mandatory = $true)][string]$InitialUri,
        [Parameter(Mandatory = $true)][hashtable]$Headers
    )

    $allItems = [System.Collections.Generic.List[object]]::new()
    $nextUri = $InitialUri

    while ($nextUri) {
        $page = Invoke-GraphGet -Uri $nextUri -Headers $Headers
        if ($page.value) {
            $allItems.AddRange([object[]]$page.value)
        }
        $nextUri = $page.'@odata.nextLink'
    }

    return $allItems
}

# ---------------------------------------------------------------------------
# 2b. $batch support - fan multiple GETs into one HTTP call (Graph allows up
#     to 20 sub-requests per batch). Each sub-request's url is relative to
#     $BaseUrl (no need to repeat the https://graph.microsoft.com/beta prefix).
#     A sub-request can come back 429 even when the outer POST succeeds (the
#     batch envelope's own 200 just means "batch was processed", not that
#     every item inside it succeeded) -- those are retried as a smaller batch
#     on the next round rather than failing the whole chunk.
# ---------------------------------------------------------------------------
function Invoke-GraphBatch {
    param(
        [Parameter(Mandatory = $true)][array]$Requests,  # array of @{ id = <string>; url = <string> }
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [int]$MaxRetries = 8,
        [int]$BaseBackoffSeconds = 5,
        [int]$MaxBackoffSeconds = 90
    )

    $batchBody = @{
        requests = $Requests | ForEach-Object {
            @{ id = $_.id; method = "GET"; url = $_.url }
        }
    } | ConvertTo-Json -Depth 10

    $attempt = 0
    while ($true) {
        $attempt++
        try {
            return Invoke-RestMethod -Method Post -Uri "$BaseUrl/`$batch" -Headers $Headers -Body $batchBody -ContentType "application/json"
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            $isThrottleOrServerError = ($statusCode -eq 429) -or ($statusCode -ge 500 -and $statusCode -lt 600)
            if ($isThrottleOrServerError -and $attempt -le $MaxRetries) {
                $retryAfter = $null
                if ($_.Exception.Response -and $_.Exception.Response.Headers["Retry-After"]) {
                    $retryAfter = [int]$_.Exception.Response.Headers["Retry-After"]
                }
                if (-not $retryAfter) {
                    $exponential = [Math]::Min($MaxBackoffSeconds, $BaseBackoffSeconds * [Math]::Pow(2, $attempt - 1))
                    $jitter = Get-Random -Minimum 0 -Maximum ([Math]::Max(1, [int]($exponential * 0.25)))
                    $retryAfter = [int]$exponential + $jitter
                }
                Write-Warning "Batch POST throttled/failed (status $statusCode). Retry $attempt/$MaxRetries after $retryAfter sec..."
                Start-Sleep -Seconds $retryAfter
                continue
            }

            throw
        }
    }
}

<#
.SYNOPSIS
    Resolves managedDevices for many detectedApps ids using $batch, chunked at $BatchSize per
    call, with per-item 429 retry across rounds and @odata.nextLink continuation for any app
    that has more devices than fit in a single page.
#>
function Get-DetectedAppDevicesBatched {
    param(
        [Parameter(Mandatory = $true)][array]$AppIds,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [int]$BatchSize = 20,
        [int]$BatchDelayMs = 500,
        [int]$MaxRounds = 6
    )

    # appId -> List[object] accumulated device records
    $deviceMap = @{}
    foreach ($id in $AppIds) { $deviceMap[$id] = [System.Collections.Generic.List[object]]::new() }

    # Work items still needing a GET: each is @{ appId = <id>; url = <relative url for this page> }
    $pending = [System.Collections.Generic.List[object]]::new()
    foreach ($id in $AppIds) {
        $encodedId = [System.Uri]::EscapeDataString($id)
        $pending.Add(@{ appId = $id; url = "/deviceManagement/detectedApps('$encodedId')/managedDevices?`$top=100&`$orderby=deviceName%20asc" })
    }

    $round = 0
    while ($pending.Count -gt 0 -and $round -lt $MaxRounds) {
        $round++
        $retryQueue = [System.Collections.Generic.List[object]]::new()
        $chunks = [System.Collections.Generic.List[object[]]]::new()
        for ($i = 0; $i -lt $pending.Count; $i += $BatchSize) {
            $end = [Math]::Min($i + $BatchSize, $pending.Count) - 1
            $chunks.Add($pending.GetRange($i, $end - $i + 1).ToArray())
        }

        $chunkIndex = 0
        foreach ($chunk in $chunks) {
            $chunkIndex++
            if ($chunkIndex -gt 1 -and $BatchDelayMs -gt 0) {
                Start-Sleep -Milliseconds $BatchDelayMs
            }

            $requests = @()
            for ($i = 0; $i -lt $chunk.Count; $i++) {
                $requests += @{ id = "$i"; url = $chunk[$i].url }
            }

            try {
                $batchResult = Invoke-GraphBatch -Requests $requests -Headers $Headers
            }
            catch {
                Write-Warning "Batch call failed outright after retries: $($_.Exception.Message). Re-queuing $($chunk.Count) item(s) for next round."
                $retryQueue.AddRange([object[]]$chunk)
                continue
            }

            foreach ($response in $batchResult.responses) {
                $item = $chunk[[int]$response.id]
                if ($response.status -eq 200) {
                    if ($response.body.value) {
                        $deviceMap[$item.appId].AddRange([object[]]$response.body.value)
                    }
                    $nextLink = $response.body.'@odata.nextLink'
                    if ($nextLink) {
                        # nextLink comes back as a full absolute URL; batch sub-request urls must
                        # be relative to $BaseUrl, so strip the common prefix back off.
                        $relative = $nextLink -replace [regex]::Escape($BaseUrl), ''
                        $retryQueue.Add(@{ appId = $item.appId; url = $relative })
                    }
                }
                elseif ($response.status -eq 429 -or $response.status -ge 500) {
                    $retryQueue.Add($item)
                }
                else {
                    Write-Warning "Device lookup failed for app '$($item.appId)' (status $($response.status)): $($response.body.error.message)"
                }
            }
        }

        $pending = $retryQueue
        if ($pending.Count -gt 0 -and $round -lt $MaxRounds) {
            $backoff = [Math]::Min(60, 5 * [Math]::Pow(2, $round - 1))
            Write-Warning "$($pending.Count) device lookup(s) still throttled/pending after round $round. Waiting $backoff sec before retrying..."
            Start-Sleep -Seconds $backoff
        }
    }

    if ($pending.Count -gt 0) {
        Write-Warning "$($pending.Count) device lookup(s) could not be completed after $MaxRounds rounds and were skipped."
    }

    return $deviceMap
}

<#
.SYNOPSIS
    Appends one result row per device for an app, or a single device-less row if there are none.
    Shared by both the sequential (-UseBatch off) and batched (-UseBatch on) code paths so the
    output shape is identical either way.
#>
function Add-AppResultRows {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$ResultsList,
        [Parameter(Mandatory = $true)]$App,
        [array]$Devices = @()
    )

    if (-not $Devices -or $Devices.Count -eq 0) {
        $ResultsList.Add([PSCustomObject]@{
            AppDisplayName    = $App.displayName
            AppVersion        = $App.version
            Publisher         = $App.publisher
            Platform          = $App.platform
            DeviceCount       = $App.deviceCount
            DeviceName        = $null
            UserPrincipalName = $null
            EmailAddress      = $null
            OperatingSystem   = $null
            OSVersion         = $null
            ComplianceState   = $null
            SerialNumber      = $null
            LastSyncDateTime  = $null
            AppId             = $App.id
            DeviceId          = $null
        })
        return
    }

    foreach ($device in $Devices) {
        $ResultsList.Add([PSCustomObject]@{
            AppDisplayName    = $App.displayName
            AppVersion        = $App.version
            Publisher         = $App.publisher
            Platform          = $App.platform
            DeviceCount       = $App.deviceCount
            DeviceName        = $device.deviceName
            UserPrincipalName = $device.userPrincipalName
            EmailAddress      = $device.emailAddress
            OperatingSystem   = $device.operatingSystem
            OSVersion         = $device.osVersion
            ComplianceState   = $device.complianceState
            SerialNumber      = $device.serialNumber
            LastSyncDateTime  = $device.lastSyncDateTime
            AppId             = $App.id
            DeviceId          = $device.id
        })
    }
}

# ---------------------------------------------------------------------------
# 3. Main
# ---------------------------------------------------------------------------
Write-Host "Authenticating to Microsoft Graph..." -ForegroundColor Cyan
$accessToken = Get-GraphAccessToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret

$headers = @{
    Authorization  = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

Write-Host "Retrieving detected apps from Intune..." -ForegroundColor Cyan
$detectedAppsUri = "$BaseUrl/deviceManagement/detectedApps?`$orderBy=displayName"
$apps = Get-AllGraphPages -InitialUri $detectedAppsUri -Headers $headers

Write-Host "Found $($apps.Count) detected apps." -ForegroundColor Green

$results = [System.Collections.Generic.List[object]]::new()

if ($AppSummaryOnly) {
    foreach ($app in $apps) {
        $results.Add([PSCustomObject]@{
            AppDisplayName = $app.displayName
            AppVersion     = $app.version
            Publisher      = $app.publisher
            Platform       = $app.platform
            SizeInBytes    = $app.sizeInByte
            DeviceCount    = $app.deviceCount
            AppId          = $app.id
        })
    }
}
else {
    if ($UseBatch) {
        Write-Host "Retrieving devices for apps using Graph `$batch (batch size $BatchSize)..." -ForegroundColor Cyan
        $appsWithDevices = @($apps | Where-Object { $_.deviceCount -gt 0 })
        $deviceMap = @{}
        if ($appsWithDevices.Count -gt 0) {
            $deviceMap = Get-DetectedAppDevicesBatched -AppIds ($appsWithDevices | ForEach-Object { $_.id }) -Headers $headers -BatchSize $BatchSize -BatchDelayMs $BatchDelayMs -MaxRounds $MaxBatchRounds
        }

        foreach ($app in $apps) {
            $devices = if ($deviceMap.ContainsKey($app.id)) { $deviceMap[$app.id] } else { @() }
            Add-AppResultRows -ResultsList $results -App $app -Devices $devices
        }
    }
    else {
        $appIndex = 0
        foreach ($app in $apps) {
            $appIndex++
            Write-Progress -Activity "Mapping apps to devices" -Status "$appIndex of $($apps.Count): $($app.displayName)" `
                -PercentComplete (($appIndex / [math]::Max($apps.Count,1)) * 100)

            if ($app.deviceCount -eq 0) {
                # No devices to enumerate - still emit one row for the app so it's not lost from the report.
                Add-AppResultRows -ResultsList $results -App $app -Devices @()
                continue
            }

            # Pace requests to the detectedApps managedDevices sub-endpoint -- it throttles with 429s
            # much more aggressively than most Graph endpoints, and frequently omits the Retry-After
            # header, so proactively spacing calls out (rather than relying on retry-after-the-fact)
            # avoids tripping the limit on larger app inventories. Skipped on the very first call.
            if ($appIndex -gt 1 -and $AppDelayMs -gt 0) {
                Start-Sleep -Milliseconds $AppDelayMs
            }

            $encodedId = [System.Uri]::EscapeDataString($app.id)
            $devicesUri = "$BaseUrl/deviceManagement/detectedApps('$encodedId')/managedDevices?`$top=100&`$orderby=deviceName%20asc"

            try {
                $devices = Get-AllGraphPages -InitialUri $devicesUri -Headers $headers
            }
            catch {
                Write-Warning "Failed to retrieve devices for app '$($app.displayName)' ($($app.id)): $($_.Exception.Message)"
                $devices = @()
            }

            Add-AppResultRows -ResultsList $results -App $app -Devices $devices
        }
        Write-Progress -Activity "Mapping apps to devices" -Completed
    }
}

# ---------------------------------------------------------------------------
# 4. Output
# ---------------------------------------------------------------------------
if ($OutputPath) {
    $directory = Split-Path -Path $OutputPath -Parent
    if ($directory -and -not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported $($results.Count) rows to $OutputPath" -ForegroundColor Green
}

if ($AsTable -or -not $OutputPath) {
    $results | Format-Table -AutoSize
}

return $results

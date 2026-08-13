param(
    [string]$PortName = "COM2",
    [int]$BaudRate = 2400,
    [string]$ListenPrefix = "http://127.0.0.1:8765/"
)

$ErrorActionPreference = "Stop"
$logPath = Join-Path $env:LOCALAPPDATA "RomesonOdooBridge\bridge.log"
$logDir = Split-Path $logPath -Parent
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-Log([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line -Encoding UTF8
}

function Send-Json($Context, [int]$StatusCode, [hashtable]$Body) {
    $json = $Body | ConvertTo-Json -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = "application/json; charset=utf-8"
    $Context.Response.Headers["Access-Control-Allow-Origin"] = "*"
    $Context.Response.Headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    $Context.Response.Headers["Access-Control-Allow-Headers"] = "Content-Type"
    $Context.Response.ContentLength64 = $bytes.Length
    $Context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Context.Response.OutputStream.Close()
}

function Format-LED8Value([string]$RawValue) {
    $clean = $RawValue -replace '[^0-9.]', ''
    if ([string]::IsNullOrWhiteSpace($clean)) { return "" }

    $number = 0.0
    if (-not [double]::TryParse(
        $clean,
        [Globalization.NumberStyles]::AllowDecimalPoint,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$number
    )) { return "" }

    if ($number -ge 1000000) {
        $formatted = [math]::Round($number).ToString("0", [Globalization.CultureInfo]::InvariantCulture)
    } else {
        $formatted = $number.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture)
    }

    if ($formatted.Length -gt 8) {
        $formatted = [math]::Round($number).ToString("0", [Globalization.CultureInfo]::InvariantCulture)
    }
    if ($formatted.Length -gt 8) {
        $formatted = $formatted.Substring($formatted.Length - 8)
    }
    return $formatted
}

function Write-Display([string]$Value) {
    $formatted = Format-LED8Value $Value
    $prefix = [byte[]](27, 64, 12, 27, 115, 50)
    $payload = if ($formatted) {
        [byte[]]($prefix + [Text.Encoding]::ASCII.GetBytes($formatted))
    } else {
        [byte[]](27, 64, 12)
    }
    $script:serial.Write($payload, 0, $payload.Length)
    Write-Log "Display updated: '$formatted'"
    return $formatted
}

$mutex = New-Object Threading.Mutex($false, "Local\RomesonOdooLED8Bridge")
if (-not $mutex.WaitOne(0, $false)) { exit 0 }

$serial = $null
$listener = $null
try {
    $serial = New-Object System.IO.Ports.SerialPort $PortName, $BaudRate, 'None', 8, 'One'
    $serial.Handshake = 'None'
    $serial.DtrEnable = $true
    $serial.RtsEnable = $true
    $serial.Open()

    $listener = New-Object Net.HttpListener
    $listener.Prefixes.Add($ListenPrefix)
    $listener.Start()
    Write-Log "Bridge started on $ListenPrefix using $PortName at $BaudRate baud"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            if ($context.Request.HttpMethod -eq "OPTIONS") {
                Send-Json $context 204 @{ ok = $true }
                continue
            }

            switch ($context.Request.Url.AbsolutePath) {
                "/health" {
                    Send-Json $context 200 @{
                        ok = $true
                        port = $PortName
                        baud = $BaudRate
                        open = $serial.IsOpen
                    }
                }
                "/display" {
                    $value = $context.Request.QueryString["value"]
                    $shown = Write-Display $value
                    Send-Json $context 200 @{ ok = $true; displayed = $shown }
                }
                "/clear" {
                    [void](Write-Display "")
                    Send-Json $context 200 @{ ok = $true }
                }
                default {
                    Send-Json $context 404 @{ ok = $false; error = "Not found" }
                }
            }
        } catch {
            Write-Log "Request error: $($_.Exception.Message)"
            try { Send-Json $context 500 @{ ok = $false; error = $_.Exception.Message } } catch {}
        }
    }
} catch {
    Write-Log "Fatal error: $($_.Exception.Message)"
    throw
} finally {
    if ($listener) { try { $listener.Stop(); $listener.Close() } catch {} }
    if ($serial -and $serial.IsOpen) { try { $serial.Close() } catch {} }
    try { $mutex.ReleaseMutex() } catch {}
    $mutex.Dispose()
}

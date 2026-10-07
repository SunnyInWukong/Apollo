<#
Control an Android phone from this PC over Tailscale, using scrcpy (adb + H.264 mirror).

First run on a phone (pick one):
  A) Android 11+, phone on Wi-Fi: Developer options > Wireless debugging > "Pair device with pairing code", then
       .\phone.ps1 -Phone pixel -Pair 41235 -Code 123456 -Port 38817
     (-Pair = pairing port on that screen, -Port = port on the main Wireless debugging screen. Port changes each time it is toggled.)
  B) Any network incl. mobile data: plug in USB once and run  .\phone.ps1 -Usb
     That switches adbd to TCP 5555 until the phone reboots.

After that:  .\phone.ps1 -Phone pixel            (Tailscale MagicDNS name or 100.x IP)
Extra scrcpy flags pass through:  .\phone.ps1 -Phone pixel -- --turn-screen-off --max-fps 60
#>
param(
    [string]$Phone,
    [int]$Port = 5555,
    [int]$Pair,
    [string]$Code,
    [switch]$Usb,
    [Parameter(ValueFromRemainingArguments)] [string[]]$ScrcpyArgs
)
$ErrorActionPreference = 'Stop'

$dir = Join-Path $env:LOCALAPPDATA 'scrcpy'
$exe = Get-ChildItem $dir -Recurse -Filter scrcpy.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    $rel = Invoke-RestMethod 'https://api.github.com/repos/Genymobile/scrcpy/releases/latest'
    $asset = $rel.assets | Where-Object name -like 'scrcpy-win64-*.zip' | Select-Object -First 1
    if (-not $asset) { throw 'No scrcpy win64 asset in latest release' }
    $zip = Join-Path $env:TEMP $asset.name
    Write-Host "Downloading $($asset.name)"
    Invoke-WebRequest $asset.browser_download_url -OutFile $zip
    Expand-Archive $zip $dir -Force
    Remove-Item $zip
    $exe = Get-ChildItem $dir -Recurse -Filter scrcpy.exe | Select-Object -First 1
}
$adb = Join-Path $exe.DirectoryName 'adb.exe'

if ($Usb) {
    & $adb usb | Out-Null
    & $adb tcpip 5555
    Write-Host 'adbd now on TCP 5555. Unplug and run: .\phone.ps1 -Phone <tailscale-name>'
    return
}
if (-not $Phone) { throw 'Pass -Phone <tailscale name or 100.x IP>, or -Usb for first-time setup' }

if ($Pair) {
    if (-not $Code) { throw '-Pair needs -Code (6-digit pairing code)' }
    & $adb pair "${Phone}:$Pair" $Code
    if ($LASTEXITCODE) { throw 'adb pair failed' }
}

$serial = "${Phone}:$Port"
$out = & $adb connect $serial
Write-Host $out
if ($out -notmatch 'connected') { throw "adb connect $serial failed. Phone on Tailscale? Wireless debugging port changed?" }

& $exe.FullName -s $serial --video-bit-rate 8M --max-size 1920 @ScrcpyArgs

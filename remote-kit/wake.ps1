<#
Wake a sleeping PC with a Wake-on-LAN magic packet.

Magic packets are LAN broadcasts; they do not cross Tailscale. A sleeping PC is also offline on Tailscale.
So the packet has to leave from a device that is awake on the same LAN as the target:
  On the same LAN:            .\wake.ps1 -Mac 2C:F0:5D:11:22:33
  From anywhere, via relay:   .\wake.ps1 -Mac 2C:F0:5D:11:22:33 -Via pi@homepi
    -Via = any always-on box on the home LAN with Tailscale + SSH + python3 (Raspberry Pi, NAS, router).

Target PC needs: BIOS "Wake on LAN" on, NIC driver "Wake on Magic Packet" on, Fast Startup off.
Get its MAC with:  getmac /v  (on the target)
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$')] [string]$Mac,
    [string]$Via
)
$ErrorActionPreference = 'Stop'
$hex = $Mac -replace '[:-]', ''

if ($Via) {
    # script goes over stdin: Windows PowerShell 5.1 mangles embedded quotes in native-command args
    "import socket;s=socket.socket(2,2);s.setsockopt(1,6,1);s.sendto(bytes.fromhex('ff'*6+'$hex'*16),('255.255.255.255',9))" | ssh $Via python3 -
    if ($LASTEXITCODE) { throw "Relay $Via failed" }
} else {
    $macBytes = 0..5 | ForEach-Object { [Convert]::ToByte($hex.Substring($_ * 2, 2), 16) }
    [byte[]]$bytes = @(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF) + (1..16 | ForEach-Object { $macBytes })
    $udp = [System.Net.Sockets.UdpClient]::new()
    $udp.EnableBroadcast = $true
    [void]$udp.Send($bytes, $bytes.Length, '255.255.255.255', 9)
    $udp.Close()
}
Write-Host "Magic packet sent for $Mac. Give it ~20 s, then connect."

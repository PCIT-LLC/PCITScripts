# Network/set-wired-dhcp.ps1
# Detects the wired (Ethernet) adapter and sets it to DHCP (IP, gateway, DNS)

Write-Host "Detecting wired network adapter..."

# Get the first wired adapter (Ethernet, not Wi-Fi)
$wired = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -notmatch "Wi-Fi|Wireless|Bluetooth" -and
    $_.Status -eq "Up" -and
    $_.HardwareInterface -eq $true
} | Select-Object -First 1

if (-not $wired) {
    Write-Error "No active wired network adapter found."
    exit 1
}

Write-Host "Found: $($wired.Name) ($($wired.InterfaceDescription))"
Write-Host "Current IP: $($wired.IPAddress)"

# Remove existing static IP addresses
Write-Host "Removing static IP addresses..."
Get-NetIPAddress -InterfaceIndex $wired.InterfaceIndex -ErrorAction SilentlyContinue | Where-Object {
    $_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -eq "Manual"
} | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

# Remove existing default gateway(s)
Write-Host "Removing default gateway(s)..."
Get-NetRoute -InterfaceIndex $wired.InterfaceIndex -ErrorAction SilentlyContinue | Where-Object {
    $_.DestinationPrefix -eq "0.0.0.0/0"
} | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

# Set IP to DHCP
Write-Host "Setting adapter to DHCP..."
Set-NetIPInterface -InterfaceIndex $wired.InterfaceIndex -Dhcp Enabled

# Set DNS to DHCP (remove any static DNS servers)
Write-Host "Setting DNS to DHCP..."
Set-DnsClientServerAddress -InterfaceIndex $wired.InterfaceIndex -ResetServerAddresses

# Disable then re-enable the adapter to force a fresh DHCP lease
Write-Host "Restarting adapter..."
Disable-NetAdapter -Name $wired.Name -Confirm:$false
Start-Sleep -Seconds 1
Enable-NetAdapter -Name $wired.Name -Confirm:$false

# Wait for DHCP lease
Write-Host "Waiting for DHCP..."
Start-Sleep -Seconds 5

# Verify
$adapter = Get-NetAdapter -InterfaceIndex $wired.InterfaceIndex
$ip = Get-NetIPAddress -InterfaceIndex $wired.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
$dns = Get-DnsClientServerAddress -InterfaceIndex $wired.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
$gateway = Get-NetRoute -InterfaceIndex $wired.InterfaceIndex -ErrorAction SilentlyContinue | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }

Write-Host ""
Write-Host "Adapter: $($adapter.Name)"
Write-Host "Status: $($adapter.Status)"
Write-Host "DHCP Enabled: $($adapter.Dhcp)"
if ($ip) {
    Write-Host "IP Address: $($ip.IPAddress)/$($ip.PrefixLength)"
} else {
    Write-Host "IP Address: (none assigned yet)"
}
if ($gateway) {
    Write-Host "Default Gateway: $($gateway.NextHop)"
} else {
    Write-Host "Default Gateway: (none)"
}
if ($dns) {
    Write-Host "DNS Servers: $($dns.ServerAddresses -join ', ')"
} else {
    Write-Host "DNS Servers: (none)"
}
Write-Host ""
Write-Host "Done. Wired adapter is now fully set to DHCP (IP, gateway, DNS)."

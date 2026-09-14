# Network/set-wired-dhcp.ps1
# Detects the wired (Ethernet) adapter and sets it to DHCP

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

# Set to DHCP
Write-Host "Setting adapter to DHCP..."
Set-NetIPInterface -InterfaceIndex $wired.InterfaceIndex -Dhcp Enabled

# Verify
Start-Sleep -Seconds 2
$adapter = Get-NetAdapter -InterfaceIndex $wired.InterfaceIndex
$ip = Get-NetIPAddress -InterfaceIndex $wired.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1

Write-Host ""
Write-Host "Adapter: $($adapter.Name)"
Write-Host "Status: $($adapter.Status)"
Write-Host "DHCP: $($adapter.Dhcp)"
if ($ip) {
    Write-Host "IP Address: $($ip.IPAddress)"
} else {
    Write-Host "IP Address: (none assigned yet)"
}
Write-Host ""
Write-Host "Done. Wired adapter is now set to DHCP."

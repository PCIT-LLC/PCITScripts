# Network/set-wired-static.ps1
# Sets a static IP on the wired adapter (no gateway, no DNS change)

Write-Host "Detecting wired network adapter..."

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

# Prompt for IP address
$ip = Read-Host "Enter static IP address (e.g. 192.168.1.50)"
if (-not $ip -or $ip -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    Write-Error "Invalid IP address."
    exit 1
}

$prefix = 25  # 255.255.255.0

# Remove existing static IP addresses
Write-Host "Removing existing IP configuration..."
Get-NetIPAddress -InterfaceIndex $wired.InterfaceIndex -ErrorAction SilentlyContinue | Where-Object {
    $_.AddressFamily -eq "IPv4"
} | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

# Remove existing default gateway(s)
Write-Host "Removing default gateway..."
Get-NetRoute -InterfaceIndex $wired.InterfaceIndex -ErrorAction SilentlyContinue | Where-Object {
    $_.DestinationPrefix -eq "0.0.0.0/0"
} | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

# Set static IP using netsh (disables DHCP at the same time)
Write-Host "Setting static IP $ip via netsh..."
netsh interface ip set address name="$($wired.Name)" source=static addr=$ip mask=255.255.255.0

Start-Sleep -Seconds 2

# Verify
Start-Sleep -Seconds 2
$adapter = Get-NetAdapter -InterfaceIndex $wired.InterfaceIndex
$ipInfo = Get-NetIPAddress -InterfaceIndex $wired.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -eq $ip }
$gateway = Get-NetRoute -InterfaceIndex $wired.InterfaceIndex -ErrorAction SilentlyContinue | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }

Write-Host ""
Write-Host "Adapter: $($adapter.Name)"
Write-Host "Status: $($adapter.Status)"
Write-Host "DHCP: $($adapter.Dhcp)"
if ($ipInfo) {
    Write-Host "IP Address: $($ipInfo.IPAddress)/$($ipInfo.PrefixLength)"
} else {
    Write-Host "IP Address: (not assigned)"
}
Write-Host "Default Gateway: $(if ($gateway) { $gateway.NextHop } else { '(none)' })"
Write-Host "DNS: (unchanged)"
Write-Host ""
Write-Host "Done. Wired adapter set to static IP $ip (no gateway)."

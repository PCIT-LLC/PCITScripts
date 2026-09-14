Write-Host "Resetting TCP/IP stack..."
try {
    netsh int ip reset
    Write-Host "Done. TCP/IP stack reset. Reboot recommended."
} catch {
    Write-Error "Failed: $_"
    throw
}

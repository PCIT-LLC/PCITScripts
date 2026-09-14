Write-Host "Flushing DNS resolver cache..."
try {
    Clear-DnsClientCache
    Write-Host "Done. DNS cache flushed."
} catch {
    Write-Error "Failed: $_"
    throw
}

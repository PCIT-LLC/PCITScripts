Write-Host "Running Disk Cleanup..."
try {
    # Run the built-in Disk Cleanup utility
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
    Write-Host "Disk Cleanup completed."
} catch {
    Write-Error "Failed: $_"
    throw
}

# SwmfsMonitor PowerShell Module - swmfs_monitor Integration

This document demonstrates how to use the `Get-SwmfsMonitorStats` function to parse output from the `swmfs_monitor` utility.

## Function Overview

The `Get-SwmfsMonitorStats` function parses the output from `swmfs_monitor` and converts it into structured PowerShell objects for easy analysis and automation of SWMFS server performance monitoring.

## Usage Examples

### Basic Usage

```powershell
# Import the module
Import-Module ./SwmfsMonitor.psm1

# Get server statistics
$stats = Get-SwmfsMonitorStats -InstanceName "dbserver"

# Or parse raw output directly
$rawOutput = & swmfs_monitor dbserver
$stats = Get-SwmfsMonitorStats -InstanceName "dbserver" -RawOutput $rawOutput
```

### Analyzing Server Performance

```powershell
# Display basic server information
Write-Host "=== SWMFS Server Performance Report ==="
Write-Host "Instance: $($stats.InstanceName)"
Write-Host "Runtime - Real: $($stats.SecondsElapsedReal)s, User: $($stats.SecondsElapsedUser)s, Kernel: $($stats.SecondsElapsedKernel)s"

# Connection statistics
Write-Host "`n=== Connection Statistics ==="
Write-Host "Clients Connected - Now: $($stats.ClientsConnectedNow), Max: $($stats.ClientsConnectedMax), Total: $($stats.ClientsConnectedTotal)"
Write-Host "Files Opened - Now: $($stats.FilesOpenedNow), Max: $($stats.FilesOpenedMax), Total: $($stats.FilesOpenedTotal)"
Write-Host "Jobs Allocated Total: $($stats.JobsAllocatedTotal)"

# File I/O operations
Write-Host "`n=== File I/O Operations ==="
Write-Host "Reads: $($stats.FileIOReads), Writes: $($stats.FileIOWrites), Flushes: $($stats.FileIOFlushes)"
Write-Host "Locks: $($stats.FileIOLocks), Usages: $($stats.FileIOUsages), Extends: $($stats.FileIOExtends)"
```

### Performance Analysis and Alerting

```powershell
# Calculate CPU efficiency
$cpuEfficiency = if ($stats.SecondsElapsedReal -gt 0) { 
    ($stats.SecondsElapsedUser + $stats.SecondsElapsedKernel) / $stats.SecondsElapsedReal * 100 
} else { 0 }

Write-Host "CPU Efficiency: $([math]::Round($cpuEfficiency, 2))%"

# Check for performance issues
$warnings = @()

# High client load check
if ($stats.ClientsConnectedNow -gt 100) {
    $warnings += "High client load: $($stats.ClientsConnectedNow) clients connected"
}

# Multiblock I/O efficiency check
if ($stats.MultiblockIOTimedOut -gt 0) {
    $timeoutRate = ($stats.MultiblockIOTimedOut / $stats.MultiblockIOWriteRequests) * 100
    $warnings += "Multiblock I/O timeouts detected: $($stats.MultiblockIOTimedOut) ($([math]::Round($timeoutRate, 2))%)"
}

# Async I/O thread utilization check
if ($stats.AsyncFileIOThreadsInUse -eq $stats.AsyncFileIOThreadsAllocated) {
    $warnings += "All async I/O threads in use - potential bottleneck"
}

# Network issues check
if ($stats.ReconnectFailures -gt 0) {
    $warnings += "Network reconnection failures detected: $($stats.ReconnectFailures)"
}

if ($warnings.Count -gt 0) {
    Write-Host "`n=== Performance Warnings ===" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "⚠️  $warning" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n✅ No performance issues detected" -ForegroundColor Green
}
```

### Detailed I/O Analysis

```powershell
# Multiblock I/O statistics
Write-Host "`n=== Multiblock I/O Statistics ==="
Write-Host "Read Requests: $($stats.MultiblockIOReadRequests)"
Write-Host "Blocks Requested: $($stats.MultiblockIOBlocksRequested)"
Write-Host "Blocks Read: $($stats.MultiblockIOBlocksRead)"

if ($stats.MultiblockIOBlocksRequested -gt 0) {
    $readEfficiency = ($stats.MultiblockIOBlocksRead / $stats.MultiblockIOBlocksRequested) * 100
    Write-Host "Read Efficiency: $([math]::Round($readEfficiency, 2))%"
}

Write-Host "Write Requests: $($stats.MultiblockIOWriteRequests)"
Write-Host "Blocks Written: $($stats.MultiblockIOBlocksWritten)"
Write-Host "Timed Out: $($stats.MultiblockIOTimedOut)"

# Async File I/O statistics
Write-Host "`n=== Async File I/O Statistics ==="
Write-Host "Total Operations: $($stats.AsyncFileIOTotal)"
Write-Host "Reads: $($stats.AsyncFileIOReads), Writes: $($stats.AsyncFileIOWrites), Flushes: $($stats.AsyncFileIOFlushes)"
Write-Host "Requeued: $($stats.AsyncFileIORequeued)"

# Thread pool information
Write-Host "`n=== Thread Pool Information ==="
Write-Host "Allocated: $($stats.AsyncFileIOThreadsAllocated)"
Write-Host "In Use: $($stats.AsyncFileIOThreadsInUse)"
Write-Host "Maximum In Use: $($stats.AsyncFileIOThreadsMaxInUse)"
Write-Host "Free List Length: $($stats.AsyncFileIOThreadsFreeListLength)"
Write-Host "Free List Limit: $($stats.AsyncFileIOThreadsFreeListLimit)"

$threadUtilization = if ($stats.AsyncFileIOThreadsAllocated -gt 0) {
    ($stats.AsyncFileIOThreadsInUse / $stats.AsyncFileIOThreadsAllocated) * 100
} else { 0 }
Write-Host "Current Utilization: $([math]::Round($threadUtilization, 2))%"
```

### Network and Reliability Monitoring

```powershell
# Network statistics
Write-Host "`n=== Network Statistics ==="
Write-Host "TCP Bytes Received: $($stats.TCPBytesReceived)"
Write-Host "TCP Bytes Sent: $($stats.TCPBytesSent)"

$totalTraffic = $stats.TCPBytesReceived + $stats.TCPBytesSent
Write-Host "Total Traffic: $([math]::Round($totalTraffic / 1MB, 2)) MB"

# Keepalive and connection health
Write-Host "`n=== Connection Health ==="
Write-Host "Keepalive Sent: $($stats.KeepaliveSent)"
Write-Host "Keepalive Received: $($stats.KeepaliveReceived)"
Write-Host "Ping Requests Received: $($stats.PingRequestsReceived)"
Write-Host "Keepalive Loop Delayed: $($stats.KeepaliveLoopDelayed)"

# Reconnection statistics
Write-Host "`n=== Reconnection Statistics ==="
Write-Host "Reconnect Requests: $($stats.ReconnectRequests)"
Write-Host "Resends Required: $($stats.ReconnectResends)"
Write-Host "Reconnect Failures: $($stats.ReconnectFailures)"
Write-Host "Missing Requests: $($stats.ReconnectMissing)"

# Dead link detection
Write-Host "`n=== Dead Link Detection ==="
Write-Host "Dead Links (UDP): $($stats.DeadLinksUDP)"
Write-Host "Dead Clients (Journal): $($stats.DeadClientsJournal)"
```

### Historical Monitoring and Trending

```powershell
# Create a monitoring snapshot
$snapshot = [PSCustomObject]@{
    Timestamp = Get-Date
    Instance = $stats.InstanceName
    ClientsConnected = $stats.ClientsConnectedNow
    FilesOpened = $stats.FilesOpenedNow
    FileIOReads = $stats.FileIOReads
    FileIOWrites = $stats.FileIOWrites
    CPUEfficiency = if ($stats.SecondsElapsedReal -gt 0) { 
        ($stats.SecondsElapsedUser + $stats.SecondsElapsedKernel) / $stats.SecondsElapsedReal * 100 
    } else { 0 }
    ThreadUtilization = if ($stats.AsyncFileIOThreadsAllocated -gt 0) {
        ($stats.AsyncFileIOThreadsInUse / $stats.AsyncFileIOThreadsAllocated) * 100
    } else { 0 }
    NetworkTrafficMB = ($stats.TCPBytesReceived + $stats.TCPBytesSent) / 1MB
}

# Export to CSV for historical analysis
$snapshot | Export-Csv -Path "swmfs_monitor_history.csv" -Append -NoTypeInformation

Write-Host "`n📊 Snapshot saved to swmfs_monitor_history.csv"
```

## Object Structure

The function returns a `PSCustomObject` with the following structure:

```text
Stats
├── InstanceName (string) - Name of the SWMFS instance
├── SecondsElapsedReal (int) - Real time elapsed in seconds
├── SecondsElapsedUser (int) - User CPU time in seconds
├── SecondsElapsedKernel (int) - Kernel CPU time in seconds
├── ClientsConnectedNow (int) - Current number of connected clients
├── ClientsConnectedMax (int) - Maximum concurrent clients
├── ClientsConnectedTotal (int) - Total clients connected since startup
├── FilesOpenedNow (int) - Current number of open files
├── FilesOpenedMax (int) - Maximum concurrent open files
├── FilesOpenedTotal (int) - Total files opened since startup
├── JobsAllocatedTotal (int) - Total jobs allocated
├── FileIOReads (int) - Total file read operations
├── FileIOWrites (int) - Total file write operations
├── FileIOFlushes (int) - Total file flush operations
├── FileIOLocks (int) - Total file lock operations
├── FileIOUsages (int) - Total file usage operations
├── FileIOExtends (int) - Total file extend operations
├── MultiblockIOReadRequests (int) - Multiblock read requests
├── MultiblockIOBlocksRequested (int) - Blocks requested for reading
├── MultiblockIOBlocksRead (int) - Blocks actually read
├── MultiblockIOWriteRequests (int) - Multiblock write requests
├── MultiblockIOBlocksWritten (int) - Blocks written
├── MultiblockIOTimedOut (int) - Multiblock operations that timed out
├── AsyncFileIOTotal (int) - Total async file I/O operations
├── AsyncFileIOReads (int) - Async file read operations
├── AsyncFileIOWrites (int) - Async file write operations
├── AsyncFileIOFlushes (int) - Async file flush operations
├── AsyncFileIORequeued (int) - Async operations requeued
├── AsyncFileIOThreadsAllocated (int) - Allocated async I/O threads
├── AsyncFileIOThreadsInUse (int) - Currently used async I/O threads
├── AsyncFileIOThreadsMaxInUse (int) - Maximum async I/O threads used
├── AsyncFileIOThreadsFreeListLength (int) - Free thread list length
├── AsyncFileIOThreadsFreeListLimit (int) - Free thread list limit
├── ReconnectRequests (int) - Total reconnection requests
├── ReconnectResends (int) - Resends required after reconnection
├── ReconnectFailures (int) - Failed reconnection attempts
├── ReconnectMissing (int) - Missing requests during reconnection
├── DeadLinksUDP (int) - Dead links detected by UDP
├── DeadClientsJournal (int) - Dead clients in journal file
├── KeepaliveSent (int) - Keepalive packets sent
├── KeepaliveReceived (int) - Keepalive packets received
├── PingRequestsReceived (int) - Ping requests received
├── KeepaliveLoopDelayed (int) - Keepalive loop delays
├── TCPBytesReceived (int64) - Total TCP bytes received
└── TCPBytesSent (int64) - Total TCP bytes sent
```

## Cross-Platform Support

The function automatically detects the appropriate executable:

- Windows: `swmfs_monitor.exe`
- Linux/macOS: `swmfs_monitor`

You can override this with the `-ExecutablePath` parameter:

```powershell
$stats = Get-SwmfsMonitorStats -ExecutablePath "/custom/path/swmfs_monitor" -InstanceName "dbserver"
```

## Error Handling

The function gracefully handles various edge cases:

- Empty output from swmfs_monitor
- Malformed numeric values
- Missing optional statistics sections

## Integration with Other Functions

Combine with other module functions for comprehensive monitoring:

```powershell
# Get overall server performance
$serverStats = Get-SwmfsMonitorStats -InstanceName "dbserver"

# Get detailed file and client information
$fileUsage = Get-SwmfsListStats -ServerOrHost "dbserver"

# Get lock contention details
$lockInfo = Get-SwmfsLockMonitorStats -ServerOrDirectory "dbserver"

# Create a comprehensive dashboard
Write-Host "=== SWMFS Comprehensive Report ==="
Write-Host "Server Performance:"
Write-Host "  Clients: $($serverStats.ClientsConnectedNow)/$($serverStats.ClientsConnectedMax) (files: $($fileUsage.Files.Count))"
Write-Host "  I/O: $($serverStats.FileIOReads) reads, $($serverStats.FileIOWrites) writes"
Write-Host "  Network: $([math]::Round(($serverStats.TCPBytesReceived + $serverStats.TCPBytesSent) / 1MB, 2)) MB total traffic"

# Check for locks with contention
$contestedLocks = $lockInfo | Where-Object { $_.NumberOfLocks -gt 0 } | 
    ForEach-Object { $_.Locks } | Where-Object { $_.QueuedCount -gt 0 }

if ($contestedLocks.Count -gt 0) {
    Write-Host "  Lock Contention: $($contestedLocks.Count) contested locks detected"
} else {
    Write-Host "  Lock Contention: None"
}
```

## Automation and Alerting Examples

```powershell
# Define performance thresholds
$thresholds = @{
    MaxClients = 80
    MaxCPUEfficiency = 80
    MaxAsyncThreadUtilization = 90
    MaxReconnectFailureRate = 5
}

# Check thresholds and send alerts
$alerts = @()

$cpuEff = ($serverStats.SecondsElapsedUser + $serverStats.SecondsElapsedKernel) / $serverStats.SecondsElapsedReal * 100
if ($cpuEff -gt $thresholds.MaxCPUEfficiency) {
    $alerts += "High CPU usage: $([math]::Round($cpuEff, 1))%"
}

$threadUtil = ($serverStats.AsyncFileIOThreadsInUse / $serverStats.AsyncFileIOThreadsAllocated) * 100
if ($threadUtil -gt $thresholds.MaxAsyncThreadUtilization) {
    $alerts += "High async thread utilization: $([math]::Round($threadUtil, 1))%"
}

if ($serverStats.ClientsConnectedNow -gt $thresholds.MaxClients) {
    $alerts += "High client count: $($serverStats.ClientsConnectedNow)"
}

# Send alerts (example using email or logging)
if ($alerts.Count -gt 0) {
    $alertMessage = "SWMFS Performance Alert for $($serverStats.InstanceName):`n" + ($alerts -join "`n")
    Write-Warning $alertMessage
    # Add-Content -Path "swmfs_alerts.log" -Value "$(Get-Date): $alertMessage"
}
```

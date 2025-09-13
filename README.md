# SWMFS Monitoring Scripts

A PowerShell module for parsing and working with SWMFS (Smallworld Master File System) monitoring statistics on Windows and Linux platforms.

## Overview

This repository contains PowerShell scripts that provide an interface to parse output from the `swmfs_monitor` utility (available as `swmfs_monitor.exe` on Windows and `swmfs_monitor` on Linux). The module extracts structured data from the monitoring output, making it easier to analyze SWMFS performance metrics programmatically across different operating systems.

## Features

- **Cross-Platform Support**: Works on both Windows and Linux platforms with automatic executable detection
- **Structured Data Parsing**: Converts raw `swmfs_monitor` output into structured PowerShell objects
- **Comprehensive Metrics**: Extracts all major SWMFS statistics including:
  - Runtime statistics (elapsed time)
  - Client connection metrics
  - File operation counters
  - I/O operation statistics
  - Thread pool information
  - Network communication metrics
  - Recovery and reconnection statistics

## Files

- `SwmfsMonitor.psm1` - Main PowerShell module containing the `Get-SwmfsMonitorStats` function
- `SwmfsMonitor.Tests.ps1` - Pester tests for validating the module functionality
- `README.md` - This documentation file

## Installation

1. Clone or download this repository
2. Import the module in your PowerShell session:

```powershell
Import-Module "./SwmfsMonitor.psm1"
```

## Usage

### Basic Usage

```powershell
# Get statistics for a specific SWMFS instance
$stats = Get-SwmfsMonitorStats -InstanceName "dbserver"
```

### Advanced Usage

```powershell
# Use a custom path to swmfs_monitor executable
# On Windows:
$stats = Get-SwmfsMonitorStats -InstanceName "dbserver" -ExecutablePath "C:\path\to\swmfs_monitor.exe"
# On Linux:
$stats = Get-SwmfsMonitorStats -InstanceName "dbserver" -ExecutablePath "/path/to/swmfs_monitor"

# Parse pre-captured output
$rawOutput = @("Seconds elapsed   : real      403282, user        1687, kernel      7162", ...)
$stats = Get-SwmfsMonitorStats -InstanceName "dbserver" -RawOutput $rawOutput
```

### Output Structure

The function returns a PowerShell object with the following properties:

#### Runtime Statistics

- `InstanceName` - The SWMFS instance name
- `SecondsElapsedReal` - Real time elapsed
- `SecondsElapsedUser` - User time elapsed  
- `SecondsElapsedKernel` - Kernel time elapsed

#### Client Connection Metrics

- `ClientsConnectedNow` - Current connected clients
- `ClientsConnectedMax` - Maximum concurrent clients
- `ClientsConnectedTotal` - Total clients connected

#### File Operations

- `FilesOpenedNow` - Currently open files
- `FilesOpenedMax` - Maximum concurrent open files
- `FilesOpenedTotal` - Total files opened
- `JobsAllocatedTotal` - Total jobs allocated

#### File I/O Statistics

- `FileIOReads` - Number of read operations
- `FileIOWrites` - Number of write operations
- `FileIOFlushes` - Number of flush operations
- `FileIOLocks` - Number of lock operations
- `FileIOUsages` - File usage count
- `FileIOExtends` - File extension operations

#### Multiblock I/O Operations

- `MultiblockIOReadRequests` - Read requests
- `MultiblockIOBlocksRequested` - Blocks requested for reading
- `MultiblockIOBlocksRead` - Blocks actually read
- `MultiblockIOWriteRequests` - Write requests
- `MultiblockIOBlocksWritten` - Blocks written
- `MultiblockIOTimedOut` - Timed out operations

#### Asynchronous File I/O

- `AsyncFileIOTotal` - Total async operations
- `AsyncFileIOReads` - Async read operations
- `AsyncFileIOWrites` - Async write operations
- `AsyncFileIOFlushes` - Async flush operations
- `AsyncFileIORequeued` - Requeued operations

#### Thread Pool Statistics

- `AsyncFileIOThreadsAllocated` - Total allocated threads
- `AsyncFileIOThreadsInUse` - Currently active threads
- `AsyncFileIOThreadsMaxInUse` - Maximum concurrent threads
- `AsyncFileIOThreadsFreeListLength` - Available threads
- `AsyncFileIOThreadsFreeListLimit` - Thread pool limit

#### Recovery and Reconnection

- `ReconnectRequests` - Reconnection requests
- `ReconnectResends` - Required resends
- `ReconnectFailures` - Failed reconnections
- `ReconnectMissing` - Missing requests
- `DeadLinksUDP` - Dead links detected via UDP
- `DeadClientsJournal` - Dead clients in journal

#### Network Communication

- `KeepaliveSent` - Keepalive packets sent
- `KeepaliveReceived` - Keepalive packets received
- `PingRequestsReceived` - Ping requests received
- `KeepaliveLoopDelayed` - Delayed keepalive loops
- `TCPBytesReceived` - Total TCP bytes received
- `TCPBytesSent` - Total TCP bytes sent

## Testing

Run the included Pester tests to validate functionality:

```powershell
Invoke-Pester -Script SwmfsMonitor.Tests.ps1
```

## Requirements

- PowerShell 5.1 or later (Windows PowerShell or PowerShell Core)
- Access to `swmfs_monitor` utility:
  - Windows: `swmfs_monitor.exe`
  - Linux: `swmfs_monitor`
- Pester module (for running tests)

The module automatically detects the operating system and uses the appropriate executable name.

## Examples

### Monitoring Multiple Instances

```powershell
$instances = @("dbserver1", "dbserver2", "appserver")
$allStats = foreach ($instance in $instances) {
    Get-SwmfsMonitorStats -InstanceName $instance
}
```

### Extracting Specific Metrics

```powershell
$stats = Get-SwmfsMonitorStats -InstanceName "dbserver"
Write-Host "Current Clients: $($stats.ClientsConnectedNow)"
Write-Host "Total I/O Operations: $($stats.FileIOReads + $stats.FileIOWrites)"
Write-Host "Network Throughput: $($stats.TCPBytesReceived + $stats.TCPBytesSent) bytes"
```

## License

This project is provided as-is for working with SWMFS monitoring data.

## Contributing

When contributing to this project:

1. Ensure all tests pass
2. Add tests for new functionality
3. Follow PowerShell best practices
4. Update documentation as needed

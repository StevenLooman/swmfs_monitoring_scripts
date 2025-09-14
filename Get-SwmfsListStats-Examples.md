# SwmfsMonitor PowerShell Module - swmfs_list Integration

This document demonstrates how to use the `Get-SwmfsListStats` function to parse output from the `swmfs_list` utility.

## Function Overview

The `Get-SwmfsListStats` function parses the output from `swmfs_list -post_process` and converts it into structured PowerShell objects for easy analysis and automation.

## Usage Examples

### Basic Usage

```powershell
# Import the module
Import-Module ./SwmfsMonitor.psm1

# Run swmfs_list and parse the output
$result = Get-SwmfsListStats -ServerOrHost "dbserver"

# Or parse raw output directly
$rawOutput = & swmfs_list -post_process dbserver
$result = Get-SwmfsListStats -RawOutput $rawOutput
```

### Analyzing the Results

```powershell
# Check server information
Write-Host "Server: $($result.ServerName)"
Write-Host "Time: $($result.ServerTime)"
Write-Host "Number of files running: $($result.Files.Count)"

# Examine each file
foreach ($file in $result.Files) {
    Write-Host "File: $($file.FilePath)"
    Write-Host "  Thread ID: $($file.ThreadId)"
    Write-Host "  Requests: $($file.Requests)"
    Write-Host "  Clients: $($file.Clients.Count)"
    
    # Show client details
    foreach ($client in $file.Clients) {
        Write-Host "    Client: $($client.ClientName) - $($client.Status)"
        Write-Host "      ID: $($client.ClientId), Requests: $($client.Requests), Reads: $($client.Reads)"
    }
}
```

### Filtering and Analysis

```powershell
# Find files with high activity
$busyFiles = $result.Files | Where-Object { $_.Clients.Count -gt 5 }

# Find idle clients
$idleClients = $result.Files | ForEach-Object { $_.Clients } | Where-Object { $_.Status -eq "idle" }

# Calculate total requests across all files
$totalRequests = ($result.Files | Measure-Object -Property Requests -Sum).Sum

# Find clients with high read activity
$highReadClients = $result.Files | ForEach-Object { $_.Clients } | Where-Object { $_.Reads -gt 1000 }
```

## Object Structure

The function returns a `PSCustomObject` with the following structure:

```
Result
├── ServerName (string) - Name of the SWMFS server
├── ServerTime (DateTime or string) - Server timestamp
└── Files (array) - List of running datastore files
    ├── FilePath (string) - Full path to the datastore file
    ├── ThreadId (int) - Server thread ID
    ├── Time (int) - Thread time
    ├── CPUTime (int) - CPU time in seconds
    ├── Requests (int) - Total requests processed
    └── Clients (array) - List of connected clients
        ├── ClientId (int64) - Unique client identifier
        ├── ClientName (string) - Client name (user@host format)
        ├── Time (int) - Client time
        ├── Requests (int) - Client requests
        ├── Reads (int) - Client read operations
        ├── Extends (int) - Client extend operations
        ├── Flushes (int) - Client flush operations
        ├── Locks (int) - Client lock operations
        ├── State (int) - Client state number
        └── Status (string) - Client status (idle, active, listing, etc.)
```

## Cross-Platform Support

The function automatically detects the appropriate executable:

- Windows: `swmfs_list.exe`
- Linux/macOS: `swmfs_list`

You can override this with the `-ExecutablePath` parameter:

```powershell
$result = Get-SwmfsListStats -ExecutablePath "/custom/path/swmfs_list" -ServerOrHost "dbserver"
```

## Error Handling

The function gracefully handles various edge cases:

- Empty output
- Malformed date strings
- Files with no clients
- Client names with special characters

## Integration with Other Functions

Combine with other module functions for comprehensive monitoring:

```powershell
# Get overall server stats
$serverStats = Get-SwmfsMonitorStats -InstanceName "dbserver"

# Get file usage details
$fileUsage = Get-SwmfsListStats -ServerOrHost "dbserver"

# Get lock information
$lockInfo = Get-SwmfsLockMonitorStats -ServerOrDirectory "dbserver"

# Create a comprehensive report
Write-Host "=== SWMFS Server Report ==="
Write-Host "Server: $($fileUsage.ServerName)"
Write-Host "Connected Clients: $($serverStats.ClientsConnectedNow)"
Write-Host "Files Running: $($fileUsage.Files.Count)"
Write-Host "Total File Operations: Reads=$($serverStats.FileIOReads), Writes=$($serverStats.FileIOWrites)"
```

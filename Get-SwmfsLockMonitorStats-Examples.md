# SwmfsMonitor PowerShell Module - swmfs_lock_monitor Integration

This document demonstrates how to use the `Get-SwmfsLockMonitorStats` function to parse output from the `swmfs_lock_monitor` utility.

## Function Overview

The `Get-SwmfsLockMonitorStats` function parses the output from `swmfs_lock_monitor` and converts it into structured PowerShell objects for easy analysis and automation of SWMFS file lock monitoring.

## Usage Examples

### Basic Usage

```powershell
# Import the module
Import-Module ./SwmfsMonitor.psm1

# Monitor locks on a specific server
$lockStats = Get-SwmfsLockMonitorStats -ServerOrDirectory "dbserver"

# Monitor locks on a specific file
$lockStats = Get-SwmfsLockMonitorStats -ServerOrDirectory "dbserver" -File "admin_scratch.ds"

# Or parse raw output directly
$rawOutput = & swmfs_lock_monitor dbserver
$lockStats = Get-SwmfsLockMonitorStats -RawOutput $rawOutput
```

### Analyzing Lock Information

```powershell
# Display basic lock statistics
Write-Host "=== SWMFS Lock Monitor Report ==="
Write-Host "Number of files with locks: $($lockStats.Count)"

$totalLocks = ($lockStats | Measure-Object -Property NumberOfLocks -Sum).Sum
Write-Host "Total locks across all files: $totalLocks"

# Examine each file's locks
foreach ($file in $lockStats) {
    Write-Host "`nFile: $($file.FilePath)"
    Write-Host "  Number of locks: $($file.NumberOfLocks)"
    
    foreach ($lock in $file.Locks) {
        Write-Host "  Lock ID $($lock.LockId) ($($lock.ExclusivityDescription)):"
        Write-Host "    Holders: $($lock.HolderCount), Queued: $($lock.QueuedCount)"
        
        if ($lock.Holders.Count -gt 0) {
            Write-Host "    Current holders: $($lock.Holders -join ', ')"
        }
        
        if ($lock.QueuedUsers.Count -gt 0) {
            Write-Host "    Queued users: $($lock.QueuedUsers -join ', ')"
        }
    }
}
```

### Lock Contention Analysis

```powershell
# Find files with lock contention
$contestedFiles = $lockStats | Where-Object { 
    $_.Locks | Where-Object { $_.QueuedCount -gt 0 } 
}

if ($contestedFiles.Count -gt 0) {
    Write-Host "`n=== Lock Contention Analysis ===" -ForegroundColor Yellow
    
    foreach ($file in $contestedFiles) {
        $contestedLocks = $file.Locks | Where-Object { $_.QueuedCount -gt 0 }
        
        Write-Host "`nFile: $($file.FilePath)" -ForegroundColor Yellow
        Write-Host "  Contested locks: $($contestedLocks.Count)"
        
        foreach ($lock in $contestedLocks) {
            Write-Host "  🔒 Lock $($lock.LockId) ($($lock.ExclusivityDescription)):"
            Write-Host "    👥 $($lock.HolderCount) holders, ⏳ $($lock.QueuedCount) waiting"
            Write-Host "    Holders: $($lock.Holders -join ', ')"
            Write-Host "    Waiting: $($lock.QueuedUsers -join ', ')"
            
            # Calculate wait time impact
            $totalWaiting = $lock.QueuedCount
            if ($totalWaiting -gt 5) {
                Write-Host "    ⚠️  High contention: $totalWaiting users waiting" -ForegroundColor Red
            } elseif ($totalWaiting -gt 2) {
                Write-Host "    ⚠️  Moderate contention: $totalWaiting users waiting" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "`n✅ No lock contention detected" -ForegroundColor Green
}
```

### Lock Usage Patterns

```powershell
# Analyze lock usage patterns
Write-Host "`n=== Lock Usage Patterns ==="

# Count exclusive vs non-exclusive locks
$exclusiveLocks = $lockStats | ForEach-Object { $_.Locks } | Where-Object { $_.Exclusivity -eq 'X' }
$nonExclusiveLocks = $lockStats | ForEach-Object { $_.Locks } | Where-Object { $_.Exclusivity -eq 'N' }

Write-Host "Exclusive locks: $($exclusiveLocks.Count)"
Write-Host "Non-exclusive locks: $($nonExclusiveLocks.Count)"

# Find locks with multiple holders (should only be non-exclusive)
$multiHolderLocks = $lockStats | ForEach-Object { $_.Locks } | Where-Object { $_.HolderCount -gt 1 }

if ($multiHolderLocks.Count -gt 0) {
    Write-Host "`nShared locks (multiple holders):"
    foreach ($lock in $multiHolderLocks) {
        $file = $lockStats | Where-Object { $_.Locks -contains $lock }
        Write-Host "  File: $($file.FilePath), Lock $($lock.LockId): $($lock.HolderCount) holders"
        Write-Host "    Holders: $($lock.Holders -join ', ')"
    }
}

# Find the most contested locks
$mostContested = $lockStats | ForEach-Object { $_.Locks } | 
    Sort-Object QueuedCount -Descending | Select-Object -First 5

if ($mostContested[0].QueuedCount -gt 0) {
    Write-Host "`nMost contested locks:"
    foreach ($lock in $mostContested | Where-Object { $_.QueuedCount -gt 0 }) {
        $file = $lockStats | Where-Object { $_.Locks -contains $lock }
        Write-Host "  File: $($file.FilePath), Lock $($lock.LockId): $($lock.QueuedCount) waiting"
    }
}
```

### User Activity Analysis

```powershell
# Analyze user activity across all locks
Write-Host "`n=== User Activity Analysis ==="

# Get all unique users
$allHolders = $lockStats | ForEach-Object { $_.Locks } | ForEach-Object { $_.Holders } | Sort-Object -Unique
$allQueued = $lockStats | ForEach-Object { $_.Locks } | ForEach-Object { $_.QueuedUsers } | Sort-Object -Unique
$allUsers = ($allHolders + $allQueued) | Sort-Object -Unique

Write-Host "Total unique users: $($allUsers.Count)"
Write-Host "Users holding locks: $($allHolders.Count)"
Write-Host "Users waiting for locks: $($allQueued.Count)"

# Find users with multiple locks
$userLockCounts = @{}
foreach ($file in $lockStats) {
    foreach ($lock in $file.Locks) {
        foreach ($holder in $lock.Holders) {
            $userLockCounts[$holder] = ($userLockCounts[$holder] ?? 0) + 1
        }
    }
}

$heavyUsers = $userLockCounts.GetEnumerator() | Where-Object { $_.Value -gt 1 } | Sort-Object Value -Descending

if ($heavyUsers.Count -gt 0) {
    Write-Host "`nUsers with multiple locks:"
    foreach ($user in $heavyUsers) {
        Write-Host "  $($user.Key): $($user.Value) locks"
    }
}

# Find users experiencing the most wait time
$userWaitCounts = @{}
foreach ($file in $lockStats) {
    foreach ($lock in $file.Locks) {
        foreach ($waiter in $lock.QueuedUsers) {
            $userWaitCounts[$waiter] = ($userWaitCounts[$waiter] ?? 0) + 1
        }
    }
}

$waitingUsers = $userWaitCounts.GetEnumerator() | Sort-Object Value -Descending

if ($waitingUsers.Count -gt 0) {
    Write-Host "`nUsers waiting for locks:"
    foreach ($user in $waitingUsers) {
        Write-Host "  $($user.Key): waiting for $($user.Value) locks"
    }
}
```

### File-Level Lock Analysis

```powershell
# Analyze locks at the file level
Write-Host "`n=== File-Level Lock Analysis ==="

# Sort files by lock activity
$filesByActivity = $lockStats | Sort-Object NumberOfLocks -Descending

Write-Host "Files by lock activity:"
foreach ($file in $filesByActivity) {
    if ($file.NumberOfLocks -gt 0) {
        $contestedCount = ($file.Locks | Where-Object { $_.QueuedCount -gt 0 }).Count
        $exclusiveCount = ($file.Locks | Where-Object { $_.Exclusivity -eq 'X' }).Count
        
        Write-Host "  $($file.FilePath):"
        Write-Host "    Total locks: $($file.NumberOfLocks)"
        Write-Host "    Exclusive: $exclusiveCount, Contested: $contestedCount"
        
        if ($contestedCount -gt 0) {
            Write-Host "    ⚠️  Lock contention detected" -ForegroundColor Yellow
        }
    }
}

# Calculate file lock efficiency
foreach ($file in $lockStats | Where-Object { $_.NumberOfLocks -gt 0 }) {
    $totalHolders = ($file.Locks | Measure-Object -Property HolderCount -Sum).Sum
    $totalQueued = ($file.Locks | Measure-Object -Property QueuedCount -Sum).Sum
    
    if ($totalQueued -gt 0) {
        $efficiencyRatio = $totalHolders / ($totalHolders + $totalQueued)
        Write-Host "`nFile: $($file.FilePath)"
        Write-Host "  Lock efficiency: $([math]::Round($efficiencyRatio * 100, 1))% ($totalHolders active / $($totalHolders + $totalQueued) total)"
    }
}
```

### Alerting and Monitoring

```powershell
# Define lock monitoring thresholds
$thresholds = @{
    MaxQueuedPerLock = 5
    MaxContestedLocksPerFile = 3
    MaxTotalQueuedUsers = 10
}

# Check thresholds and generate alerts
$alerts = @()

# Check for individual locks with high contention
$highContentionLocks = $lockStats | ForEach-Object { $_.Locks } | 
    Where-Object { $_.QueuedCount -gt $thresholds.MaxQueuedPerLock }

if ($highContentionLocks.Count -gt 0) {
    $alerts += "High contention locks detected: $($highContentionLocks.Count) locks with >$($thresholds.MaxQueuedPerLock) queued users"
}

# Check for files with too many contested locks
$highContentionFiles = $lockStats | Where-Object { 
    ($_.Locks | Where-Object { $_.QueuedCount -gt 0 }).Count -gt $thresholds.MaxContestedLocksPerFile 
}

if ($highContentionFiles.Count -gt 0) {
    $alerts += "Files with high lock contention: $($highContentionFiles.Count) files with >$($thresholds.MaxContestedLocksPerFile) contested locks"
}

# Check total system-wide queued users
$totalQueuedUsers = ($lockStats | ForEach-Object { $_.Locks } | Measure-Object -Property QueuedCount -Sum).Sum

if ($totalQueuedUsers -gt $thresholds.MaxTotalQueuedUsers) {
    $alerts += "High system-wide lock contention: $totalQueuedUsers users waiting for locks"
}

# Report alerts
if ($alerts.Count -gt 0) {
    Write-Host "`n=== Lock Monitoring Alerts ===" -ForegroundColor Red
    foreach ($alert in $alerts) {
        Write-Host "🚨 $alert" -ForegroundColor Red
    }
    
    # Log alerts
    $alertMessage = "SWMFS Lock Alert: " + ($alerts -join "; ")
    # Add-Content -Path "swmfs_lock_alerts.log" -Value "$(Get-Date): $alertMessage"
} else {
    Write-Host "`n✅ All lock monitoring thresholds are within normal ranges" -ForegroundColor Green
}
```

### Lock History and Trending

```powershell
# Create a lock monitoring snapshot
$snapshot = [PSCustomObject]@{
    Timestamp = Get-Date
    TotalFiles = $lockStats.Count
    FilesWithLocks = ($lockStats | Where-Object { $_.NumberOfLocks -gt 0 }).Count
    TotalLocks = ($lockStats | Measure-Object -Property NumberOfLocks -Sum).Sum
    ExclusiveLocks = ($lockStats | ForEach-Object { $_.Locks } | Where-Object { $_.Exclusivity -eq 'X' }).Count
    NonExclusiveLocks = ($lockStats | ForEach-Object { $_.Locks } | Where-Object { $_.Exclusivity -eq 'N' }).Count
    ContestedLocks = ($lockStats | ForEach-Object { $_.Locks } | Where-Object { $_.QueuedCount -gt 0 }).Count
    TotalHolders = ($lockStats | ForEach-Object { $_.Locks } | Measure-Object -Property HolderCount -Sum).Sum
    TotalQueued = ($lockStats | ForEach-Object { $_.Locks } | Measure-Object -Property QueuedCount -Sum).Sum
    UniqueUsers = (($lockStats | ForEach-Object { $_.Locks } | ForEach-Object { $_.Holders + $_.QueuedUsers }) | Sort-Object -Unique).Count
}

# Export to CSV for historical analysis
$snapshot | Export-Csv -Path "swmfs_lock_history.csv" -Append -NoTypeInformation

Write-Host "`n📊 Lock monitoring snapshot saved to swmfs_lock_history.csv"

# Display summary metrics
Write-Host "`n=== Summary Metrics ==="
Write-Host "Lock efficiency: $([math]::Round(($snapshot.TotalHolders / ($snapshot.TotalHolders + $snapshot.TotalQueued)) * 100, 1))%"
Write-Host "Contention rate: $([math]::Round(($snapshot.ContestedLocks / $snapshot.TotalLocks) * 100, 1))%"
Write-Host "Average locks per active file: $([math]::Round($snapshot.TotalLocks / $snapshot.FilesWithLocks, 1))"
```

## Object Structure

The function returns an array of `PSCustomObject` representing files, each with the following structure:

```text
File[]
├── FilePath (string) - Full path to the datastore file
├── NumberOfLocks (int) - Total number of locks on this file
└── Locks[] - Array of lock objects
    ├── LockId (int) - Unique lock identifier
    ├── Exclusivity (string) - 'X' for exclusive, 'N' for non-exclusive
    ├── ExclusivityDescription (string) - 'Exclusive' or 'Non-Exclusive'
    ├── HolderCount (int) - Number of users currently holding the lock
    ├── QueuedCount (int) - Number of users waiting for the lock
    ├── Holders (string[]) - Array of user names holding the lock
    └── QueuedUsers (string[]) - Array of user names waiting for the lock
```

## Cross-Platform Support

The function automatically detects the appropriate executable:

- Windows: `swmfs_lock_monitor.exe`
- Linux/macOS: `swmfs_lock_monitor`

You can override this with the `-ExecutablePath` parameter:

```powershell
$lockStats = Get-SwmfsLockMonitorStats -ExecutablePath "/custom/path/swmfs_lock_monitor" -ServerOrDirectory "dbserver"
```

## Command Line Arguments

The function supports additional command line arguments through the `-AdditionalArgs` parameter:

```powershell
# Monitor with specific options
$lockStats = Get-SwmfsLockMonitorStats -ServerOrDirectory "dbserver" -AdditionalArgs @("-verbose", "-timeout", "30")
```

## Error Handling

The function gracefully handles various edge cases:

- Empty output from swmfs_lock_monitor
- Files with no locks
- Malformed user names or special characters
- Continuation lines for large user lists

## Integration with Other Functions

Combine with other module functions for comprehensive monitoring:

```powershell
# Get overall server performance
$serverStats = Get-SwmfsMonitorStats -InstanceName "dbserver"

# Get detailed file and client information
$fileUsage = Get-SwmfsListStats -ServerOrHost "dbserver"

# Get lock information
$lockInfo = Get-SwmfsLockMonitorStats -ServerOrDirectory "dbserver"

# Create a comprehensive report correlating performance and locks
Write-Host "=== SWMFS Comprehensive Lock Analysis ==="

# Find files that are both heavily used and have lock contention
$busyFiles = $fileUsage.Files | Where-Object { $_.Clients.Count -gt 3 }
$contestedFiles = $lockInfo | Where-Object { 
    ($_.Locks | Where-Object { $_.QueuedCount -gt 0 }).Count -gt 0 
}

foreach ($busyFile in $busyFiles) {
    $lockFile = $contestedFiles | Where-Object { $_.FilePath -like "*$([System.IO.Path]::GetFileName($busyFile.FilePath))*" }
    
    if ($lockFile) {
        Write-Host "`n🔥 High Activity + Lock Contention: $($busyFile.FilePath)"
        Write-Host "   Clients: $($busyFile.Clients.Count), Requests: $($busyFile.Requests)"
        Write-Host "   Contested locks: $(($lockFile.Locks | Where-Object { $_.QueuedCount -gt 0 }).Count)"
        Write-Host "   Users waiting: $(($lockFile.Locks | Measure-Object -Property QueuedCount -Sum).Sum)"
        
        # This indicates a potential performance bottleneck
        Write-Host "   ⚠️  Potential performance bottleneck detected" -ForegroundColor Red
    }
}

# Show overall system health
Write-Host "`n=== System Health Summary ==="
Write-Host "Connected clients: $($serverStats.ClientsConnectedNow)"
Write-Host "Active files: $($fileUsage.Files.Count)"
Write-Host "Files with locks: $(($lockInfo | Where-Object { $_.NumberOfLocks -gt 0 }).Count)"
Write-Host "Total lock contention points: $(($lockInfo | ForEach-Object { $_.Locks } | Where-Object { $_.QueuedCount -gt 0 }).Count)"
```

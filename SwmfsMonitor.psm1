function Get-SwmfsMonitorStats {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$InstanceName,
        [Parameter()]
        [string]$ExecutablePath,
        [Parameter()]
        [string[]]$RawOutput
    )

    # Set default executable path based on operating system
    if (-not $ExecutablePath) {
        if ($IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)) {
            # Windows or Windows PowerShell 5.1 and earlier
            $ExecutablePath = "swmfs_monitor.exe"
        } else {
            # Linux/macOS with PowerShell Core
            $ExecutablePath = "swmfs_monitor"
        }
    }

    if ($RawOutput) {
        $output = $RawOutput
    } else {
        $output = & $ExecutablePath $InstanceName
        if (-not $output) {
            throw "No output from swmfs_monitor."
        }
    }

    $stats = @{
        InstanceName = $InstanceName
    }

    foreach ($line in $output) {
        if ($line -match '^Seconds elapsed\s*:\s*real\s*(\d+), user\s*(\d+), kernel\s*(\d+)') {
            $stats.SecondsElapsedReal   = [int]$matches[1]
            $stats.SecondsElapsedUser   = [int]$matches[2]
            $stats.SecondsElapsedKernel = [int]$matches[3]
        }
        elseif ($line -match '^Clients connected\s*:\s*now\s*(\d+), max\s*(\d+), total\s*(\d+)') {
            $stats.ClientsConnectedNow   = [int]$matches[1]
            $stats.ClientsConnectedMax   = [int]$matches[2]
            $stats.ClientsConnectedTotal = [int]$matches[3]
        }
        elseif ($line -match '^Files opened\s*:\s*now\s*(\d+), max\s*(\d+), total\s*(\d+)') {
            $stats.FilesOpenedNow   = [int]$matches[1]
            $stats.FilesOpenedMax   = [int]$matches[2]
            $stats.FilesOpenedTotal = [int]$matches[3]
        }
        elseif ($line -match '^Jobs allocated\s*:\s*total\s*(\d+)') {
            $stats.JobsAllocatedTotal = [int]$matches[1]
        }
        elseif ($line -match '^Reads:\s*(\d+)\s*Writes:\s*(\d+)\s*Flushes:\s*(\d+)') {
            $stats.FileIOReads   = [int]$matches[1]
            $stats.FileIOWrites  = [int]$matches[2]
            $stats.FileIOFlushes = [int]$matches[3]
        }
        elseif ($line -match '^Locks:\s*(\d+)\s*Usages:\s*(\d+)\s*Extends:\s*(\d+)') {
            $stats.FileIOLocks   = [int]$matches[1]
            $stats.FileIOUsages  = [int]$matches[2]
            $stats.FileIOExtends = [int]$matches[3]
        }
        elseif ($line -match '^Read Requests:\s*(\d+)\s*Blocks Requested:\s*(\d+)\s*Blocks Read:\s*(\d+)') {
            $stats.MultiblockIOReadRequests     = [int]$matches[1]
            $stats.MultiblockIOBlocksRequested  = [int]$matches[2]
            $stats.MultiblockIOBlocksRead       = [int]$matches[3]
        }
        elseif ($line -match '^Write Requests:\s*(\d+)\s*Blocks Written:\s*(\d+)\s*Timed out:\s*(\d+)') {
            $stats.MultiblockIOWriteRequests = [int]$matches[1]
            $stats.MultiblockIOBlocksWritten = [int]$matches[2]
            $stats.MultiblockIOTimedOut      = [int]$matches[3]
        }
        elseif ($line -match '^Total:\s*(\d+)\s*Reads:\s*(\d+)\s*Writes:\s*(\d+)\s*Flushes:\s*(\d+)') {
            $stats.AsyncFileIOTotal   = [int]$matches[1]
            $stats.AsyncFileIOReads   = [int]$matches[2]
            $stats.AsyncFileIOWrites  = [int]$matches[3]
            $stats.AsyncFileIOFlushes = [int]$matches[4]
        }
        elseif ($line -match '^Requeued:\s*(\d+)') {
            $stats.AsyncFileIORequeued = [int]$matches[1]
        }
        elseif ($line -match '^Total Allocated:\s*(\d+)\s*In Use:\s*(\d+)\s*Maximum In Use:\s*(\d+)') {
            $stats.AsyncFileIOThreadsAllocated    = [int]$matches[1]
            $stats.AsyncFileIOThreadsInUse        = [int]$matches[2]
            $stats.AsyncFileIOThreadsMaxInUse     = [int]$matches[3]
        }
        elseif ($line -match '^Free List Length:\s*(\d+)\s*Free List Limit:\s*(\d+)') {
            $stats.AsyncFileIOThreadsFreeListLength = [int]$matches[1]
            $stats.AsyncFileIOThreadsFreeListLimit  = [int]$matches[2]
        }
        elseif ($line -match '^Total reconnection requests:\s*(\d+)\s*Resends required:\s*(\d+)') {
            $stats.ReconnectRequests = [int]$matches[1]
            $stats.ReconnectResends  = [int]$matches[2]
        }
        elseif ($line -match '^Total reconnection failures:\s*(\d+)\s*Missing requests:\s*(\d+)') {
            $stats.ReconnectFailures = [int]$matches[1]
            $stats.ReconnectMissing  = [int]$matches[2]
        }
        elseif ($line -match '^Dead links detected by UDP:\s*(\d+)\s*Journal file dead clients:\s*(\d+)') {
            $stats.DeadLinksUDP      = [int]$matches[1]
            $stats.DeadClientsJournal= [int]$matches[2]
        }
        elseif ($line -match '^Keepalive packets sent:\s*(\d+)\s*Keepalive packets received:\s*(\d+)') {
            $stats.KeepaliveSent     = [int]$matches[1]
            $stats.KeepaliveReceived = [int]$matches[2]
        }
        elseif ($line -match '^Ping requests received:\s*(\d+)\s*Keepalive loop delayed:\s*(\d+)') {
            $stats.PingRequestsReceived = [int]$matches[1]
            $stats.KeepaliveLoopDelayed = [int]$matches[2]
        }
        elseif ($line -match '^Total TCP bytes received:\s*(\d+)\s*Total TCP bytes sent:\s*(\d+)') {
            $stats.TCPBytesReceived = [int64]$matches[1]
            $stats.TCPBytesSent     = [int64]$matches[2]
        }
    }

    return [PSCustomObject]$stats
}

Export-ModuleMember -Function Get-SwmfsMonitorStats
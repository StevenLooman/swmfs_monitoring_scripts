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

function Get-SwmfsLockMonitorStats {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ServerOrDirectory,
        [Parameter()]
        [string]$File,
        [Parameter()]
        [string]$ExecutablePath,
        [Parameter()]
        [string[]]$AdditionalArgs,
        [Parameter()]
        [string[]]$RawOutput
    )

    # Set default executable path based on operating system
    if (-not $ExecutablePath) {
        if ($IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)) {
            # Windows or Windows PowerShell 5.1 and earlier
            $ExecutablePath = "swmfs_lock_monitor.exe"
        } else {
            # Linux/macOS with PowerShell Core
            $ExecutablePath = "swmfs_lock_monitor"
        }
    }

    if ($RawOutput) {
        $output = $RawOutput
    } else {
        $args = @()
        if ($ServerOrDirectory) {
            $args += $ServerOrDirectory
        }
        if ($File) {
            $args += $File
        }
        if ($AdditionalArgs) {
            $args += $AdditionalArgs
        }
        
        if ($args.Count -eq 0) {
            throw "Either ServerOrDirectory parameter or RawOutput must be provided."
        }
        
        $output = & $ExecutablePath @args
        if (-not $output) {
            throw "No output from swmfs_lock_monitor."
        }
    }

    $files = @()
    $currentFile = $null
    $currentLock = $null
    $i = 0

    while ($i -lt $output.Count) {
        $line = $output[$i]
        
        # Parse file header line: "File: \\dbserver\D$\admin scratch.ds Number of locks: 1"
        if ($line -match '^File:\s*(.+?)\s*Number of locks:\s*(\d+)') {
            if ($currentFile) {
                $files += $currentFile
            }
            
            $currentFile = [PSCustomObject]@{
                FilePath = $matches[1].Trim()
                NumberOfLocks = [int]$matches[2]
                Locks = @()
            }
            $currentLock = $null
        }
        # Parse lock line: "     79 X    1    0 user1@host1"
        elseif ($line -match '^\s*(\d+)\s+([XN])\s+(\d+)\s+(\d+)(.*)') {
            $lockId = [int]$matches[1]
            $exclusivity = $matches[2]
            $holderCount = [int]$matches[3]
            $queuedCount = [int]$matches[4]
            $usersText = $matches[5].Trim()
            
            $users = @()
            if ($usersText) {
                $users = $usersText -split '\s+' | Where-Object { $_ }
            }
            
            $currentLock = [PSCustomObject]@{
                LockId = $lockId
                Exclusivity = $exclusivity
                ExclusivityDescription = if ($exclusivity -eq 'X') { 'Exclusive' } else { 'Non-Exclusive' }
                HolderCount = $holderCount
                QueuedCount = $queuedCount
                Holders = $users
                QueuedUsers = @()
            }
            
            if ($currentFile) {
                $currentFile.Locks += $currentLock
            }
        }
        # Parse continuation line for users: "                     hatebea5@bideford ilkdbc70@halstead"
        elseif ($line -match '^\s{20,}(.+)' -and $currentLock -and -not ($line -match '^\s*Queued\s')) {
            $usersText = $matches[1].Trim()
            if ($usersText) {
                $additionalUsers = $usersText -split '\s+' | Where-Object { $_ }
                $currentLock.Holders += $additionalUsers
            }
        }
        # Parse queued users line: "         Queued      cleaa63@coleford"
        elseif ($line -match '^\s*Queued\s+(.+)') {
            if ($currentLock) {
                $queuedUsersText = $matches[1].Trim()
                if ($queuedUsersText) {
                    $queuedUsers = $queuedUsersText -split '\s+' | Where-Object { $_ }
                    $currentLock.QueuedUsers += $queuedUsers
                }
            }
        }
        # Parse continuation line for queued users: "                     alc9b56f@portland dar351e0@amersham emsd2b6a@emsworth"
        elseif ($line -match '^\s{20,}(.+)' -and $currentLock -and $currentLock.QueuedUsers.Count -gt 0) {
            $queuedUsersText = $matches[1].Trim()
            if ($queuedUsersText) {
                $additionalQueuedUsers = $queuedUsersText -split '\s+' | Where-Object { $_ }
                $currentLock.QueuedUsers += $additionalQueuedUsers
            }
        }
        
        $i++
    }
    
    # Add the last file if it exists
    if ($currentFile) {
        $files += $currentFile
    }

    return $files
}

function Get-SwmfsListStats {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ServerOrHost,
        [Parameter()]
        [string]$ExecutablePath,
        [Parameter()]
        [string[]]$AdditionalArgs,
        [Parameter()]
        [string[]]$RawOutput
    )

    # Set default executable path based on operating system
    if (-not $ExecutablePath) {
        if ($IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)) {
            # Windows or Windows PowerShell 5.1 and earlier
            $ExecutablePath = "swmfs_list.exe"
        } else {
            # Linux/macOS with PowerShell Core
            $ExecutablePath = "swmfs_list"
        }
    }

    if ($RawOutput) {
        $output = $RawOutput
    } else {
        $args = @("-post_process")
        if ($ServerOrHost) {
            $args += $ServerOrHost
        }
        if ($AdditionalArgs) {
            $args += $AdditionalArgs
        }
        
        $output = & $ExecutablePath @args
        if (-not $output) {
            throw "No output from swmfs_list."
        }
    }

    $result = [PSCustomObject]@{
        ServerName = $null
        ServerTime = $null
        Files = @()
    }

    $currentFile = $null
    $i = 0

    while ($i -lt $output.Count) {
        $line = $output[$i]
        
        # Parse server header line: "Windows server dbserver, Universal time Sat Sep 13 20:31:27 2025."
        if ($line -match '^(Windows|Linux)\s+server\s+(.+?),\s+Universal\s+time\s+(.+)\.$') {
            $result.ServerName = $matches[2].Trim()
            $result.ServerTime = try { 
                [DateTime]::Parse($matches[3]) 
            } catch { 
                $matches[3] 
            }
        }
        # Parse file header line: "File D:\admin dd_extension.ds is running:"
        elseif ($line -match '^File\s+(.+?)\s+is\s+running:$') {
            if ($currentFile) {
                $result.Files += $currentFile
            }
            
            $currentFile = [PSCustomObject]@{
                FilePath = $matches[1].Trim()
                ThreadId = $null
                Time = $null
                CPUTime = $null
                Requests = $null
                Clients = @()
            }
        }
        # Parse file thread info line: "Thread id 5460, Time 172384, CPU time 0s, Requests 12467."
        elseif ($line -match '^Thread\s+id\s+(\d+),\s+Time\s+(\d+),\s+CPU\s+time\s+(\d+)s,\s+Requests\s+(\d+)\.') {
            if ($currentFile) {
                $currentFile.ThreadId = [int]$matches[1]
                $currentFile.Time = [int]$matches[2]
                $currentFile.CPUTime = [int]$matches[3]
                $currentFile.Requests = [int]$matches[4]
            }
        }
        # Parse client data line: "818728898,user1@host1,171887,444,323,0,0,0,2,idle"
        elseif ($line -match '^(\d+),([^,]+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(.+)$') {
            if ($currentFile) {
                $client = [PSCustomObject]@{
                    ClientId = [int64]$matches[1]
                    ClientName = $matches[2].Trim()
                    Time = [int]$matches[3]
                    Requests = [int]$matches[4]
                    Reads = [int]$matches[5]
                    Extends = [int]$matches[6]
                    Flushes = [int]$matches[7]
                    Locks = [int]$matches[8]
                    State = [int]$matches[9]
                    Status = $matches[10].Trim()
                }
                $currentFile.Clients += $client
            }
        }
        
        $i++
    }
    
    # Add the last file if it exists
    if ($currentFile) {
        $result.Files += $currentFile
    }

    return $result
}

Export-ModuleMember -Function Get-SwmfsMonitorStats, Get-SwmfsLockMonitorStats, Get-SwmfsListStats
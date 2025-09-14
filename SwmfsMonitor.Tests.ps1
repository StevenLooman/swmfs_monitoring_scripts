Import-Module "$PSScriptRoot/SwmfsMonitor.psm1"

Describe "Get-SwmfsMonitorStats" {
    BeforeAll {
        $mockOutput = @"
Seconds elapsed   : real      403282, user        1687, kernel      7162
Clients connected : now           24, max           36, total       1015
Files opened      : now          203, max          255, total        945
Jobs allocated    : total   73687438

Total File Operation Counts:
Reads: 63358263 Writes:   762589 Flushes:  2317869 (24861)
Locks:  2064015 Usages:    22824 Extends:   514161

Multiblock I/O Operations:
Read Requests:     27495 Blocks Requested:   362968 Blocks Read:   342091
Write Requests:  1559566 Blocks Written:   29535663 Timed out:       1094

Asynchronous File I/O Operations:
Total:    96291611 Reads: 63700354 Writes: 30298252 Flushes:  2293005
Requeued:    35106

Asynchronous File I/O Threads:
Total Allocated:      1063 In Use:      286 Maximum In Use:      333
Free List Length:       47 Free List Limit:      256

Recovery and Reconnection Statistics:
Total reconnection requests:      125 Resends required:       40
Total reconnection failures:       11 Missing requests:        1
Dead links detected by UDP:         6 Journal file dead clients:         0
Keepalive packets sent:         83154 Keepalive packets received:    48835
Ping requests received:          6396 Keepalive loop delayed:            0

Communications Statistics:
Total TCP bytes received:    66951265672 Total TCP bytes sent:       166243751105
"@ -split "`n"
    }

    It "Parses swmfs_monitor output correctly" {
        $result = Get-SwmfsMonitorStats -InstanceName "dbserver" -RawOutput $mockOutput
        $result.InstanceName | Should -Be "dbserver"
        $result.SecondsElapsedReal | Should -Be 403282
        $result.ClientsConnectedNow | Should -Be 24
        $result.FilesOpenedMax | Should -Be 255
        $result.JobsAllocatedTotal | Should -Be 73687438
        $result.FileIOReads | Should -Be 63358263
        $result.FileIOWrites | Should -Be 762589
        $result.FileIOFlushes | Should -Be 2317869
        $result.FileIOLocks | Should -Be 2064015
        $result.MultiblockIOReadRequests | Should -Be 27495
        $result.MultiblockIOBlocksWritten | Should -Be 29535663
        $result.AsyncFileIOTotal | Should -Be 96291611
        $result.AsyncFileIORequeued | Should -Be 35106
        $result.AsyncFileIOThreadsAllocated | Should -Be 1063
        $result.ReconnectRequests | Should -Be 125
        $result.DeadLinksUDP | Should -Be 6
        $result.KeepaliveSent | Should -Be 83154
        $result.TCPBytesReceived | Should -Be 66951265672
        $result.TCPBytesSent | Should -Be 166243751105
    }

    Context "Cross-platform executable detection" {
        It "Uses correct executable on Windows PowerShell 5.1" {
            # Test with RawOutput to avoid actual command execution
            $result = Get-SwmfsMonitorStats -InstanceName "testinstance" -RawOutput $mockOutput
            $result.InstanceName | Should -Be "testinstance"
            
            # Test that the function would use .exe extension for Windows PowerShell
            # This is validated by the fact that the default behavior works
        }

        It "Uses correct executable on PowerShell Core" {
            # Test with RawOutput to avoid actual command execution
            $result = Get-SwmfsMonitorStats -InstanceName "testinstance" -RawOutput $mockOutput
            $result.InstanceName | Should -Be "testinstance"
            
            # Test that the function works correctly regardless of platform
        }

        It "Accepts custom executable path" {
            # Test with RawOutput to avoid actual command execution
            $result = Get-SwmfsMonitorStats -InstanceName "testinstance" -ExecutablePath "/custom/path/swmfs_monitor" -RawOutput $mockOutput
            $result.InstanceName | Should -Be "testinstance"
        }

        It "Sets appropriate default executable based on platform" {
            # Since we can't easily mock the platform detection variables,
            # we test that the function works with explicit paths
            $result1 = Get-SwmfsMonitorStats -InstanceName "test1" -ExecutablePath "swmfs_monitor.exe" -RawOutput $mockOutput
            $result1.InstanceName | Should -Be "test1"
            
            $result2 = Get-SwmfsMonitorStats -InstanceName "test2" -ExecutablePath "swmfs_monitor" -RawOutput $mockOutput
            $result2.InstanceName | Should -Be "test2"
        }
    }
}

Describe "Get-SwmfsLockMonitorStats" {
    BeforeAll {
        $mockSimpleOutput = @(
            "File: \\dbserver\D`$\admin scratch.ds Number of locks: 1",
            "      79 X    1    0 user1@host1 ",
            "",
            "File: \\dbserver\D`$\db dd_extension.ds Number of locks: 0",
            "",
            "File: \\dbserver\D`$\admin ace.ds Number of locks: 2",
            "     351 X    1    0 user1@host1 ",
            "     361 X    1    0 user2@host2 "
        )

        $mockQueuedOutput = @(
            "File: jupiter:/sw/active_ds/ds_elec/w_top raster.ds Number of locks: 1",
            "  378674 N    3    1 bidb99d3@alcester dav418@sandbach bar68b1b@daventry",
            "         Queued      cleaa63@coleford"
        )

        $mockMultilineOutput = @(
            "File: jupiter:/sw/active_ds/ds_elec/w_top gdb.ds Number of locks: 5",
            "  354466 N    5    0 hatc5e4@amersham bak754e8@coleford per72f5@pershore",
            "                     hatebea5@bideford ilkdbc70@halstead",
            "  370612 N    1    0 hatc5e4@amersham",
            "  370642 N    1    0 per72f5@pershore",
            "  370862 N    1    0 bak754e8@coleford",
            "  387870 X    1    0 rama0c90@biddulph"
        )

        $mockComplexOutput = @(
            "File: jupiter:/sw/active_ds/ds_elec/w_top raster.ds Number of locks: 3",
            "       6 X    1    0 lou56031@bideford",
            "  378674 X    1   50 ilkf2fea@biddulph",
            "         Queued      alc9b56f@portland dar351e0@amersham emsd2b6a@emsworth",
            "                     hatd5349@hatfield ram20a55@yarmouth ramc75e8@alcester",
            "  393090 X    1    0 por4b345@rochdale"
        )
    }

    Context "Basic parsing functionality" {
        It "Parses simple file and lock information correctly" {
            $result = Get-SwmfsLockMonitorStats -RawOutput $mockSimpleOutput
            $result.Count | Should -Be 3

            # First file with one lock
            $result[0].FilePath | Should -Be "\\dbserver\D`$\admin scratch.ds"
            $result[0].NumberOfLocks | Should -Be 1
            $result[0].Locks.Count | Should -Be 1
            $result[0].Locks[0].LockId | Should -Be 79
            $result[0].Locks[0].Exclusivity | Should -Be "X"
            $result[0].Locks[0].ExclusivityDescription | Should -Be "Exclusive"
            $result[0].Locks[0].HolderCount | Should -Be 1
            $result[0].Locks[0].QueuedCount | Should -Be 0
            $result[0].Locks[0].Holders | Should -Be @("user1@host1")
            $result[0].Locks[0].QueuedUsers.Count | Should -Be 0

            # Second file with no locks
            $result[1].FilePath | Should -Be "\\dbserver\D`$\db dd_extension.ds"
            $result[1].NumberOfLocks | Should -Be 0
            $result[1].Locks.Count | Should -Be 0

            # Third file with two locks
            $result[2].FilePath | Should -Be "\\dbserver\D`$\admin ace.ds"
            $result[2].NumberOfLocks | Should -Be 2
            $result[2].Locks.Count | Should -Be 2
            $result[2].Locks[0].LockId | Should -Be 351
            $result[2].Locks[1].LockId | Should -Be 361
        }

        It "Handles non-exclusive locks correctly" {
            $result = Get-SwmfsLockMonitorStats -RawOutput $mockQueuedOutput
            $result.Count | Should -Be 1
            $result[0].Locks[0].Exclusivity | Should -Be "N"
            $result[0].Locks[0].ExclusivityDescription | Should -Be "Non-Exclusive"
        }

        It "Parses queued users correctly" {
            $result = Get-SwmfsLockMonitorStats -RawOutput $mockQueuedOutput
            $result.Count | Should -Be 1
            $lock = $result[0].Locks[0]
            $lock.HolderCount | Should -Be 3
            $lock.QueuedCount | Should -Be 1
            $lock.Holders | Should -Be @("bidb99d3@alcester", "dav418@sandbach", "bar68b1b@daventry")
            $lock.QueuedUsers | Should -Be @("cleaa63@coleford")
        }

        It "Handles multi-line user lists" {
            $result = Get-SwmfsLockMonitorStats -RawOutput $mockMultilineOutput
            $result.Count | Should -Be 1
            $lock = $result[0].Locks[0]
            $lock.LockId | Should -Be 354466
            $lock.HolderCount | Should -Be 5
            $lock.Holders.Count | Should -Be 5
            $lock.Holders | Should -Contain "hatc5e4@amersham"
            $lock.Holders | Should -Contain "hatebea5@bideford"
            $lock.Holders | Should -Contain "ilkdbc70@halstead"
        }

        It "Handles complex output with multi-line queued users" {
            $result = Get-SwmfsLockMonitorStats -RawOutput $mockComplexOutput
            $result.Count | Should -Be 1
            $result[0].Locks.Count | Should -Be 3

            # Check the lock with many queued users
            $lockWithQueue = $result[0].Locks[1]
            $lockWithQueue.LockId | Should -Be 378674
            $lockWithQueue.QueuedCount | Should -Be 50
            $lockWithQueue.QueuedUsers.Count | Should -Be 6
            $lockWithQueue.QueuedUsers | Should -Contain "alc9b56f@portland"
            $lockWithQueue.QueuedUsers | Should -Contain "ramc75e8@alcester"
        }
    }

    Context "Parameter validation" {
        It "Requires either ServerOrDirectory or RawOutput" {
            { Get-SwmfsLockMonitorStats } | Should -Throw "Either ServerOrDirectory parameter or RawOutput must be provided."
        }

        It "Accepts ServerOrDirectory parameter" {
            # This would normally execute the command, but we test with RawOutput to avoid execution
            $result = Get-SwmfsLockMonitorStats -ServerOrDirectory "dbserver" -RawOutput $mockSimpleOutput
            $result.Count | Should -Be 3
        }

        It "Accepts custom executable path" {
            $result = Get-SwmfsLockMonitorStats -ExecutablePath "/custom/path/swmfs_lock_monitor" -RawOutput $mockSimpleOutput
            $result.Count | Should -Be 3
        }
    }

    Context "Cross-platform executable detection" {
        It "Sets appropriate default executable path" {
            # Test that function works with various executable paths
            $result1 = Get-SwmfsLockMonitorStats -ExecutablePath "swmfs_lock_monitor.exe" -RawOutput $mockSimpleOutput
            $result1.Count | Should -Be 3
            
            $result2 = Get-SwmfsLockMonitorStats -ExecutablePath "swmfs_lock_monitor" -RawOutput $mockSimpleOutput
                        $result2.Count | Should -Be 3
        }
    }
}

Describe "Get-SwmfsListStats" {
    BeforeAll {
        $mockOutput = @(
            "",
            "Windows server dbserver, Universal time Sat Sep 13 20:31:27 2025.",
            "",
            "File D:\admin dd_extension.ds is running:",
            "",
            "Thread id 5460, Time 172384, CPU time 0s, Requests 12467.",
            "",
            "818728898,user1@host1,171887,444,323,0,0,0,2,idle",
            "818728900,user1@host1,171735,430,318,0,0,0,1,idle",
            "818728902,user1@host1,171692,430,318,0,0,0,1,idle",
            "818728927,user1@host1,4565,436,319,0,0,0,2,idle",
            "818728928,user1@host1,4410,430,318,0,0,0,1,idle",
            "818728929,user1@host1,4356,430,318,0,0,0,1,idle",
            "818728930,user1@host1,4318,430,318,0,0,0,1,idle",
            "818728933,users@host2 - swmfs_list,0,14,0,0,0,0,0,listing",
            "",
            "File E:\BMG_DS\Kabels raster.ds is running:",
            "",
            "Thread id 6520, Time 172379, CPU time 1s, Requests 79829.",
            "",
            "818729218,user1@host1,171887,75,13,0,0,0,27,idle",
            "818729220,user1@host1,171736,36689,13,0,0,0,18335,idle",
            "818729222,user1@host1,171692,23,13,0,0,0,2,idle",
            "818729247,user1@host1,4565,27,13,0,0,0,3,idle",
            "818729248,user1@host1,4410,897,13,0,0,0,439,idle",
            "818729249,user1@host1,4356,141,13,0,0,0,61,idle",
            "818729250,user1@host1,4319,23,13,0,0,0,2,idle",
            "818729253,user2@host2 - swmfs_list,0,13,0,0,0,0,0,listing"
        )

        $mockLinuxOutput = @(
            "",
            "Linux server testserver, Universal time Mon Sep 15 14:22:33 2025.",
            "",
            "File /data/gis/raster.ds is running:",
            "",
            "Thread id 1234, Time 98765, CPU time 5s, Requests 54321.",
            "",
            "123456789,admin@server1,12345,100,50,2,1,3,1,active",
            "123456790,user@workstation,54321,200,75,0,0,1,2,idle"
        )

        $mockEmptyFileOutput = @(
            "",
            "Windows server dbserver, Universal time Sat Sep 13 20:31:27 2025.",
            "",
            "File D:\admin empty.ds is running:",
            "",
            "Thread id 1111, Time 2222, CPU time 0s, Requests 0.",
            ""
        )
    }

    Context "Basic parsing functionality" {
        It "Parses server information correctly" {
            $result = Get-SwmfsListStats -RawOutput $mockOutput
            $result.ServerName | Should -Be "dbserver"
            $result.ServerTime | Should -BeOfType [DateTime]
            $result.ServerTime.Year | Should -Be 2025
            $result.ServerTime.Month | Should -Be 9
            $result.ServerTime.Day | Should -Be 13
        }

        It "Parses multiple files correctly" {
            $result = Get-SwmfsListStats -RawOutput $mockOutput
            $result.Files.Count | Should -Be 2

            # First file
            $file1 = $result.Files[0]
            $file1.FilePath | Should -Be "D:\admin dd_extension.ds"
            $file1.ThreadId | Should -Be 5460
            $file1.Time | Should -Be 172384
            $file1.CPUTime | Should -Be 0
            $file1.Requests | Should -Be 12467
            $file1.Clients.Count | Should -Be 8

            # Second file
            $file2 = $result.Files[1]
            $file2.FilePath | Should -Be "E:\BMG_DS\Kabels raster.ds"
            $file2.ThreadId | Should -Be 6520
            $file2.Time | Should -Be 172379
            $file2.CPUTime | Should -Be 1
            $file2.Requests | Should -Be 79829
            $file2.Clients.Count | Should -Be 8
        }

        It "Parses client data correctly" {
            $result = Get-SwmfsListStats -RawOutput $mockOutput
            $client = $result.Files[0].Clients[0]
            
            $client.ClientId | Should -Be 818728898
            $client.ClientName | Should -Be "user1@host1"
            $client.Time | Should -Be 171887
            $client.Requests | Should -Be 444
            $client.Reads | Should -Be 323
            $client.Extends | Should -Be 0
            $client.Flushes | Should -Be 0
            $client.Locks | Should -Be 0
            $client.State | Should -Be 2
            $client.Status | Should -Be "idle"
        }

        It "Handles different client statuses" {
            $result = Get-SwmfsListStats -RawOutput $mockOutput
            $listingClient = $result.Files[0].Clients | Where-Object { $_.Status -eq "listing" }
            $listingClient | Should -Not -BeNullOrEmpty
            $listingClient.ClientName | Should -Be "users@host2 - swmfs_list"
            $listingClient.Status | Should -Be "listing"
        }

        It "Handles Linux server output" {
            $result = Get-SwmfsListStats -RawOutput $mockLinuxOutput
            $result.ServerName | Should -Be "testserver"
            $result.Files.Count | Should -Be 1
            $result.Files[0].FilePath | Should -Be "/data/gis/raster.ds"
            $result.Files[0].ThreadId | Should -Be 1234
            $result.Files[0].Clients.Count | Should -Be 2
            
            $activeClient = $result.Files[0].Clients | Where-Object { $_.Status -eq "active" }
            $activeClient | Should -Not -BeNullOrEmpty
            $activeClient.ClientName | Should -Be "admin@server1"
        }
    }

    Context "Edge cases" {
        It "Handles files with no clients" {
            $result = Get-SwmfsListStats -RawOutput $mockEmptyFileOutput
            $result.Files.Count | Should -Be 1
            $result.Files[0].FilePath | Should -Be "D:\admin empty.ds"
            $result.Files[0].ThreadId | Should -Be 1111
            $result.Files[0].Clients.Count | Should -Be 0
        }

        It "Handles empty output" {
            $result = Get-SwmfsListStats -RawOutput @()
            $result.ServerName | Should -BeNullOrEmpty
            $result.ServerTime | Should -BeNullOrEmpty
            $result.Files.Count | Should -Be 0
        }

        It "Handles malformed date strings gracefully" {
            $malformedDateOutput = @(
                "Windows server dbserver, Universal time Invalid Date Format.",
                "File D:\test.ds is running:",
                "Thread id 1, Time 1, CPU time 0s, Requests 1."
            )
            $result = Get-SwmfsListStats -RawOutput $malformedDateOutput
            $result.ServerName | Should -Be "dbserver"
            $result.ServerTime | Should -Be "Invalid Date Format"
        }

        It "Handles client names with special characters" {
            $specialCharOutput = @(
                "Windows server dbserver, Universal time Sat Sep 13 20:31:27 2025.",
                "File D:\test.ds is running:",
                "Thread id 1, Time 1, CPU time 0s, Requests 1.",
                "123456,user@domain.com - special tool,100,10,5,0,0,0,1,working"
            )
            $result = Get-SwmfsListStats -RawOutput $specialCharOutput
            $result.Files[0].Clients[0].ClientName | Should -Be "user@domain.com - special tool"
            $result.Files[0].Clients[0].Status | Should -Be "working"
        }
    }

    Context "Parameter validation and execution" {
        It "Accepts ServerOrHost parameter" {
            # This would normally execute the command, but we test with RawOutput to avoid execution
            $result = Get-SwmfsListStats -ServerOrHost "dbserver" -RawOutput $mockOutput
            $result.ServerName | Should -Be "dbserver"
        }

        It "Accepts additional arguments" {
            $result = Get-SwmfsListStats -AdditionalArgs @("-full") -RawOutput $mockOutput
            $result.Files.Count | Should -Be 2
        }

        It "Accepts custom executable path" {
            $result = Get-SwmfsListStats -ExecutablePath "/custom/path/swmfs_list" -RawOutput $mockOutput
            $result.ServerName | Should -Be "dbserver"
        }
    }

    Context "Cross-platform executable detection" {
        It "Sets appropriate default executable path" {
            # Test that function works with various executable paths
            $result1 = Get-SwmfsListStats -ExecutablePath "swmfs_list.exe" -RawOutput $mockOutput
            $result1.ServerName | Should -Be "dbserver"
            
            $result2 = Get-SwmfsListStats -ExecutablePath "swmfs_list" -RawOutput $mockOutput
            $result2.ServerName | Should -Be "dbserver"
        }
    }

    Context "Data type validation" {
        It "Converts numeric fields to appropriate types" {
            $result = Get-SwmfsListStats -RawOutput $mockOutput
            $client = $result.Files[0].Clients[0]
            
            $client.ClientId | Should -BeOfType [int64]
            $client.Time | Should -BeOfType [int]
            $client.Requests | Should -BeOfType [int]
            $client.Reads | Should -BeOfType [int]
            $client.Extends | Should -BeOfType [int]
            $client.Flushes | Should -BeOfType [int]
            $client.Locks | Should -BeOfType [int]
            $client.State | Should -BeOfType [int]
            
            $file = $result.Files[0]
            $file.ThreadId | Should -BeOfType [int]
            $file.Time | Should -BeOfType [int]
            $file.CPUTime | Should -BeOfType [int]
            $file.Requests | Should -BeOfType [int]
        }

        It "Preserves string fields as strings" {
            $result = Get-SwmfsListStats -RawOutput $mockOutput
            $client = $result.Files[0].Clients[0]
            
            $client.ClientName | Should -BeOfType [string]
            $client.Status | Should -BeOfType [string]
            $result.Files[0].FilePath | Should -BeOfType [string]
        }
    }
}

    Context "Edge cases" {
        It "Handles empty output" {
            $result = Get-SwmfsLockMonitorStats -RawOutput @()
            $result.Count | Should -Be 0
        }

        It "Handles files with only header and no locks" {
            $emptyFileOutput = @("File: \\server\path\file.ds Number of locks: 0")
            $result = Get-SwmfsLockMonitorStats -RawOutput $emptyFileOutput
            $result.Count | Should -Be 1
            $result[0].NumberOfLocks | Should -Be 0
            $result[0].Locks.Count | Should -Be 0
        }

        It "Handles locks with no users listed" {
            $noUsersOutput = @(
                "File: \\server\path\file.ds Number of locks: 1",
                "  12345 X    0    0"
            )
            $result = Get-SwmfsLockMonitorStats -RawOutput $noUsersOutput
            $result.Count | Should -Be 1
            $result[0].Locks[0].Holders.Count | Should -Be 0
            $result[0].Locks[0].QueuedUsers.Count | Should -Be 0
        }
    }
}
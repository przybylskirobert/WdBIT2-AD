Throw "this is not a robust file" 
$location = Get-Location
$ScriptsLocation =  "C:\WdBIT2-AD\Other Scripts"
Set-Location $ScriptsLocation
Import-Module ActiveDirectory

#region import GPO
    $backupPath = "$ScriptsLocation\GPO Backup"
    $migTable = "gpo_backup_" + $((Get-ADDOmain).NetBIOSName) + ".migtable"
    $migTablePath = "$ScriptsLocation\Scripts\" + $migTable
    Copy-Item -Path $ScriptsLocation\Scripts\gpo_backup.migtable -Destination $migTablePath
    ((Get-Content -path $migTablePath  -Raw) -replace 'CHANGEME', $dnsRoot )| Set-Content -Path $migTablePath 
    $gPOMigrationTable = (Get-ChildItem -Path "$ScriptsLocation\Scripts\" -Filter "$migTable").fullname
    .$ScriptsLocation\Scripts\Import-GPO.ps1 -BackupPath $backupPath -GPOMigrationTable $gPOMigrationTable -Verbose
#endregion

#region Link Restricted Admin Mode gpo
    $GpoLinks = @(
        $(New-Object PSObject -Property @{ Name = "Restricted Admin Mode" ; OU = "OU=Domain Controllers"; Order = 1 ; LinkEnabled = 'YES' }),
        $(New-Object PSObject -Property @{ Name = "Restricted Admin Mode" ; OU = "OU=Devices,OU=Tier0,OU=Admin"; Order = 1 ; LinkEnabled = 'YES' }),
        $(New-Object PSObject -Property @{ Name = "Restricted Admin Mode" ; OU = "OU=Devices,OU=Tier1,OU=Admin"; Order = 1 ; LinkEnabled = 'YES' }),
        $(New-Object PSObject -Property @{ Name = "Restricted Admin Mode" ; OU = "OU=Devices,OU=Tier2,OU=Admin"; Order = 1 ; LinkEnabled = 'YES' }),
        $(New-Object PSObject -Property @{ Name = "Restricted Admin Mode" ; OU = "OU=Tier0 Servers,OU=Tier0,OU=Admin"; Order = 1 ; LinkEnabled = 'YES' }),
        $(New-Object PSObject -Property @{ Name = "Restricted Admin Mode" ; OU = "OU=Tier 1 Servers"; Order = 1 ; LinkEnabled = 'YES' })
    )
    .$ScriptsLocation\Scripts\Link-GpoToOU.ps1 -GpoLinks $GpoLinks -Verbose
    Set-Location $location
#endregion

#region Link Shutdown DC by specific users gpo
$GpoLinks = @(
    $(New-Object PSObject -Property @{ Name = "Shutdown DC by specific users" ; OU = "OU=Domain Controllers"; Order = 1 ; LinkEnabled = 'YES' })
)
.$ScriptsLocation\Scripts\Link-GpoToOU.ps1 -GpoLinks $GpoLinks -Verbose
Set-Location $location
#endregion

#region Link Disable PrintSpooler service gpo
$GpoLinks = @(
    $(New-Object PSObject -Property @{ Name = "Disable PrintSpooler service" ; OU = "OU=Domain Controllers"; Order = 1 ; LinkEnabled = 'YES' })
)
.$ScriptsLocation\Scripts\Link-GpoToOU.ps1 -GpoLinks $GpoLinks -Verbose
Set-Location $location
#endregion

#region Enable RecycleBin
.$ScriptsLocation\Scripts\Set-MAchineAccountQuota.ps1 -Value 0 -Verbose
#endregion

#region Clean Admins groups
.$ScriptsLocation\Scripts\Remove-GroupMembers.ps1 -GroupName 'SChema Admins' -Verbose
.$ScriptsLocation\Scripts\Remove-GroupMembers.ps1 -GroupName 'DNSAdmins' -Verbose
#endregion

#region AccountCouldNotBeDelegated
.$ScriptsLocation\Scripts\Set-AccountCannotBeDelegated.ps1 -OU 'OU=Accounts,OU=Tier0,OU=Admin' -Verbose 
#endregion
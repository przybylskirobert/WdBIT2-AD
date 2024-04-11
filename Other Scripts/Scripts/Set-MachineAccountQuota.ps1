<#
    .Example
    .\Set-MAchineAccountQuota.ps1 -Value 0 -Verbose
    PS C:\Tools> .\Set-MAchineAccountQuota.ps1 -Value 0 -Verbose
    VERBOSE: Changing value of the ms-DS-MachineAccountQuota from '10' to '0'
#>

[CmdletBinding()]
param(
    [parameter(Mandatory = $true)][string] $Value
)

$oldQuota = (Get-ADObject -Identity ((Get-ADDomain).distinguishedname)  -Properties ms-DS-MachineAccountQuota)."ms-DS-MachineAccountQuota"

Write-Host "Changing value of the ms-DS-MachineAccountQuota from '$oldQuota' to '$Value'" -ForegroundColor Green
Write-Verbose 'Set-ADDomain -Identity (Get-ADDomain).distinguishedname -Replace @{"ms-DS-MachineAccountQuota"="$Value"}'
Set-ADDomain -Identity (Get-ADDomain).distinguishedname -Replace @{"ms-DS-MachineAccountQuota"="$Value"}
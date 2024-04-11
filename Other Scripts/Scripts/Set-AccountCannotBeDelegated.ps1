<#
    .Example
    \Set-AccountCannotBeDelegated.ps1 -OU 'OU=Accounts,OU=Tier0,OU=Admin' -Verbose 
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)][string] $OU     
)

Import-Module ActiveDirectory
$dn = (get-addomain).DistinguishedName

$searchBase = $OU + ',' + $dn

$users = Get-ADUser -SearchBase $searchBase -filter *
foreach ($user in $users){
    Write-Host "Configuring AccountNotDelegated flag with value '$true' on user '$($user.samaccountname)'" -ForegroundColor Green
    Write-Verbose 'Set-ADUser $user -AccountNotDelegated $true'
    Set-ADUser $user -AccountNotDelegated $true
}
<#
    .Example
        .\Remove-GroupMembers.ps1 -GroupName "Schema Admins" -Verbose
        VERBOSE: Actuall 'Schema Admins' group members are:

        Name  DistinguishedName                          
        ----  -----------------                          
        domop CN=domop,CN=Users,DC=mvp,DC=azureblog,DC=pl


        VERBOSE: Cleaning 'Schema Admins' group from members.
#>

[CmdletBinding()]
param(
    [parameter(Mandatory = $true)][string] $GroupName
)

$admins = Get-ADGroupMember -Identity $GroupName

Write-Host "Actuall '$GroupName' group members are:" -ForegroundColor Green
$admins| ft Name,DistinguishedName

Write-Host "Cleaning '$GroupName' group from members." -ForegroundColor Green
foreach ($admin in $admins){
    Write-Verbose 'Remove-ADGroupMember -Identity $GroupName -Members $admin.samaccountname -Confirm:$false'
    Remove-ADGroupMember -Identity $GroupName -Members $admin.samaccountname -Confirm:$false
}
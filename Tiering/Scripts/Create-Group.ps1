<#
    .Example
    $csv = Read-Host -Prompt "Please provide full path to Groups csv file"
    .\Create-Group.ps1 List $csv -Verbose
    PS C:\Tools> $csv = Read-Host -Prompt "Please provide full path to Groups csv file"
    Please provide full path to Groups csv file: c:\tools\groups.csv
    PS C:\Tools> .\Create-Group.ps1 List $csv -Verbose
    VERBOSE: Creating new Group 'Tier0ReplicationMaintenance' under 'OU=Groups,OU=Tier0,OU=Admin,DC=azureblog,DC=pl'
    VERBOSE: Creating new Group 'Tier1ServerMaintenance' under 'OU=Groups,OU=Tier1,OU=Admin,DC=azureblog,DC=pl'
    VERBOSE: Creating new Group 'ServiceDeskOperators' under 'OU=Groups,OU=Tier2,OU=Admin,DC=azureblog,DC=pl'
    VERBOSE: Creating new Group 'WorkstationMaintenance' under 'OU=Groups,OU=Tier2,OU=Admin,DC=azureblog,DC=pl'
    VERBOSE: Group 'tier1admins'already exists.
    VERBOSE: Group 'tier2admins'already exists.
#>

[CmdletBinding()]
param(
        [parameter(Mandatory = $true)][PSOBject] $List
)
$dNC = (Get-ADRootDSE).defaultNamingContext
if ($List -like "*csv*") {
    if (Test-Path -Path $List){
        Write-Host "Working with CSV File '$List'" -ForegroundColor Green
        $groups = Import-CSV -Path $List
    }
}

foreach ($group in $groups) {
    $groupName = $group.Name
    $groupOUPrefix = $group.OU
    $destOU = $group.OU + "," + $dNC
    $groupDN = "CN=" + $groupName + "," + $destOU
    $checkForGroup = Get-ADGroup -filter 'Name -eq $groupName' -ErrorAction SilentlyContinue
    If ($checkForGroup.count -eq 0 ) {
        Write-Host "Creating new Group '$($Group.samAccountName)' under '$destOU'" -ForegroundColor Green
        Write-Verbose 'New-ADGroup -Name $Group.Name -SamAccountName $Group.samAccountName -GroupCategory $Group.GroupCategory -GroupScope $Group.GroupScope -DisplayName $Group.DisplayName -Path $destOU -Description $Group.Description'
        New-ADGroup -Name $Group.Name -SamAccountName $Group.samAccountName -GroupCategory $Group.GroupCategory -GroupScope $Group.GroupScope -DisplayName $Group.DisplayName -Path $destOU -Description $Group.Description
        If ($Group.Membership -ne "") {
            Write-Host "Adding Group Membership '$($Group.Membership)' for group '$($Group.samAccountName)'" -foreground Green
            Write-Verbose 'Add-ADPrincipalGroupMembership -Identity $Group.samAccountName -MemberOf $Group.Membership'
            Add-ADPrincipalGroupMembership -Identity $Group.samAccountName -MemberOf $Group.Membership
        }
        $error.Clear()
    } 
    Else {
        Write-Host "Group '$($Group.samAccountName)'already exists." -ForegroundColor Yellow
    }
}

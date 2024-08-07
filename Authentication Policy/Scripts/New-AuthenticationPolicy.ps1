param (
    [string] $PolicyName,
    [string] $ComputersGroupName,
    [string] $UsersGroupName,
    [string[]] $OUsToInclude,
    [switch] $BGAConfig = $false,
    [int] $UserTGTLifetimeMins = 121,
    [string] $Description = "Assigned principals can authenticate to specific resources"

)

$dsnAME = (Get-ADDomain).distinguishedname

if ($BGAConfig -ne $true){
    $taskName = "Update_group_$($ComputersGroupName)_with_Computers"
    $argument = "-NoProfile -command " + '"$OUs = @(' + "'" + $OUsToInclude[0] + "," + $dsnAME + "'" + ",'" + $OUsToInclude[1] + "," + $dsnAME + "')" +  '; $OUs | foreach { Get-ADComputer -Filter * -SearchBase $_} | ForEach-Object {Add-ADGroupMember -Identity ' + $ComputersGroupName + ' -Members $_.SamAccountName}' + '"'
    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $argument
    $trigger =  New-ScheduledTaskTrigger -Daily -At 12am 
    $STPrin = New-ScheduledTaskPrincipal -GroupId "System" -RunLevel Highest
    Write-Host "Creating Scheduled task '$taskName' to update group '$ComputersGroupName' with objects from the following OUs: '$OUsToInclude[0]', '$OUsToInclude[1]'" -ForegroundColor Green
    Write-Verbose 'Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $STPrin -Description "Update group $ComputersGroupName with objects from Ous: $OUsToInclude[0], $OUsToInclude[1]"'
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $STPrin -Description "Update group '$ComputersGroupName' with objects from Ous: '$OUsToInclude[0]', '$OUsToInclude[1]'"
    Get-ScheduledTask -TaskName $taskName | Start-ScheduledTask
}

Write-Host "Creating new AuthenticationPolicy '$PolicyName' with UserTGTLifetimeMins '$UserTGTLifetimeMins'" -ForegroundColor Green
Write-Verbose 'New-ADAuthenticationPolicy -Name $PolicyName -Description $Description  -UserTGTLifetimeMins $UserTGTLifetimeMins -ProtectedFromAccidentalDeletion $true -Enforce'
New-ADAuthenticationPolicy -Name $PolicyName -Description $Description  -UserTGTLifetimeMins $UserTGTLifetimeMins -ProtectedFromAccidentalDeletion $true -Enforce
$sids = @()
Get-ADGroupMember -Identity $ComputersGroupName | ForEach-Object {
    $sid = $_.SID.value
    $sids += "SID($sid)"
}
if (($sids | Measure-Object).count -gt 1){$sidsj = $sids -join ", "}else{$sidsj = $sids}

Write-Host  "Adding members from group '$ComputersGroupName' to User Sign On section under Authentication Policy '$PolicyName'" -ForegroundColor Green
Write-Verbose '$userAllowedToAuthenticateFrom = "O:SYG:SYD:(XA;OICI;CR;;;WD;(Member_of_any {" + $sidsj + "}))"'
$userAllowedToAuthenticateFrom = "O:SYG:SYD:(XA;OICI;CR;;;WD;(Member_of_any {" + $sidsj + "}))"
Write-Verbose 'Set-ADAuthenticationPolicy -Identity $PolicyName -UserAllowedToAuthenticateFrom  $userAllowedToAuthenticateFrom'
Set-ADAuthenticationPolicy -Identity $PolicyName -UserAllowedToAuthenticateFrom  $userAllowedToAuthenticateFrom
Get-ADAuthenticationPolicy -Identity $PolicyName | Set-ADAuthenticationPolicy -Enforce $false

$taskName = "Update_AuthPolicy_$($PolicyName)_with_Users"
$argument = "-NoProfile -command " + '"' + "& Get-ADGroupMember -Recursive -Identity " + "'" + $UsersGroupName + "'" + "| ForEach-Object {Set-ADAccountAuthenticationPolicySilo -AuthenticationPolicy " + $PolicyName + " -Identity " + '$_' + ".SamAccountName}" + '"'
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $argument
$trigger =  New-ScheduledTaskTrigger -Daily -At 12am 
$STPrin = New-ScheduledTaskPrincipal -GroupId "System" -RunLevel Highest
Write-Host "Creating Scheduled task '$taskName' to update authentication policy '$PolicyName' with users from the group '$UsersGroupName'" -ForegroundColor Green
Write-Verbose 'Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $STPrin -Description "Update Authentication policy $PolicyName users with $UsersGroupName members"'
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $STPrin -Description "Update Authentication policy '$PolicyName' users with '$UsersGroupName' members"
Get-ScheduledTask -TaskName $taskName | Start-ScheduledTask 
 

$taskName = "Update_AuthPolicy_$($PolicyName)_with_Computers"
$argument = "-NoProfile -command " + '"$sids = @(); Get-ADGroupMember -Identity ' + $ComputersGroupName + ' | ForEach-Object {$sid = $_.SID.value; $sids += ' + '"""' + 'SID($sid)' + '"""}; if (($sids | Measure-Object).count -gt 1){$sidsj = $sids -join ' + '"""' + ',' + '"""' + '}else{$sidsj = $sids}; Set-ADAuthenticationPolicy -Identity ' + $PolicyName + ' -UserAllowedToAuthenticateFrom ' + '"""' + 'O:SYG:SYD:(XA;OICI;CR;;;WD;(Member_of_any {$sidsj}))' + '"""'
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $argument
$trigger =  New-ScheduledTaskTrigger -Daily -At 12am 
$STPrin = New-ScheduledTaskPrincipal -GroupId "System" -RunLevel Highest
Write-Host "Creating Scheduled task '$taskName' to update authentication policy '$PolicyName' with computers from the group '$ComputersGroupName'" -ForegroundColor Green
Write-Verbose 'Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $STPrin -Description "Update Authentication policy $PolicyName users with $ComputersGroupName members"'
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Principal $STPrin -Description "Update Authentication policy '$PolicyName' users with '$ComputersGroupName' members"
Get-ScheduledTask -TaskName $taskName | Start-ScheduledTask

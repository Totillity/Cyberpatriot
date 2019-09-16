cd C:\Users\$env:USERNAME\Desktop
Write-Host Stealing the Readme
$url = Read-Host -Prompt 'Input the Readme URL'
Invoke-RestMethod -Uri $url -Method Get -OutFile C:\Users\$env:USERNAME\Desktop\Output\readme.txt

Write-Host Checking Authorized Users

$users = Get-LocalUser | findstr -i true
$readme = Get-Content .\Output\readme.txt
$users -replace "True","" > .\Output\users.txt
$content = Get-Content .\Output\users.txt
$content | Foreach {$_.TrimEnd()} | Set-Content .\Output\users.txt
$authUsers = [regex]::matches($readme, 'Authorized Administrators(.*?)Competition Guidelines').value
$authUsers > .\Output\authUsers.txt



foreach($line in Get-Content .\Output\users.txt) {
    if(Get-Content .\Output\authUsers.txt | Select-String $line){
        Write-Host $line has been a good and followed the Rules
        Write-Host .
    } else {
      Write-Host $line is not in the Readme. Adding him/her to deletedUsers.txt and removing...
	    Remove-LocalUser -Name "$line"
	    $line >> .\Output\deletedUsers.txt
      Write-Host WARNING WARNING -The above person has pulled an oopsie- WARNING WARNING
    }
}

Write-Host Checking for Authorized Administrators and Demoting
$admin = Get-LocalGroupMember -Group "Administrators" | ForEach-Object {$_.name} | Select-String -Pattern "Administrator" -NotMatch
$admin -replace '.*\\' > .\Output\admins.txt
$readme = Get-Content .\Output\readme.txt
$authAdmin = [regex]::matches($readme, 'Authorized Administrators(.*?)Authorized Users').value
$authAdmin > .\Output\authAdmin.txt
foreach($line in Get-Content .\Output\admins.txt) {
    if(Get-Content .\Output\authAdmin.txt | Select-String $line){
	    Write-Host $line is authorized. Not demoting...
    } else {
	    Write-Host $line is not authorized. Adding him/her to demotedAdmins.txt and demoting...
	    Remove-LocalGroupMember -Group "Administrators" -Member $line
	    $line >> .\Output\demotedAdmins.txt
    }
}

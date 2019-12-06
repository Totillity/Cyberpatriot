# Administrator, DefaultAccount, Guest, WDAGUtilityAccount

$DUMP = ($PSScriptRoot + "\..\dump\")


$SecureStdPass = ConvertTo-SecureString "TiredofWork50" -AsPlainText -Force

function automaticUsersPrep() {
    $URL = Get-Content ($env:USERPROFILE+"\Desktop\README.desktop")
    $Regex = [Regex]::new('(?<=")(.*)(?=")')
    $Match = $Regex.Match($URL)
    if ($Match.Success) {
        $URL = $Match.Value
    }
    echo $URL
    Invoke-WebRequest -Uri $URL -OutFile ($DUMP + "readme.txt")
}

function removeUnauthorizedUsers() {
    $readme = Get-Content ($DUMP + "readme.txt")
    Get-LocalUser | ForEach-Object {
        $currentUser = $_.ToString()
        if ($currentUser.contains("Administrator") -or $currentUser.contains("DefaultAccount") -or $currentUser.contains("Guest") -or $currentUser.contains("WDAGUtilityAccount")) {
            echo "Built-In Account detected"
        } else {
            $authorizedUser = $readme | Select-String -Pattern $currentUser.TrimEnd() -Quiet
            if (-not($authorizedUser)) {
                echo ($currentUser + " is not authorized")
                Remove-LocalUser -Name $currentUser
            } else {
                echo ($currentUser + " is authorized")
                if (-not($currentUser -eq $env:UserName)) {
                    Set-LocalUser -Name $currentUser -Password $SecureStdPass
                }
                Set-LocalUser -Name $currentUser -PasswordNeverExpires $false
            }
        }
    }   
}

function demoteUnauthorizedAdministrators() {
    $readme = Get-Content ($DUMP + "readme.txt")
    $Regex = [Regex]::new('(?<=Authorized Administrators)(.*)(?=Authorized Users)')
    $Match = $Regex.Match($readme)
    if ($Match.Success) {
        $authorizedAdmin = $Match.Value
    }
    Get-LocalGroupMember -Group "Administrators" | ForEach-Object {
        $localAdmin = (($_ -split "\\")[1])
        if ($localAdmin.contains("Administrator")) {
            Write-Host "Built-In Account Detected"
        } else {
            $isAuthorized = $authorizedAdmin | Select-String -Pattern $localAdmin -Quiet
            if(-not($isAuthorized)) {
                Write-Host "$localAdmin is not admin"
                Remove-LocalGroupMember -Group "Administrators" -Member $localAdmin
            }
        }
    } 
}

automaticUsersPrep
if (-not(Test-Path ($DUMP + "readme.txt"))) {
    echo "It looks like I couldn't download the readme. Please enter URL"
    $URL = Read-Host -Prompt 'URL'
    Invoke-WebRequest -Uri $URL -OutFile ($DUMP + "readme.txt")
    if (-not(Test-Path ($DUMP + "readme.txt"))) {
        echo "Uh-Oh the readme isn't downloading for some reason. Exiting..."
        Exit
    }
}
removeUnauthorizedUsers
demoteUnauthorizedAdministrators
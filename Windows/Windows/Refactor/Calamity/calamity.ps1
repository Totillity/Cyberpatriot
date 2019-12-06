#Requires -RunAsAdministrator

function SelectionMenu() {
    Write-Host "Enter a number from the below options to run certain modules or parts"
    Write-Host "+-------------------------------------------------------------------+"
    Write-Host "| 1. Everything                                                     |"
    Write-Host "| 2. Policies                                                       |"
    Write-Host "| 3. Users                                                          |"
    Write-Host "| 4. Firewall                                                       |"
    Write-Host "| 5. Applications                                                   |"
    Write-Host "| 6. Services                                                       |"
    Write-Host "| 7. Miscellaneous                                                  |"
    Write-Host "| 8. Change Options                                                 |"
    Write-Host "| 9. Exit                                                           |"
    Write-Host "|-------------------------------------------------------------------|"
    Write-Host "| Chosen Options                                                    |"
    Write-Host "| Enable Remote Desktop: $RDP                                          |"
    Write-Host "| Enable SMB: $SMB                                                     |"
    Write-Host "| Remove Shares: $AllowShares                                                  |"
    Write-Host "+-------------------------------------------------------------------+"
}

function Users {
    $scriptPath = $PSScriptRoot + "\Modules\users.ps1"
    Invoke-Expression "cmd /c start powershell -NoExit -Command '& $scriptPath'"
}

function Applications {
    Param($RDP, $SMB, $AllowShares)
    $scriptPath = $PSScriptRoot + "\Modules\applications.bat $RDP $SMB $AllowShares"
    Invoke-Expression "cmd /c start powershell -NoExit -Command '& $scriptPath'"
}

function Policies {
    $scriptPath = $PSScriptRoot + "\Modules\policies.bat"
    Invoke-Expression "cmd /c start powershell -NoExit -Command '& $scriptPath'"
}

function Firewall {
    $scriptPath = $PSScriptRoot + "\Modules\firewall.bat"
    Invoke-Expression "cmd /c start powershell -NoExit -Command '& $scriptPath'"
}

function Services {
    $scriptPath = $PSScriptRoot + "\Modules\services.bat"
    Invoke-Expression "cmd /c start powershell -NoExit -Command '& $scriptPath'"
}

function Miscellaneous {
    $scriptPath = $PSScriptRoot + "\Modules\miscellaneous.bat"
    Invoke-Expression "cmd /c start powershell -NoExit -Command '& $scriptPath'"
}

function RunEverything {
    Users
    Applications
    Policies
    Firewall
    Services
    Miscellaneous
}



$DUMP = ($PSScriptRoot + "\dump\")
New-Item -ItemType Directory -Path ($DUMP)

Write-Host "Welcome to the execution of the Calamity script. First please answer a few questions"
$RDP = Read-Host -Prompt "Enable Remote Desktop? (Y/N)"
$SMB = Read-Host -Prompt "Enable SMB? (Y/N)"
$AllowShares = Read-Host -Prompt "Remove Shares? (Y/N)"
do {
    SelectionMenu
    $Selection = Read-Host "Option"
    Switch ($Selection){
        '1' {
            RunEverything
        } '2' {
            Policies
        } '3' {
            Users
        } '4' {
            Firewall
        } '5' {
            Applications -RDP $RDP -SMB $SMB -AllowShares $AllowShares
        } '6' {
            Services
        } '7' {
            Miscellaneous
        } '8' { 
            $RDP = Read-Host -Prompt "Enable Remote Desktop? (Y/N)"
            $SMB = Read-Host -Prompt "Enable SMB? (Y/N)"
            $AllowShares = Read-Host -Prompt "Remove Shares? (Y/N)"
        } '9' {
            return
        }
    }
    pause
} until ($Selection -eq '9')

@echo off
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
CHOICE /M "Do you want Echo ON "
if %ERRORLEVEL% EQU 2 @echo off
if %ERRORLEVEL% EQU 1 @echo on
setlocal enabledelayedexpansion
color 1f
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Check for admin rights
echo Checking if script contains Administrative rights...
net sessions
if %errorlevel%==0 (
	echo Success!
	cls
) else (
	cls
	echo No admin, please run with Administrative rights if you want to the script to work!
	pause
  cls
  echo You have chose to run the script without Aministrative Rights, "Good Luck!"
	pause
)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:options

:: Operating System (thank you to, Compo [user:6738015], user on stackoverflow)
Set "_P="
For /F "EOL=P Tokens=*" %%A In ('"WMIC OS Get ProductType,Version 2>Nul"'
) Do For /F "Tokens=1-3 Delims=. " %%B In ("%%A") Do Set /A _P=%%B,_V=%%C%%D
If Not Defined _P Exit /B
If %_V% Lss 62 Exit /B
If %_P% Equ 1 (If %_V% Equ 62 Set "OS=Windows8"
    If %_V% Equ 63 Set "OS=Windows81"
    If %_V% Equ 100 Set "OS=Windows10"
) Else If %_V% Equ 100 (Set "OS=Server2016") Else Exit /B
Set OS
echo.

:: Operating System "bit" (thank you to, Iridium [user:381588], user on stackoverflow)
if "%PROCESSOR_ARCHITECTURE%" EQU "x86" (
    if "%PROCESSOR_ARCHITEW6432%" EQU "AMD64" (
        :: 64 bit OS, but running a 32 bit command prompt
        set bit=64
    ) else (
        :: 32 bit OS
        set bit=32
    )
) else (
    :: 64 bit OS
    set bit=64
)
set bit
echo.

:: Do you want RemoteDesktop
set RemoteDesktop=N
set /P choice=Disable RemoteDesktop [Y/N]?
if /I "%choice%" EQU "Y" set RemoteDesktop=Y
echo.

:: Do you want SMB
set SMB=N
set /P choice=Do you want SMB enabled [Y/N]?
if /I "%choice%" EQU "Y" set SMB=Y
echo.

:: Do we need files to be shared
set share=Y
set /P choice=Do we need files to be shared [Y/N]?
if /I "%choice%" EQU "N" set share=N
echo.

:: Do you want to do users
set HPps1=Y
set /P choice=Do you want to do hardenpolicy.ps1 [Y/N]?
if /I "%choice%" EQU "N" set HPps1=N
echo.

:: Do you want to do users
set Users=Y
set /P choice=Do you want to do users [Y/N]?
if /I "%choice%" EQU "N" set Users=N
if /I "%choice%" EQU "Y" set Users=Y
echo.

:: Do you want to edit FirefoxSettings
set Firefox=Y
set /P choice=Do you want to complete FirefoxSettings [Y/N]?
if /I "%choice%" EQU "N" set Firefox=N
echo.

:: Do you want to install Software
set Software=Y
set /P choice=Do you want to install/update software [Y/N]?
if /I "%choice%" EQU "N" set Software=N
echo.
cls

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:MENU
color f0
echo Choose An option:
echo ษอออออออออออออออออออออป
echo บ  1. Does everything บ
echo บ  2. Policies        บ
echo บ  3. Users           บ
echo บ  4. Software        บ
echo บ  5. Input           บ
echo ฬอออออออออออออออออออออสอออออออออออออออออออป
echo บ Current OS = %OS%
echo บ Enable RemoteDesktop = %RemoteDesktop%
echo บ Run hardenpolicy.ps1 = %HPps1%
echo บ Enable SMB = %SMB%
echo บ Keep shares = %share%
echo บ Run Users script = %Users%
echo บ Run Firefox script = %Firefox%
echo บ Install/update software = %Software%
echo ศอออออออออออออออออออออออออออออออออออออออออผ

:: Fetch option
CHOICE /C 12345 /M "Enter your choice:"
if %ERRORLEVEL% EQU 5 goto :Input
if %ERRORLEVEL% EQU 4 goto :Software
if %ERRORLEVEL% EQU 3 goto :Users
if %ERRORLEVEL% EQU 2 goto :policies
if %ERRORLEVEL% EQU 1 goto :Everything

:Input
set /p Loc="Enter Location: "
echo %Loc%
pause
goto %Loc%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:Everything

::Dose audit categorys
auditpol /set /category:* /success:enable
auditpol /set /category:* /failure:enable

:FirefoxSettings

if /I "%Firefox%" EQU "N" goto SkipFF
cd %appdata%\Mozilla\Firefox\Profiles
:: Below: this selects the next folder in the DIR [you have to do this becuase the folder you need to get into is generated at random]
for /d %%F in (*) do cd "%%F" & goto :break
:break
copy /y /v %~dp0\Meta\Perfect\prefs.js %cd%
cls
echo. & echo You should be good!
start /wait firefox about:config
:SkipFF

:share
if /I "%share%" EQU "N" wmic path Win32_Share delete

:InternetExp
dism /online /enable-feature:"Internet-Explorer-Optional-amd64"

:registry
:: Shows all files even if Super Hidden
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /V Hidden /T REG_DWORD /D 1 /F
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /V HideFileExt /T REG_DWORD /D 0 /F
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /V ShowSuperHidden /T REG_DWORD /D 1 /F

:: Windows Update
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /V AUOptions /T REG_DWORD /D 4 /F
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /V ElevateNonAdmins /T REG_DWORD /D 1 /F
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /V IncludeRecommendedUpdates /T REG_DWORD /D 1 /F
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /V ScheduledInstallTime /T REG_DWORD /D 22 /F
sc config wuauserv start= auto
net start wuauserv

:: Netowrking/Miscellaneous
reg add "HKLM\SYSTEM\CurrentControlSet\Services\cdrom" /V AutoRun /T REG_DWORD /D 0 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Application" /V RestrictGuestAcess /T REG_DWORD /D 1 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\EventLog\System" /V RestrictGuestAcess /T REG_DWORD /D 1 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Security" /V RestrictGuestAcess /T REG_DWORD /D 1 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V SynAttackProtect /T REG_DWORD /D 2 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V EnableDeadGWDetect /T REG_DWORD /D 0 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V EnableICMPRedirect /T REG_DWORD /D 0 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V DisableIPSourceRouting /T REG_DWORD /D 2 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V KeepAliveTime /T REG_DWORD /D 300000 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V NoNameReleaseOnDemand /T REG_DWORD /D 1 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V TcpMaxConnectResponseRetransmissions /T REG_DWORD /D 2 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V TcpMaxDataRetransmissions /T REG_DWORD /D 3 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /V TcpMaxPortsExhausted /T REG_DWORD /D 5 /F
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /V NoDriveTypeAutorun /T REG_DWORD /D 255 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Control\LSA\Kerberos\Parameters" /V LogLevel /T REG_DWORD /D 1 /F

:: Security - Disable Autorun.
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoAutorun" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d 255 /f

:: Privacy/Security - Only download Windows Updates from LAN peers, and Microsoft servers.
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d 1 /f

::Configuring UAC
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /V PromptOnSecureDesktop /T REG_DWORD /D 1 /F
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /V ConsentPromptBehaviorAdmin /T REG_DWORD /D 1 /F
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /V ConsentPromptBehaviorUser /T REG_DWORD /D 0 /F
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /V FilterAdministratorToken /T REG_DWORD /D 1 /F
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /V EnableInstallerDetection /T REG_DWORD /D 1 /F
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /V EnableLUA /T REG_DWORD /D 1 /F >> nul 2>&1
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /V EnableVirtualization /T REG_DWORD /D 1 /F


:SMB
:: https://www.alibabacloud.com/help/faq-detail/57499.htm
Dism /online /Get-Features /format:table | find "SMB1Protocol"
if /I "%SMB%" EQU "Y" (
  :: Disable SMB1
  sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi
  sc.exe config mrxsmb10 start= disabled
  :: Enable SMB2/3
  sc.exe config lanmanworkstation depend= bowser/mrxsmb10/mrxsmb20/nsi
  sc.exe config mrxsmb20 start= auto
) else (
  :: Disables SMB1
  sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi
  sc.exe config mrxsmb10 start= disabled
  :: Disables SMB2/3
  sc.exe config lanmanworkstation depend= bowser/mrxsmb10/nsi
  sc.exe config mrxsmb20 start= disabled
)


:RemoteDesktop
if /I "%RemoteDesktop%" EQU "N" (
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /V fDenyTSConnections /T REG_DWORD /D 1 /F
	sc config iphlpsvc start= disabled
	sc stop iphlpsvc
	sc config umrdpservice start= disabled
	sc stop umrdpservice
	sc config termservice start= disabled
	sc stop termservice
) else (
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /V fDenyTSConnections /T REG_DWORD /D 0 /F
  reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /V UserAuthentication /T REG_DWORD /D 1 /F
)

:: Regardless, set these keys
reg add "HKLM\SYSTEM\ControlSet001\Control\Remote Assistance" /V CreateEncryptedOnlyTickets /T REG_DWORD /D 1 /F
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /V fDisableEncryption /T REG_DWORD /D 0 /F
reg add "HKLM\SYSTEM\ControlSet001\Control\Remote Assistance" /V fAllowFullControl /T REG_DWORD /D 0 /F
reg add "HKLM\SYSTEM\ControlSet001\Control\Remote Assistance" /V fAllowToGetHelp /T REG_DWORD /D 0 /F
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /V AllowRemoteRPC /T REG_DWORD /D 0 /F


:miscellaneous
:: Security - Do not hide extensions for know file types.
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\HideFileExt" /v "CheckedValue" /t REG_DWORD /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f


:firewall
netsh advfirewall set allprofiles state on
netsh advfirewall reset
netsh advfirewall show allprofiles
netsh advfirewall firewall set rule name="Remote Assistance (DCOM-In)" new enable=no
netsh advfirewall firewall set rule name="Remote Assistance (PNRP-In)" new enable=no
netsh advfirewall firewall set rule name="Remote Assistance (RA Server TCP-In)" new enable=no
netsh advfirewall firewall set rule name="Remote Assistance (SSDP TCP-In)" new enable=no
netsh advfirewall firewall set rule name="Remote Assistance (SSDP UDP-In)" new enable=no
netsh advfirewall firewall set rule name="Remote Assistance (TCP-In)" new enable=no
netsh advfirewall firewall set rule name="Telnet Server" new enable=no
netsh advfirewall firewall set rule name="netcat" new enable=no
netsh advfirewall set allprofiles state on
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound
netsh advfirewall firewall add rule name="Block135tout" protocol=TCP dir=out remoteport=135 action=block
netsh advfirewall firewall add rule name="Block135uout" protocol=UDP dir=out remoteport=135 action=block
netsh advfirewall firewall add rule name="Block135tin" protocol=TCP dir=in localport=135 action=block
netsh advfirewall firewall add rule name="Block135tout" protocol=UDP dir=in localport=135 action=block
netsh advfirewall firewall add rule name="Block137tout" protocol=TCP dir=out remoteport=137 action=block
netsh advfirewall firewall add rule name="Block137uout" protocol=UDP dir=out remoteport=137 action=block
netsh advfirewall firewall add rule name="Block137tin" protocol=TCP dir=in localport=137 action=block
netsh advfirewall firewall add rule name="Block137tout" protocol=UDP dir=in localport=137 action=block
netsh advfirewall firewall add rule name="Block138tout" protocol=TCP dir=out remoteport=138 action=block
netsh advfirewall firewall add rule name="Block138uout" protocol=UDP dir=out remoteport=138 action=block
netsh advfirewall firewall add rule name="Block138tin" protocol=TCP dir=in localport=138 action=block
netsh advfirewall firewall add rule name="Block138tout" protocol=UDP dir=in localport=138 action=block
netsh advfirewall firewall add rule name="Block139tout" protocol=TCP dir=out remoteport=139 action=block
netsh advfirewall firewall add rule name="Block139uout" protocol=UDP dir=out remoteport=139 action=block
netsh advfirewall firewall add rule name="Block139tin" protocol=TCP dir=in localport=139 action=block
netsh advfirewall firewall add rule name="Block139tout" protocol=UDP dir=in localport=139 action=block

:: Disable default rules.
netsh advfirewall firewall set rule group="Connect" new enable=no
netsh advfirewall firewall set rule group="Contact Support" new enable=no
netsh advfirewall firewall set rule group="Cortana" new enable=no
netsh advfirewall firewall set rule group="DiagTrack" new enable=no
netsh advfirewall firewall set rule group="Feedback Hub" new enable=no
netsh advfirewall firewall set rule group="Microsoft Photos" new enable=no
netsh advfirewall firewall set rule group="OneNote" new enable=no
netsh advfirewall firewall set rule group="Remote Assistance" new enable=no
netsh advfirewall firewall set rule group="Windows Spotlight" new enable=no

:: Delete custom rules in case script has previously run.
netsh advfirewall firewall delete rule name="block_Connect_in"
netsh advfirewall firewall delete rule name="block_Connect_out"
netsh advfirewall firewall delete rule name="block_ContactSupport_in"
netsh advfirewall firewall delete rule name="block_ContactSupport_out"
netsh advfirewall firewall delete rule name="block_Cortana_in"
netsh advfirewall firewall delete rule name="block_Cortana_out"
netsh advfirewall firewall delete rule name="block_DiagTrack_in"
netsh advfirewall firewall delete rule name="block_DiagTrack_out"
netsh advfirewall firewall delete rule name="block_dmwappushservice_in"
netsh advfirewall firewall delete rule name="block_dmwappushservice_out"
netsh advfirewall firewall delete rule name="block_FeedbackHub_in"
netsh advfirewall firewall delete rule name="block_FeedbackHub_out"
netsh advfirewall firewall delete rule name="block_OneNote_in"
netsh advfirewall firewall delete rule name="block_OneNote_out"
netsh advfirewall firewall delete rule name="block_Photos_in"
netsh advfirewall firewall delete rule name="block_Photos_out"
netsh advfirewall firewall delete rule name="block_RemoteRegistry_in"
netsh advfirewall firewall delete rule name="block_RemoteRegistry_out"
netsh advfirewall firewall delete rule name="block_RetailDemo_in"
netsh advfirewall firewall delete rule name="block_RetailDemo_out"
netsh advfirewall firewall delete rule name="block_WMPNetworkSvc_in"
netsh advfirewall firewall delete rule name="block_WMPNetworkSvc_out"
netsh advfirewall firewall delete rule name="block_WSearch_in"
netsh advfirewall firewall delete rule name="block_WSearch_out"

:: Add custom blocking rules.
netsh advfirewall firewall add rule name="block_Connect_in" dir=in program="%WINDIR%\SystemApps\Microsoft.PPIProjection_cw5n1h2txyewy\Receiver.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_Connect_out" dir=out program="%WINDIR%\SystemApps\Microsoft.PPIProjection_cw5n1h2txyewy\Receiver.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_ContactSupport_in" dir=in program="%WINDIR%\SystemApps\ContactSupport_cw5n1h2txyewy\ContactSupport.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_ContactSupport_out" dir=out program="%WINDIR%\SystemApps\ContactSupport_cw5n1h2txyewy\ContactSupport.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_Cortana_in" dir=in program="%WINDIR%\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy\SearchUI.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_Cortana_out" dir=out program="%WINDIR%\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy\SearchUI.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_DiagTrack_in" dir=in service="DiagTrack" action=block enable=yes
netsh advfirewall firewall add rule name="block_DiagTrack_out" dir=out service="DiagTrack" action=block enable=yes
netsh advfirewall firewall add rule name="block_dmwappushservice_in" dir=in service="dmwappushservice" action=block enable=yes
netsh advfirewall firewall add rule name="block_dmwappushservice_out" dir=out service="dmwappushservice" action=block enable=yes
netsh advfirewall firewall add rule name="block_FeedbackHub_in" dir=in program="%ProgramFiles%\WindowsApps\Microsoft.WindowsFeedbackHub_1.1708.2831.0_x64__8wekyb3d8bbwe\PilotshubApp.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_FeedbackHub_out" dir=out program="%ProgramFiles%\WindowsApps\Microsoft.WindowsFeedbackHub_1.1708.2831.0_x64__8wekyb3d8bbwe\PilotshubApp.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_OneNote_in" dir=in program="%ProgramFiles%\WindowsApps\Microsoft.Office.OneNote_17.8625.21151.0_x64__8wekyb3d8bbwe\onenoteim.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_OneNote_out" dir=out program="%ProgramFiles%\WindowsApps\Microsoft.Office.OneNote_17.8625.21151.0_x64__8wekyb3d8bbwe\onenoteim.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_Photos_in" dir=in program="%ProgramFiles%\WindowsApps\Microsoft.Windows.Photos_2017.39091.16340.0_x64__8wekyb3d8bbwe\Microsoft.Photos.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_Photos_out" dir=out program="%ProgramFiles%\WindowsApps\Microsoft.Windows.Photos_2017.39091.16340.0_x64__8wekyb3d8bbwe\Microsoft.Photos.exe" action=block enable=yes
netsh advfirewall firewall add rule name="block_RemoteRegistry_in" dir=in service="RemoteRegistry" action=block enable=yes
netsh advfirewall firewall add rule name="block_RemoteRegistry_out" dir=out service="RemoteRegistry" action=block enable=yes
netsh advfirewall firewall add rule name="block_RetailDemo_in" dir=in service="RetailDemo" action=block enable=yes
netsh advfirewall firewall add rule name="block_RetailDemo_out" dir=out service="RetailDemo" action=block enable=yes
netsh advfirewall firewall add rule name="block_WMPNetworkSvc_in" dir=in service="WMPNetworkSvc" action=block enable=yes
netsh advfirewall firewall add rule name="block_WMPNetworkSvc_out" dir=out service="WMPNetworkSvc" action=block enable=yes
netsh advfirewall firewall add rule name="block_WSearch_in" dir=in service="WSearch" action=block enable=yes
netsh advfirewall firewall add rule name="block_WSearch_out" dir=out service="WSearch" action=block enable=yes


:weak
:: Weak services
echo "DISABLING WEAK SERVICES"
dism /online /disable-feature /featurename:IIS-WebServerRole /NoRestart
dism /online /disable-feature /featurename:IIS-WebServer /NoRestart
dism /online /disable-feature /featurename:IIS-CommonHttpFeatures /NoRestart
dism /online /disable-feature /featurename:IIS-HttpErrors /NoRestart
dism /online /disable-feature /featurename:IIS-HttpRedirect /NoRestart
dism /online /disable-feature /featurename:IIS-ApplicationDevelopment /NoRestart
dism /online /disable-feature /featurename:IIS-NetFxExtensibility /NoRestart
dism /online /disable-feature /featurename:IIS-NetFxExtensibility45 /NoRestart
dism /online /disable-feature /featurename:IIS-HealthAndDiagnostics /NoRestart
dism /online /disable-feature /featurename:IIS-HttpLogging /NoRestart
dism /online /disable-feature /featurename:IIS-LoggingLibraries /NoRestart
dism /online /disable-feature /featurename:IIS-RequestMonitor /NoRestart
dism /online /disable-feature /featurename:IIS-HttpTracing /NoRestart
dism /online /disable-feature /featurename:IIS-Security /NoRestart
dism /online /disable-feature /featurename:IIS-URLAuthorization /NoRestart
dism /online /disable-feature /featurename:IIS-RequestFiltering /NoRestart
dism /online /disable-feature /featurename:IIS-IPSecurity /NoRestart
dism /online /disable-feature /featurename:IIS-Performance /NoRestart
dism /online /disable-feature /featurename:IIS-HttpCompressionDynamic /NoRestart
dism /online /disable-feature /featurename:IIS-WebServerManagementTools /NoRestart
dism /online /disable-feature /featurename:IIS-ManagementScriptingTools /NoRestart
dism /online /disable-feature /featurename:IIS-IIS6ManagementCompatibility /NoRestart
dism /online /disable-feature /featurename:IIS-Metabase /NoRestart
dism /online /disable-feature /featurename:IIS-HostableWebCore /NoRestart
dism /online /disable-feature /featurename:IIS-StaticContent /NoRestart
dism /online /disable-feature /featurename:IIS-DefaultDocument /NoRestart
dism /online /disable-feature /featurename:IIS-DirectoryBrowsing /NoRestart
dism /online /disable-feature /featurename:IIS-WebDAV /NoRestart
dism /online /disable-feature /featurename:IIS-WebSockets /NoRestart
dism /online /disable-feature /featurename:IIS-ApplicationInit /NoRestart
dism /online /disable-feature /featurename:IIS-ASPNET /NoRestart
dism /online /disable-feature /featurename:IIS-ASPNET45 /NoRestart
dism /online /disable-feature /featurename:IIS-ASP /NoRestart
dism /online /disable-feature /featurename:IIS-CGI /NoRestart
dism /online /disable-feature /featurename:IIS-ISAPIExtensions /NoRestart
dism /online /disable-feature /featurename:IIS-ISAPIFilter /NoRestart
dism /online /disable-feature /featurename:IIS-ServerSideIncludes /NoRestart
dism /online /disable-feature /featurename:IIS-CustomLogging /NoRestart
dism /online /disable-feature /featurename:IIS-BasicAuthentication /NoRestart
dism /online /disable-feature /featurename:IIS-HttpCompressionStatic /NoRestart
dism /online /disable-feature /featurename:IIS-ManagementConsole /NoRestart
dism /online /disable-feature /featurename:IIS-ManagementService /NoRestart
dism /online /disable-feature /featurename:IIS-WMICompatibility /NoRestart
dism /online /disable-feature /featurename:IIS-LegacyScripts /NoRestart
dism /online /disable-feature /featurename:IIS-LegacySnapIn /NoRestart
dism /online /disable-feature /featurename:IIS-FTPServer /NoRestart
dism /online /disable-feature /featurename:IIS-FTPSvc /NoRestart
dism /online /disable-feature /featurename:IIS-FTPExtensibility /NoRestart
dism /online /disable-feature /featurename:TFTP /NoRestart
dism /online /disable-feature /featurename:TelnetClient /NoRestart
dism /online /disable-feature /featurename:TelnetServer /NoRestart

:: Privacy - Stop unneeded services.
net stop DiagTrack
net stop dmwappushservice
net stop RemoteRegistry
net stop RetailDemo
net stop WinRM
net stop WMPNetworkSvc

:: Privacy - Delete, or disable, unneeded services.
sc config RemoteRegistry start=disabled
sc config RetailDemo start=disabled
sc config WinRM start=disabled
sc config WMPNetworkSvc start=disabled
sc delete DiagTrack
sc delete dmwappushservice

echo Done with SERVICES/Features simple

cls
echo. & echo Configuring services advanced

:: Services that should be burned at the stake.
for %%S in (tapisrv,bthserv,mcx2svc,remoteregistry,seclogon,telnet,tlntsvr,p2pimsvc,simptcp,fax,msftpsvc,nettcpportsharing,iphlpsvc,lfsvc,bthhfsrv,irmon,sharedaccess,xblauthmanager,xblgamesave,xboxnetapisvc) do (
	sc config %%S start= disabled
	sc stop %%S
)

:: Services that are an automatic start.
for %%S in (eventlog,mpssvc) do (
	sc config %%S start= auto
	sc start %%S
)

:: Services that are an automatic (delayed) start.
for %%S in (windefend,sppsvc,wuauserv) do (
	sc config %%S start= delayed-auto
	sc start %%S
)

:: Services that are a manual start.
for %%S in (wersvc,wecsvc) do (
	sc config %%S start= demand
)

echo. & echo Services configured.
cls


:Cleaning
echo. & echo Deleting things
del %APPDATA%\stasks.txt & del %APPDATA%\stasks2.txt

echo. & echo Cleaning startup files
reg delete HKLM\Software\Microsoft\Windows\CurrentVersion\Run /VA /F
reg delete HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce /VA /F
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /VA /F
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce /VA /F

dir /B "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\" >> %~dp0\Output\deletedfiles.txt
del /S "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\*" /F /Q
dir /B "C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\" >> %~dp0\Output\deletedfiles.txt
del /S "C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*" /F /Q
echo. & echo Startup files cleansed
cls

:policies
if "%OS%" EQU "Windows10" set Operating=true
if "%OS%" EQU "Windows81" set Operating=true
if "%OS%" EQU "Windows8" set Operating=true
if /I "%Operating%" EQU "false" goto Server
  :: Windows 10 and Windows 8.1 and Windows8
  "%~dp0\Meta\LGPO.exe" /m "%~dp0\Meta\Perfect\DomainSysvol\GPO\Machine\registry.pol"
  "%~dp0\Meta\LGPO.exe" /u "%~dp0\Meta\Perfect\DomainSysvol\GPO\User\registry.pol"
  "%~dp0\Meta\LGPO.exe" /s "%~dp0\Meta\Perfect\DomainSysvol\GPO\Machine\microsoft\windows nt\SecEdit\GptTmpl.inf"
  "%~dp0\Meta\LGPO.exe" /ac "%~dp0\Meta\Perfect\DomainSysvol\GPO\Machine\microsoft\windows nt\Audit\audit.csv"
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /V DisableExceptionChainValidation /T REG_DWORD /D 0 /F
  reg add HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowSignInOptions /V value /T REG_DWORD /D 0 /F
  reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config /V DownloadMode /T REG_DWORD /D 0 /F
  reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config /V DODownloadMode /T REG_DWORD /D 0 /F

  :: They kept changing the value name for this, so I'm just doing all of them.
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /V AllowCortana /T REG_DWORD /D 0 /F
  reg add HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config /V AutoConnectAllowedOEM /T REG_DWORD /D 0 /F
  reg add HKLM\Software\Policies\Microsoft\Windows\OneDrive /V DisableFileSyncNGSC /T REG_DWORD /D 1 /F
  reg add HKLM\Software\Policies\Microsoft\Windows\OneDrive /V DisableFileSync /T REG_DWORD /D 1 /F

goto AfterServerPol

:Server
  :: Windows Server
  "%~dp0\Meta\LGPO.exe" /m "%~dp0\Meta\Perfect\ServerDomainSysvol\GPO\Machine\registry.pol"
  "%~dp0\Meta\LGPO.exe" /u "%~dp0\Meta\Perfect\ServerDomainSysvol\GPO\User\registry.pol"
  "%~dp0\Meta\LGPO.exe" /s "%~dp0\Meta\Perfect\ServerDomainSysvol\GPO\Machine\microsoft\windows nt\SecEdit\GptTmpl.inf"
  "%~dp0\Meta\LGPO.exe" /ac "%~dp0\Meta\Perfect\ServerDomainSysvol\GPO\Machine\microsoft\windows nt\Audit\audit.csv"

:AfterServerPol

:Software
if /I "%Software%" EQU "Y" (
	start %~dp0\Meta\"Ninite - Everything Firefox Glary Malwarebytes Installer.exe"
)

:Users
if /I "%Users%" EQU "Y" (
	cls
	color 0D

	copy %~dp0\Meta\users.ps1 %USERPROFILE%\desktop
	MKDIR %USERPROFILE%\desktop\output

	pause
	set PATH=%PATH%;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\
	powershell.exe -executionpolicy bypass -file %USERPROFILE%\desktop\users.ps1
	cd C:\Windows\System32
	set path=C:\Windows\System32
	pause
)
pause

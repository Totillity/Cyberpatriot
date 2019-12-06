cd %appdata%\Mozilla\Firefox\Profiles
:: Below: this selects the next folder in the DIR [you have to do this becuase the folder you need to get into is generated at random]
for /d %%F in (*) do cd "%%F" & goto :break
:break
copy /y /v %~dp0\..\Perfect\prefs.js %cd%
start /wait firefox about:config

set RemoteDesktop=%1
set SMB=%2
set share=%3

echo %RemoteDesktop%
echo %SMB%
echo %share%

if /I "%share%" EQU "Y" wmic path Win32_Share delete

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


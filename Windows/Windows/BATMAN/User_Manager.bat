@echo off
color 1f
set path=%~dp0
echo Checking if script contains Administrative rights...
net sessions
if %errorlevel%==0 (
echo Success!
) else (
cls
echo No admin, please run with Administrative rights...
pause
)

color 1f

set "user=dir"
path %SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem

:Options
cls
echo Account Options
echo ---------------
echo.
echo 1. View Account Details
echo.
echo 2. Change Account password
echo.
echo 3. Change Account Name
echo.
echo 4. Enable Account
echo.
echo 5. Disable Account
echo.
echo 6. Add/Revoke Administrator Priviledge
echo.
echo 7. Delete Account
echo.
echo 8. Exit
echo.
echo *NOTE: You must be an andministrator to use some features of this program!
echo.
echo.
set/p "option=Enter the number that corresponds with the option you wish to perform: "
if %option%== 1 goto :Details
if %option%== 2 goto :Password
if %option%== 3 goto :Name
if %option%== 4 goto :Enable
if %option%== 5 goto :Disable
if %option%== 6 goto :Admin
if %option%== 7 goto :Delete
if %option%== 8 exit
goto :Options


:Details
cls
path
echo.
wmic useraccount get name
echo.
set/p "user=Please enter account to receive this action: "
cls
net user %user%
set/p "choice=More Users? (y,n): "
if %choice%==y goto :Details
if %choice%==n goto :Options
goto :Options

:Password
cls
echo.
wmic useraccount get name
echo.
set/p "user=Please enter account to receive this action: "
net user %user% *
set/p "choice=More Users? (y,n): "
if %choice%==y goto :Password
if %choice%==n goto :Options
goto :Options

:Name
cls
echo.
wmic useraccount get name
echo.
set/p "user=Please enter account to receive this action: "
echo.
set/p "name=Enter new name: "
wmic useraccount where name='%user%' rename %name%
set/p "choice=More Users? (y,n): "
if %choice%==y goto :Name
if %choice%==n goto :Options
goto :Options

:Enable
cls
echo.
wmic useraccount get name
echo.
set/p "user=Please enter account to receive this action: "
net user %user% /active:yes
set/p "choice=More Users? (y,n): "
if %choice%==y goto :Enable
if %choice%==n goto :Options
goto :Options


:Disable
cls
echo.
wmic useraccount get name
echo.
set/p "user=Please enter account to receive this action: "
net user %user% /active:no
set/p "choice=More Users? (y,n): "
if %choice%==y goto :Disable
if %choice%==n goto :Options
goto :Options


:Admin
cls
echo.
net localgroup Administrators
echo.
echo.
set/p "user=Please enter account to receive this action: "
echo.
set/p "choice=Add or revoke? (a,r): "
if %choice%==a net localgroup administrators %user% /add
if %choice%==r net localgroup administrators %user% /delete
set/p "choice=More Users? (y,n): "
if %choice%==y goto :Admin
if %choice%==n goto :Options
goto :Options

:Delete
cls
echo.
wmic useraccount get name
echo.
set/p "user=Please enter account to receive this action: "
echo.
set/p "selection=ARE YOU SURE YOU WANT TO DELETE THE ACOUNT AND ALL OF ITS CONTENTS? (y,n): "
if %selection%==y net user %user% /DELETE
if %selection%==n goto :Delete
set/p "choice=More Users? (y,n): "
if %choice%==y goto :Delete
if %choice%==n goto :Options
goto :Options
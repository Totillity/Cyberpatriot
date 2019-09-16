############## By Hasan Dimdik ##############

##### Microsoft Internet Explorer Cumulative Security Update (MS15-124) #####
###Impact: A remote, unauthenticated attacker could exploit these vulnerabilities to conduct cross-site scripting attacks, elevate their privileges, execute arbitrary code or cause a denial of service condition on the targeted system ###
New-Item -Name "FEATURE_ENABLE_PRINT_INFO_DISCLOSURE_FIX" -Path 'hklm:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\Main\FeatureControl\' -type Directory
New-ItemProperty -Path 'hklm:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_ENABLE_PRINT_INFO_DISCLOSURE_FIX\' -Name "iexplore.exe" -Value "00000001"
New-Item -Name "FEATURE_ENABLE_PRINT_INFO_DISCLOSURE_FIX" -Path 'hklm:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\' -type Directory
New-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_ENABLE_PRINT_INFO_DISCLOSURE_FIX\' -Name "iexplore.exe" -Value "00000001"
New-Item -Name "FEATURE_ALLOW_USER32_EXCEPTION_HANDLER_HARDENING" -Path 'hklm:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\' -type Directory
New-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_ALLOW_USER32_EXCEPTION_HANDLER_HARDENING\' -Name "iexplore.exe" -Value "00000001"
New-Item -Name "FEATURE_ALLOW_USER32_EXCEPTION_HANDLER_HARDENING" -Path 'hklm:\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer\Main\FeatureControl\' -type Directory
New-ItemProperty -Path 'hklm:\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_ALLOW_USER32_EXCEPTION_HANDLER_HARDENING\' -Name "iexplore.exe" -Value "00000001"
New-Item -Name "Virtualization" -Path 'hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\' -type Directory
##### Protecting guest virtual machines from CVE-2017-5715 (branch target injection) #####
#New-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization' -Name "MinVmVersionForCpuBasedMitigations" -Value "1.0"

#####	Enabled Cached Logon Credential   ##### 
### Impact : Unauthorized users can gain access to this cached information, thereby obtaining sensitive logon information 
Set-ItemProperty -Path 'hklm:\Software\Microsoft\Windows Nt\CurrentVersion\Winlogon' -Name "CachedLogonsCount" -Value "0"

##### Windows Update For Credentials Protection and Management (Microsoft Security Advisory 2871997) #####
### Impact : If this vulnerability is successfully exploited, attackers can steal credentials of the system
New-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\Session Manager\' -Name "CWDIllegalInDllSearch" -Value "00000001" -PropertyType "DWord"

#### Microsoft Windows Security Update Registry Key Configuration Missing (ADV180012) (Spectre/Meltdown Variant 4) #####
###Impact : An attacker who has successfully exploited this vulnerability may be able to read privileged data across trust boundaries. Vulnerable code patterns in the operating system (OS) or in applications could allow an attacker to exploit this vulnerability. In the case of Just-in-Time (JIT) compilers, such as JavaScript JIT employed by modern web browsers, it may be possible for an attacker to supply JavaScript that produces native code that could give rise to an instance of CVE-2018-3639#
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name "FeatureSettingsOverride" -Value "00000008"
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name "FeatureSettingsOverrideMask" -Value "00000003"

#### Allowed Null Session ####
### Impact : Unauthorized users can establish a null session and obtain sensitive information, such as usernames and/or the share list, which could be used in further attacks against the host
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\LSA' -Name "RestrictAnonymous" -Value "00000001"
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\LSA' -Name "everyoneincludesanonymous" -Value "00000000"


Set-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer' -Name "ForceActiveDesktopOn" -Value "00000000"
Set-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer' -Name "NoActiveDesktopChanges" -Value "00000001"
Set-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer' -Name "NoActiveDesktop" -Value "00000001"
Set-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer' -Name "ShowSuperHidden" -Value "00000001"

##### Microsoft Windows Explorer AutoPlay Not Disabled #####
###Impact: Exploiting this vulnerability can cause malicious applications to be executed unintentionally at escalated privilege ###
New-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer' -Name "NoDriveTypeAutoRun" -Value "00000255" -PropertyType "DWord"
Set-ItemProperty -Path 'hkcu:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name "NoDriveTypeAutoRun" -Value "00000001"

##### Windows Registry Setting To Globally Prevent Socket Hijacking Missing #####
###Impact: If this registry setting is missing, in the absence of a SO_EXCLUSIVEADDRUSE check on a listening privileged socket, local unprivileged users can easily hijack the socket and intercept all data meant for the privileged process #####
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Services\AFD\Parameters' -Name "ForceActiveDesktopOn" -Value "00000001"

#####Disable TLS 1.0#####
###Impact: An attacker can exploit cryptographic flaws to conduct man-in-the-middle type attacks or to decryption communications###
#Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Name "Enabled" -Value "00000000"
#Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client' -Name "DisabledByDefault" -Value "00000001"

#####Disable SSL v3 #######
###Impact: SL 3.0 is an obsolete and insecure protocol.
###Encryption in SSL 3.0 uses either the RC4 stream cipher, or a block cipher in CBC mode.
###RC4 is known to have biases, and the block cipher in CBC mode is vulnerable to the POODLE attack.
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -Name "DisabledByDefault" -Value "00000001"
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -Name "Enabled" -Value "00000000"

##### Disable RC4 Protocols#####
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128' -Name "Enabled" -Value "00000000"
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128' -Name "Enabled" -Value "00000000"
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128' -Name "Enabled" -Value "00000000"
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168' -Name "Enabled" -Value "00000000"
Set-ItemProperty -Path 'hklm:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168/168' -Name "Enabled" -Value "00000000"

##### 	Microsoft Windows FragmentSmack Denial of Service Vulnerability (ADV180022) #####
###Impact: A system under attack would become unresponsive with 100% CPU utilization but would recover as soon as the attack terminated. ###
Set-NetIPv4Protocol -ReassemblyLimit 0
Set-NetIPv6Protocol -ReassemblyLimit 0

####MS15-011 Hardening UNC Paths Breaks GPO Access -	Microsoft Group Policy Remote Code Execution Vulnerability (MS15-011) ######
###Impact: The vulnerability could allow remote code execution if an attacker convinces a user with a domain-configured system to connect to an attacker-controlled network ###
Set-ItemProperty -Path 'hklm:\SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths' -Name "\\*\netlogon" -Value "RequireMutualAuthentication=1, RequireIntegrity=1, RequirePrivacy=1"
Set-ItemProperty -Path 'hklm:\SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths' -Name "\\*\sysvol" -Value "RequireMutualAuthentication=1, RequireIntegrity=1, RequirePrivacy=1"

##### Windows Update for Credentials Protection and Management (Microsoft Security Advisory 2871997)
### IMPACT If this vulnerability is successfully exploited, attackers can steal credentials of the system. ###
Set-ItemProperty -Path 'hklm:\System\CurrentControlSet\Control\SecurityProviders\WDigest' -Name "UseLogonCredential" -Value "0"
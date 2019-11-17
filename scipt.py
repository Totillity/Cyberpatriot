import os
import sys
import ctypes
import subprocess

from abc import ABC, abstractmethod
from typing import List, IO, Callable, Union

if os.name == 'nt':
    import winreg


class Task(ABC):
    loggers: List[IO] = []
    show_commands: bool = False

    task_name: str

    @abstractmethod
    def check(self):
        raise NotImplementedError()

    @classmethod
    def log(cls, msg: str, start="", end="\n", flush=False):
        for logger in cls.loggers:
            logger.write(f"{start}While {cls.task_name}: {msg}{end}")
            if flush:
                logger.flush()

    @classmethod
    def progress_bar(cls, task: str, on: int, total: int):
        percent = on / total
        bars = int(80 * percent)
        bar = "[" + "=" * bars + " " * (80 - bars) + "]"
        cls.log(f"({int(percent*100):02d}%) {bar}", start="\r", end="", flush=True)

    @classmethod
    def error(cls, msg: str):
        print("Error: " + msg, file=sys.stderr)
        exit(0)

    @classmethod
    def warn(cls, msg: str):
        print(f"Warning: {msg}\n", file=sys.stderr)

    @classmethod
    def get_input(cls, prompt: str,
                  max_tries: float = float('inf'),
                  file: IO = sys.stdout,
                  validator: Union[Callable[[str], bool], str] = None):
        if validator is None:
            def validator(s: str) -> bool:
                if s.strip() != "":
                    return True
                else:
                    return False
        elif isinstance(validator, str):
            if validator == 'y/n':
                def validator(s: str) -> bool:
                    if s.lower() in ('y', 'n'):
                        return True
                    else:
                        return False
            else:
                raise ValueError('Validator str can only be one of "y/n".')

        tries = 0
        while tries < max_tries:
            print(prompt, file=file, end="")
            inp = input()
            if validator(inp):
                return inp
            else:
                tries += 1
        else:
            cls.error("Max tries exceeded")

    @classmethod
    def set_reg_key(cls, path: str, key: str, val):
        if isinstance(val, int):
            handle = winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, path)
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, path, 0, winreg.KEY_WRITE) as handle:
                winreg.SetValueEx(handle, key, 0, winreg.REG_DWORD, val)
        elif isinstance(val, str):
            handle = winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, path)
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, path, 0, winreg.KEY_WRITE) as handle:
                winreg.SetValueEx(handle, key, 0, winreg.REG_SZ, val)
        else:
            raise TypeError('Val must be a int or str')

    @classmethod
    def set_service(cls, service: str, enabled: bool, force_hide=False):
        cls.run(["sc", f"config", service, f"start={'enabled' if enabled else 'disabled'}"], force_hide=force_hide)
        if not enabled:
            cls.run([f"sc", "stop", service], force_hide=force_hide)

    @classmethod
    def disable_features(cls, features: List[str]):
        for feature in features:
            cls.run(["dism", "/online", "/disable-feature", f"/featurename:{feature}", "/NoRestart"])

    @classmethod
    def run(cls, s: List[str], force_hide=False):
        if cls.show_commands and not force_hide:
            return subprocess.run(s)
        else:
            return subprocess.run(s, stdout=subprocess.PIPE)


class InitTasks(Task):
    task_name = "Initializing Script"

    def __init__(self):
        inp = self.get_input("Log to screen? (y/n) ", validator=lambda s: s.lower() in ("y", "n"))
        if inp.lower() == "y":
            Task.loggers.append(sys.stdout)

        inp = self.get_input("Show Command Output? (y/n) ", validator=lambda s: s.lower() in ("y", "n"))
        Task.show_commands = inp.lower() == "y"

    def check(self):
        pass


class CheckOS(Task):
    task_name = "Checking OS"

    def __init__(self):
        pass

    def check(self):
        if os.name != 'nt':
            self.log("Failed (Not On Windows)")
            self.error("Not On Windows!")
        self.log("Passed (On Windows)")


class CheckPermissions(Task):
    task_name = "Checking Permissions"

    def __init__(self):
        pass

    def check(self):
        if ctypes.windll.shell32.IsUserAnAdmin() == 0:
            self.log("Failed (Not An Admin)")
            self.error("Not An Admin!")
        else:
            self.log("Passed (An Admin)")


class DisableRDP(Task):
    task_name = "Setting RDP"

    def __init__(self):
        inp = self.get_input("Disable RDP? (y/n) ", validator="y/n")
        if inp.lower() == "y":
            self.do = True
        else:
            self.do = False

    def check(self):
        if self.do:
            self.set_reg_key(r"SYSTEM\CurrentControlSet\Control\Terminal Server", r"fDenyTSConnections", 1)
            for service, enabled in {'iphlpsvc': False, 'umrdpservice': False, 'termservice': False}.items():
                self.set_service(service, enabled)
            self.log("Disabled RDP")
        else:
            self.set_reg_key(r"SYSTEM\CurrentControlSet\Control\Terminal Server", r"fDenyTSConnections", 0)
            self.set_reg_key(r"System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp",
                             "UserAuthentication", 1)

            self.log("Enabled RDP")

        self.set_reg_key(r"SYSTEM\ControlSet001\Control\Remote Assistance", "CreateEncryptedOnlyTickets", 1)
        self.set_reg_key(r"System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp",
                         "fDisableEncryption", 0)
        self.set_reg_key(r"SYSTEM\ControlSet001\Control\Remote Assistance", "fAllowFullControl", 0)
        self.set_reg_key(r"SYSTEM\ControlSet001\Control\Remote Assistance", "fAllowToGetHelp", 0)
        self.set_reg_key(r"System\CurrentControlSet\Control\Terminal Server", "AllowRemoteRPC", 0)


class EnableFirewall(Task):
    task_name = "Enabling Firewall"

    FIREWALL_CMD = """netsh advfirewall firewall set rule group="Connect" new enable=no
netsh advfirewall firewall set rule group="Contact Support" new enable=no
netsh advfirewall firewall set rule group="Cortana" new enable=no
netsh advfirewall firewall set rule group="DiagTrack" new enable=no
netsh advfirewall firewall set rule group="Feedback Hub" new enable=no
netsh advfirewall firewall set rule group="Microsoft Photos" new enable=no
netsh advfirewall firewall set rule group="OneNote" new enable=no
netsh advfirewall firewall set rule group="Remote Assistance" new enable=no
netsh advfirewall firewall set rule group="Windows Spotlight" new enable=no
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
netsh advfirewall firewall add rule name="block_WSearch_out" dir=out service="WSearch" action=block enable=yes"""

    def __init__(self):
        pass

    def check(self):
        total = len(self.FIREWALL_CMD.splitlines())
        for n, cmd in enumerate(self.FIREWALL_CMD.splitlines()):
            self.run(cmd.split())
            self.progress_bar(self.task_name, n, total)
        self.log("Done enabling firewall", start="\n")


class WeakStuff(Task):
    task_name = "Disabling Weak Programs"

    features = ['IIS-WebServerRole', 'IIS-WebServer', 'IIS-CommonHttpFeatures', 'IIS-HttpErrors', 'IIS-HttpRedirect',
                'IIS-ApplicationDevelopment', 'IIS-NetFxExtensibility', 'IIS-NetFxExtensibility45',
                'IIS-HealthAndDiagnostics', 'IIS-HttpLogging', 'IIS-LoggingLibraries', 'IIS-RequestMonitor',
                'IIS-HttpTracing', 'IIS-Security', 'IIS-URLAuthorization', 'IIS-RequestFiltering', 'IIS-IPSecurity',
                'IIS-Performance', 'IIS-HttpCompressionDynamic', 'IIS-WebServerManagementTools',
                'IIS-ManagementScriptingTools', 'IIS-IIS6ManagementCompatibility', 'IIS-Metabase',
                'IIS-HostableWebCore', 'IIS-StaticContent', 'IIS-DefaultDocument', 'IIS-DirectoryBrowsing',
                'IIS-WebDAV', 'IIS-WebSockets', 'IIS-ApplicationInit', 'IIS-ASPNET', 'IIS-ASPNET45', 'IIS-ASP',
                'IIS-CGI', 'IIS-ISAPIExtensions', 'IIS-ISAPIFilter', 'IIS-ServerSideIncludes', 'IIS-CustomLogging',
                'IIS-BasicAuthentication', 'IIS-HttpCompressionStatic', 'IIS-ManagementConsole',
                'IIS-ManagementService', 'IIS-WMICompatibility', 'IIS-LegacyScripts', 'IIS-LegacySnapIn',
                'IIS-FTPServer', 'IIS-FTPSvc', 'IIS-FTPExtensibility', 'TelnetClient', 'TFTP', 'TelnetServer']

    bitch_services = ['tapisrv', 'bthserv', 'mcx2svc', 'remoteregistry', 'seclogon', 'telnet', 'tlntsvr', 'p2pimsvc',
                      'simptcp', 'fax', 'msftpsvc', 'nettcpportsharing', 'iphlpsvc', 'lfsvc', 'bthhfsrv', 'irmon',
                      'sharedaccess', 'xblauthmanager', 'xblgamesave', 'xboxnetapisvc']

    def __init__(self):
        pass

    def check(self):
        total = len(self.features)
        for n, feature in enumerate(self.features):
            self.run(["dism", "/online", "/disable-feature", f"/featurename:{feature}", "/NoRestart"])
            self.progress_bar(self.task_name, n, total)
        self.log("Disabled weak services", start="\n")

        total = len(self.bitch_services)
        for n, bitch in enumerate(self.bitch_services):
            self.set_service(bitch, False)
            self.progress_bar(self.task_name, n, total)
        self.log("Burned processes at the stake", start="\n")


def main():
    tasks = [
        InitTasks,
        CheckOS,
        CheckPermissions,
        DisableRDP,
        EnableFirewall,
        WeakStuff,
    ]

    task_objs = []

    for task in tasks:
        if not hasattr(task, 'task_name'):
            Task.warn(f"{task.__name__} does not have the required attribute 'task_name'. Logging will error.")
            res = Task.get_input("OK? (y/n) ", file=sys.stderr, validator='y/n')
            if res.lower() == 'y':
                print("Okay. If you say so...", file=sys.stderr)
            else:
                Task.error("Time to fix it")
        obj = task()
        task_objs.append(obj)

    for task_obj in task_objs:
        task_obj.check()

    print("Script Done")


main()

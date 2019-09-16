#!/usr/bin/env bash

# TODO:
# 1. Implement security for nginx
# 2. Implement Bastille

mkdir avon avon/log avon/dump
logf=./avon/log/avon_$(date +%T).log
dump=./avon/dump
stdpass="TiredofWork50"

# Logging
log() {
  echo $(date +%T): $1 >> $logf
  echo $1
}

# Ensure script is running as root
if [ $EUID -ne 0 ]; then
  log "Run as root"
  exit 64
fi

# Automatic updates
autoupdate() {
  log "Enabling automatic updates"
  cat presets/auto-upgrades > /etc/apt/apt.conf.d/20auto-upgrades
}

# Secure sourcing for 14.04
sourcing_14() {
  log "Using most trustworthy sources in source.list"
  cat presets/14.04sources.list > /etc/apt/sources.list
}

# Secure sourcing for 16
sourcing_16() {
  log "Using most trustworthy sources in source.list"
  cat presets/16sources.list > /etc/apt/sources.list
}

# Secure sourcing for Debian Jessie (8)
sourcing_jessie() {
  log "Using most trustworthy sources in source.list"
  cat presets/jessiesources.list > /etc/apt/sources.list
}

# Secure sourcing for Debian Stretch (9)
sourcing_stretch() {
  log "Using most trustworthy sources in source.list"
  cat presets/stretchsources.list > /etc/apt/sources.list
}


# Install script dependencies
dependencies() {
  log "Installing dependencies"
  apt-get update
  apt-get -y install gufw synaptic libpam-cracklib clamav gnome-system-tools auditd audispd-plugins rkhunter chkrootkit iptables curl unattended-upgrades openssl libpam-tmpdir libpam-umask
  if [ $? = 100 ]; then
    log "FATAL: Vital apt-get is not working. Please fix and test before rerunning the script."
    exit 1
  fi
}

# Update Firefox
firefox() {
  log "Updating Firefox"
  killall firefox
  mv ~/.mozilla ~/.mozilla.old
  apt-get purge firefox
  apt-get install firefox
  log "Configuring Firefox"
  killall firefox
  cat presets/syspref.js > /etc/firefox/syspref.js
  su -c 'firefox -new-tab about:config' $SUDO_USER
}

# RKHunter
rkhunterrun() {
  rkhunter --update --propupd
}

# Configure hosts files
hosts() {
  if [ -s /etc/hosts ]; then
    log "Copying hosts file for convenience"
    cp /etc/hosts $dump/hosts
    log "Cleansing hosts file"
    cat presets/hosts > /etc/hosts
  fi
}

# Firewall
firewall() {
  log "Enabling firewall"
  ufw enable
}

# Disables Ctrl+Alt+Del
ctrlaltdel() {
  log "Disabling Ctrl+Alt+Del"
  sed -i '/^exec*/ c\exec false' /etc/init/control-alt-delete.conf
}

# /etc/rc.local has to contain only exit 0
rclocal() {
  log "Setting contents of /etc/rc.local to exit 0"
  echo "exit 0" > /etc/rc.local
}

# Configure telnet
telnet() {
  log "Configured telnet"
  ufw deny 23
  iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 23 -j DROP
  apt-get purge telnet
}

# Enable auditing
auditing() {
  log "Enabling auditing"
  auditctl -e 1
}

# Configure root password
rootpassword() {
  log "Changing the root password. Make sure you document it"
  passwd root
}

# Configure cron to allow root access only
cronrootonly() {
  log "Changing cron to only allow root access"
  crontab -r
  rm -f /etc/cron.deny at.deny
  echo root > /etc/cron.allow > /etc/at.allow
  chown root:root /etc/cron.allow /etc/at.allow
  chmod 644 /etc/cron.allow /etc/at.allow
}

# Disable guest account
disableguestacc() {
  log "Disabling the guest account"
  echo "[SeatDefaults]" > /etc/lightdm/lightdm.conf
  echo "greeter-session=unity-greeter" >> /etc/lightdm/lightdm.conf
  echo "user-session=ubuntu" >> /etc/lightdm/lightdm.conf
  echo "allow-guest=false" >> /etc/lightdm/lightdm.conf
}

# Password policies
passwordpolicies() {
  log "Enabling password policies"
  sed -i '/pam_unix.so/ s/$/ remember=5 minlen=8/g' /etc/pam.d/common-password
  sed -i '/pam_cracklib.so/ s/$/ ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1/g' /etc/pam.d/common-password
  sed -i '/PASS_MAX_DAYS/c\PASS_MAX_DAYS 90' /etc/login.defs
  sed -i '/PASS_MIN_DAYS/c\PASS_MIN_DAYS 10' /etc/login.defs
  sed -i '/PASS_WARN_AGE/c\PASS_WARN_AGE 7' /etc/login.defs
}

# Remove nullok from pam.d
nonullok() {
  log "Removing Nullok"
  sed -i 's/\<nullok_secure\>//g' /etc/pam.d/common-auth
  sed -i 's/\<nullok\>//g' /etc/pam.d/common-auth
  sed -i 's/\<nullok\>//g' /etc/pam.d/common-password
  sed -i 's/\<nullok_secure\>//g' /etc/pam.d/common-password
}

# Network configuration
networkconfig() {
  log "Securing network settings"
  echo "nospoof on" >> /etc/host.conf
  iptables -t nat -F
  iptables -t mangle -F
  iptables -t nat -X
  iptables -t mangle -X
  iptables -F
  iptables -X
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -A INPUT -s 0.0.0.0/8 -j DROP
  iptables -A INPUT -s 100.64.0.0/10 -j DROP
  iptables -A INPUT -s 169.254.0.0/16 -j DROP
  iptables -A INPUT -s 192.0.0.0/24 -j DROP
  iptables -A INPUT -s 192.0.2.0/24 -j DROP
  iptables -A INPUT -s 198.18.0.0/15 -j DROP
  iptables -A INPUT -s 198.51.100.0/24 -j DROP
  iptables -A INPUT -s 203.0.113.0/24 -j DROP
  iptables -A INPUT -s 224.0.0.0/3 -j DROP
  iptables -A INPUT -d 0.0.0.0/8 -j DROP
  iptables -A INPUT -d 100.64.0.0/10 -j DROP
  iptables -A INPUT -d 169.254.0.0/16 -j DROP
  iptables -A INPUT -d 192.0.0.0/24 -j DROP
  iptables -A INPUT -d 192.0.2.0/24 -j DROP
  iptables -A INPUT -d 198.18.0.0/15 -j DROP
  iptables -A INPUT -d 198.51.100.0/24 -j DROP
  iptables -A INPUT -d 203.0.113.0/24 -j DROP
  iptables -A INPUT -d 224.0.0.0/3 -j DROP
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -j ACCEPT
  iptables -A INPUT -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -j ACCEPT
  iptables -A INPUT -p tcp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT
  iptables -A INPUT -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT
  iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 23 -j DROP         #Block Telnet
  iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 2049 -j DROP       #Block NFS
  iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 2049 -j DROP       #Block NFS
  iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 6000:6009 -j DROP  #Block X-Windows
  iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 7100 -j DROP       #Block X-Windows font server
  iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 515 -j DROP        #Block printer port
  iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 515 -j DROP        #Block printer port
  iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 111 -j DROP        #Block Sun rpc/NFS
  iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 111 -j DROP        #Block Sun rpc/NFS
  iptables -A INPUT -p all -s localhost  -i eth0 -j DROP            #Deny outside packets from internet which claim to be from your loopback interface.
  iptables -A OUTPUT -d 0.0.0.0/8 -j DROP
  iptables -A OUTPUT -d 100.64.0.0/10 -j DROP
  iptables -A OUTPUT -d 169.254.0.0/16 -j DROP
  iptables -A OUTPUT -d 192.0.0.0/24 -j DROP
  iptables -A OUTPUT -d 192.0.2.0/24 -j DROP
  iptables -A OUTPUT -d 198.18.0.0/15 -j DROP
  iptables -A OUTPUT -d 198.51.100.0/24 -j DROP
  iptables -A OUTPUT -d 203.0.113.0/24 -j DROP
  iptables -A OUTPUT -d 224.0.0.0/3 -j DROP
  iptables -A OUTPUT -s 0.0.0.0/8 -j DROP
  iptables -A OUTPUT -s 100.64.0.0/10 -j DROP
  iptables -A OUTPUT -s 169.254.0.0/16 -j DROP
  iptables -A OUTPUT -s 192.0.0.0/24 -j DROP
  iptables -A OUTPUT -s 192.0.2.0/24 -j DROP
  iptables -A OUTPUT -s 198.18.0.0/15 -j DROP
  iptables -A OUTPUT -s 198.51.100.0/24 -j DROP
  iptables -A OUTPUT -s 203.0.113.0/24 -j DROP
  iptables -A OUTPUT -s 224.0.0.0/3 -j DROP
  iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
  iptables -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -P OUTPUT DROP
  iptables -P OUTPUT ACCEPT
  ufw deny 2049
  ufw deny 515
  ufw deny 111
}

# Secure boot password
securebootpassword() {
  log "Enabling password for secure boot"
  sed -i 's/\/sbin\/sushell/\/sbin\/sulogin/g' /lib/systemd/system/emergency.service
  sed -i 's/\/sbin\/sushell/\/sbin\/sulogin/g' /lib/systemd/system/rescue.service
}

# Enable grub password
grubpassword() {
  log "Enabling password for grub boot loader"
  passwordHash=$(echo -e "$stdpass\n$stdpass" | grub-mkpasswd-pbkdf2 | cut -c 33-)
  echo -e '\ncat <<EOF\nset superusers="Admin"\npassword_pbkdf2 Admin'$passwordHash'\nEOF' >> /etc/grub.d/00_header
  update-grub
  chown root:root /boot/grub/grub.cfg
  log "Set password for grub boot loader. Username: Admin Password: $stdpass"
}

initramfs() {
  log "Disabling root prompt on initramfs and Disabling Ipv6 for Grub"
  sed -i 's/GRUB_CMDLINE_LINUX="".*/GRUB_CMDLINE_LINUX="panic=0 ipv6.disable=1 quiet splash"/g' /etc/default/grub
}

prebootsecurity() {
  securebootpassword
  grubpassword
  initramfs
}

# Disable coredumps
disablecoredumps() {
  log "Disabling coredumps"
  echo "* hard core 0" >> /etc/security/limits.conf
  echo 'fs.suid_dumpable = 0' >> /etc/sysctl.conf
  sysctl -p
  echo 'ulimit -S -c 0 > /dev/null 2>&1' >> /etc/profile
}

# Sysctl settings
sysctlsecurity() {
  log "Altering sysctl for security"
  cp presets/sysctl.conf /etc/sysctl.conf
}

sysctlconfiguration() {
  disablecoredumps
  sysctlsecurity
  sysctl -p
}

# Remove unwanted media
# Helper function `mediawarrant`
mediawarrant() {
  log "Searching for $1 files out outputting to file for forensic question answers"
  find / -type f -not -iname 'CP*_Background*.png' -not -path '/*/.cache/*' -not -path '/usr/*' -not -path '/var/lib/app-info/icons/*' -not -path '/opt/*' -not -path '/lib/*' -name \*.$1 -ls 2> /dev/null > $dump/$1\files
  find / -type f -not -iname 'CP*_Background*.png' -not -path '/*/.cache/*' -not -path '/usr/*' -not -path '/var/lib/app-info/icons/*' -not -path '/opt/*' -not -path '/lib/*' -name \*.$1 -print0 2> /dev/null | xargs -0 rm -rf
}
unwantedmedia() {
  mediawarrant png
  mediawarrant jpg
  mediawarrant mp4
  mediawarrant mp3
  mediawarrant mov
  mediawarrant avi
  mediawarrant mpg
  mediawarrant mpeg
  mediawarrant flac
  mediawarrant m4a
  mediawarrant flv
  mediawarrant ogg
  mediawarrant gif
  mediawarrant jpeg
}

# Copy & parse README
automaticusersprep() {
  log "Copying & parsing README"
  touch $dump/readme
  chmod 777 $dump/readme

  readmeurl=`cat /home/$SUDO_USER/Desktop/README.desktop | grep -o '".*"' | tr -d '"'`
  readmeurl=${readmeurl:4}
  readmeurl="https"$readmeurl
  curl $readmeurl -k > $dump/readme
}

# Remove unauthorized users
unauthorizedusers() {
  log "Checking and removing unauthorized users"
  cut -d: -f1,3 /etc/passwd | egrep ':[0-9]{4}$' | cut -d: -f1 > $dump/usersover1000
  echo root >> $dump/usersover1000
  echo > $dump/removedusers
  for user in `cat $dump/usersover1000`; do
  	if [ $user = "root" ]; then
  		log ROOT FOUND
  	else
  		cat $dump/readme | grep ^$user
  		if [ $? = 1 ]; then
  			log "$user is unauthorized. Removing..."
  			userdel $user
  			echo "$user has been removed from the system" >> $dump/removedusers
        log "$user has been removed from the system"
  		fi
  	fi
  done
}

# Remove unauthorized administrators
unauthorizedadministrators() {
  log "Checking and removing unauthorized administrators"
  cat $dump/readme | sed -n '/Authorized Administrators/,/Authorized Users/p' > $dump/authadmin
  touch $dump/adminusers
  chmod 777 $dump/adminusers
  cat /etc/group | grep sudo | cut -c 11- | tr , '\n' > $dump/adminusers
  echo "" > $dump/demotedadmins
  chmod 777 $dump/demotedadmins
  for user in `cat $dump/adminusers`; do
  	cat $dump/authadmin | grep ^$user
  	if [ $? = 1 ]; then
  		log $user is not supposed to be an admin. Demoting $user
  		deluser $user
  		echo The admin privileges of $user has been revoked >> $dump/demotedadmins
      log The admin privileges of $user has been revoked
  	fi
  done
}

# Change user passwords
changeuserpasswords() {
  log "Changing passwords of all users"
  cat $dump/readme | sed -n '/Authorized Administrators/,/Authorized Users/p' > $dump/authadminpass
  for user in `cat $dump/usersover1000`; do
    echo -e "$stdpass\n$stdpass" | passwd $user
    echo "$user: $stdpass" >> $dump/changedpasswords
  done
}

# Automatic users
automaticusers() {
  automaticusersprep
  unauthorizedusers
  unauthorizedadministrators
  changeuserpasswords
}

# Checking for any user who has a UID of 0 and is not a root and removing
uidcheck() {
  log "Checking for 0 UID users other than root and removing"
  touch $dump/zeroUIDUsers
  touch $dump/UIDUsers

  cut -d: -f1,3 /etc/passwd | egrep ':0$' | cut -d: -f1 | grep -v root > $dump/zeroUIDUsers
  if [ -s $dump/zeroUIDUsers ]
  	then
  		echo "Found 0 UID. Fixing now."

  		while IFS='' read -r line || [[ -n "$line" ]]; do
  			thing=1
  			while true; do
  				rand=$((RANDOM%999+1000))
  				cut -d: -f1,3 /etc/passwd | egrep ":$rand$" | cut -d: -f1 > $dump/UIDUsers
  				if [ -s $dump/UIDUsers ]
  				then
  					echo "Couldn't find unused UID. Trying Again..."
            continue
  				else
  					break
  				fi
  			done
  			usermod -u $rand -g $rand -o $line
  			touch $dump/oldstring
  			old=$(grep "$line" /etc/passwd)
  			echo $old > $dump/oldstring
  			sed -i "s~0:0~$rand:$rand~" $dump/oldstring
  			new=$(cat $dump/oldstring)
  			sed -i "s~$old~$new~" /etc/passwd
  			log "ZeroUID User: $line"
  			log "Assigned UID: $rand"
  		done < "/zeroUIDUsers"
  		cut -d: -f1,3 /etc/passwd | egrep ':0$' | cut -d: -f1 | grep -v root > $dump/zeroUIDUsers

  		if [ -s $dump/zeroUIDUsers ]
  		then
  			echo "WARNING: UID CHANGE UNSUCCESSFUL!"
  		else
  			echo "Successfully Changed Zero UIDs!"
  		fi
  	else
  		echo "No Zero UID Users"
  	fi
}

# Pure FTPD Configuration
pureftpd() {
  log "Evaluating compulsory status of pure-ftpd"
  cat $copydir/readme | grep -w 'pure-ftpd'
  if [ $? = 0 ]; then
    apt-get install -y pure-ftpd
    mkdir /etc/ssl/private
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem -days 365 -subj "/C=US/ST=Colorado/L=Denver/O=Team Helix/OU=Linux Department/CN=teamhelix.me"
    echo "2" > /etc/pure-ftpd/conf/TLS
    service pure-ftpd start
    service pure-ftpd restart
    log "Installed and secured pure-ftpd"
  else
    apt-get purge -y pure-ftpd
    apt-get autoremove
    log "Removed pure-ftpd as not required"
  fi
}

# VSFTP Configuration
vsftp() {
  if $vsftp = "y" ; then
    # Disable anonymous uploads
    sed -i '/^anon_upload_enable/ c\anon_upload_enable no' /etc/vsftpd.conf
    sed -i '/^anonymous_enable/ c\anonymous_enable=NO' /etc/vsftpd.conf
    # FTP user directories use chroot
    sed -i '/^chroot_local_user/ c\chroot_local_user=YES' /etc/vsftpd.conf
    service vsftpd restart
  else
    apt-get purge -y vsftpd
  fi
}

# MySQL Configuration
mysql() {
  if $mysql = "y"; then
    # Disable remote access
    sed -i '/bind-address/ c\bind-address = 127.0.0.1' /etc/mysql/my.cnf
    service mysql restart
  else
    apt-get purge -y mysql*
  fi
}

# Apache2 Configuration
apachetwo() {
  if $apachetwo = "y"; then
    cat presets/apache2.conf >> /etc/apache2/apache2.conf
    a2enmod userdir

  	chown -R root:root /etc/apache2
  	chown -R root:root /etc/apache

    a2enmod rewrite

    apt-get -y install libapache2-mod-evasive
    mkdir /var/log/mod_evasive

    chown www-data:www-data /var/log/mod_evasive

    cat presets/mod-evasive.conf >> /etc/apache2/mods-available/mode-evasive.conf

    a2enmod evasive

    apt-get -y install libapache2-mod-security2

    a2enmod security2

    sed -i 's/ServerToken.*/ServerTokens Prod/g' /etc/apache2/conf-enabled/security.conf
    sed -i 's/ServerSignature.*/ServerSignature Off/g' /etc/apache2/conf-enabled/security.conf
    sed -i 's/TraceEnable.*/TraceEnable Off/g' /etc/apache2/conf-enabled/security.conf

    sed -r -i -e 's|^([[:space:]]*)</Directory>|\1\tOptions -Includes\n\1\tOptions -FollowSymLinks\n\1</Directory>|g' /etc/apache2/apache2.conf
    sed -r -i -e 's|^([[:space:]]*)</Directory>|\1\tLimitRequestBody 512000\n\1\tOptions -FollowSymLinks\n\1</Directory>|g' /etc/apache2/apache2.conf
    sed -r -i -e 's|^([[:space:]]*)</Directory>|\n\1\t<LimitExcept GET POST HEAD>\n\1\t\tdeny from all\n\1\t</LimitExcept>\n\n</Directory>|g' /etc/apache2/apache2.conf

    service apache2 restart
  else
    apt-get purge -y apache2
  fi
}

# PHP Configuration
phpconfiguration() {
  if $php = "y" ; then
    log "Make sure you go to the Application Checklists document and go through the checklist for PHP. Press enter to continue"
    read trash
    php Meta/phpconfigcheck.php -a -h > $copydir/phpSecurity.html
  else
    apt-get purge -y *php*
  fi
}

# Bind9 Configuration
bindnine() {
  if $bindnine = "y"; then
    apt-get update bind9 bind9-host
    ps aux | grep bind | grep -v '^root' # Ensure Bind9 is running with non-root account
    # Permission and ownership modifications
    chown -R root:bind /etc/bind
    chown root:bind /etc/bind/named.conf*
    chmod 640 /etc/bind/named.conf*
    echo -e "allow-recursion { localhost; 192.168.0.0/24; };\nallow-query { localhost; 192.168.0.0/24; };\nallow-transfer { 192.168.1.1; };\nlisten-on port 53 { 127.0.0.1; 192.168.1.1; };" >> /etc/bind/named.conf.options
    service bind9 restart
  else
    apt-get purge -y bind9
  fi
}

# nginx Configuration
nginx() {
  if $nginx = "y" ; then
    # Check TODO #3 at the top
    continue
  else
    apt-get purge -y nginx
  fi
}

# SSH Configuration
sshservice() {
  log "Evaluating compulsory status of SSHD"
  cat $dump/readme | grep -w 'ssh\|SSH'
  if [ $? = 0 ]; then
      apt-get install -y openssh-server
      sed -i 's/PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
      sed -i 's/Protocol.*/Protocol 2/g' /etc/ssh/sshd_config
      sed -i 's/X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
      sed -i 's/AllowTcpForwarding.*/AllowTcpForwarding no/g' /etc/ssh/sshd_config
      sed -i 's/LogLevel.*/LogLevel VERBOSE/g' /etc/ssh/sshd_config
      sed -i 's/PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config

      # Users
      groupadd sshusers
      cut -d: -f1,3 /etc/passwd | egrep ':[0-9]{4}$' | cut -d: -f1 > $dump/usersover1000
      for user in `cat $dump/usersover1000`; do
      	cat $dump/readme | grep ^$user
      	if [ $? = 0 ]; then
    			usermod -a -G sshusers $user
      	fi
      done
      echo "AllowGroups sshusers" >> /etc/ssh/sshd_config


      service sshd start
      service sshd restart
      log "Installed and secured SSH"
  else
      apt-get purge -y openssh-server
      apt-get autoremove
      log "Removed SSH as not required"
  fi
}

serviceconfiguration() {
  pureftpd
  vsftp
  mysql
  apachetwo
  phpconfiguration
  bindnine
  nginx
  sshservice
}

# Kill CUPS (DANGEROUS! THIS IS A *LAST CASE* RESORT)
killcups() {
  log "Killing cups"
  # CUPSD
  systemctl disable cups.socket cups.path cups.service
  systemctl kill --signal=SIGKILL cups.service
  systemctl stop cups.socket cups.path

  # CUPS-BROWSED
  systemctl disable cups-browsed
  systemctl stop cups-browsed
}

# Kill Avahi Daemon
killavahidaemon() {
  log "Killing Avahi Daemon"
  systemctl disable avahi-daemon.socket avahi-daemon.service
  systemctl stop avahi-daemon.socket avahi-daemon.service
}

# Purging the badness
purges() {
  apt-get purge -y john* ophcrack minetest nmap wireshark netcat* polari rpcbind
  apt-get purge -y transmission-gtk empathy mutt freeciv kismet hydra* nikto* xinetd
  apt-get purge -y squid minetest p0f minetest-server
}

# Updates
updates() {
  apt-get autoremove
  apt-get update
  apt-get upgrade
}

# Establish configuration variables
configvars() {

  echo "Secure VSFTP? (y/n)\t"
  read vsftp

  echo "Secure MySQL (y/n)\t"
  read mysql

  echo "Secure Apache2 (y/n)\t"
  read apachetwo

  echo "Secure PHP (y/n)\t"
  read php

  echo "Secure Bind9 (y/n)\t"
  read bindnine

  echo "Secure nginx (y/n)\t"
  read nginx
}

avon_generic() {
  configvars
  autoupdate
  dependencies
  firefox
  rkhunterrun
  hosts
  firewall
  ctrlaltdel
  rclocal
  telnet
  auditing
  rootpassword
  cronrootonly
  disableguestacc
  passwordpolicies
  nonullok
  networkconfig
  securebootpassword
  grubpassword
  initramfs
  prebootsecurity
  disablecoredumps
  sysctlsecurity
  sysctlconfiguration
  unwantedmedia
  automaticusers
  uidcheck
  serviceconfiguration
  killavahidaemon
  purges
  updates
  bindnine
}

avon_ubuntu14() {
  avon_generic
  sourcing_14
}

avon_ubuntu16() {
  avon_generic
  sourcing_16
}

avon_debian() {
  avon_generic
  sourcing_jessie # CP generally uses Debian 8 (Jessie)
}


currentoperatingsystem=`cat /etc/os-release | grep "PRETTY_NAME" | grep -o '".*"' | sed 's/"//g'`

if [[ $currentoperatingsystem == *14.04* ]]; then
  ubuntu14
fi

if [[ $currentoperatingsystem == *16.04* ]]; then
  ubuntu16
fi

if [[ $currentoperatingsystem == *Debian* ]]; then
  debian
fi

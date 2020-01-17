#!/bin/bash

############################################
### CLOUD BASED DEBIAN INITIALISATION    ###
### VERSION: 0.1                         ###
### TWITTER: @jeffreyshran               ###
### GITHUB:  github.com/JeffreyShran     ###
############################################

### Initial script idea and some techniques taken from:
### https://www.digitalocean.com/community/tutorials/automating-initial-server-setup-with-ubuntu-18-04
### https://dotnetrussell.com/SetupBare.sh
### https://unix.stackexchange.com/a/434061
###
### VNC Tested on UltraVNC: https://www.uvnc.com/downloads/ultravnc/126-download-ultravnc-1224.html
###
### To execute the script, run the below command. Taken from - https://askubuntu.com/a/992451 
### -O -  Allows us to output to nowhere and into the bash pipe.
### wget -O - https://raw.githubusercontent.com/JeffreyShran/Snippets/master/fresh-debian-setup.sh | sudo bash

### This helps us to keep the script tidy in respect to error handling ###
# -e exits as soon as any line in the bash script fails.
# -x prints each command that is going to be executed.
set -e

### Needs root access to continue ###
# id -u used as POSIX compliant: https://askubuntu.com/a/30157
if ! [ $(id -u) = 0 ] > /dev/null 2>&1; then
   echo "This script needs to be ran as interactive root. Switch to 'sudo -i' and try again."
   exit 1
fi

### Change the frontend default behaviour of debconf to noninteractive ###
# This helps to make the installs and updates etc non-interactive. (i.e You don't get asked questions)
# Otherwise you have to run something like this each time as the noninteractive will not persist: sudo DEBIAN_FRONTEND=noninteractive apt-get install slrn.
dpkg-reconfigure debconf --frontend=noninteractive

### Update, upgrade and clean up ###
# -qq should imply -y but didn't work under testing so using -qy here. TODO: Why not?
apt update -qy && apt upgrade -qy && apt autoremove -qy

### Remove ~/.bash_aliases and recreate from GitHub file. These are personalised bash commands and entirely optional. ###
# -q Quiet.
# -O Output file.
rm ~/.bash_aliases
wget -q https://raw.githubusercontent.com/JeffreyShran/Snippets/master/bash_aliases -O ~/.bash_aliases

### Install core utilities. The for loop will check if the application exists before attempting an install ###
# Script from - https://unix.stackexchange.com/a/434061
CORE_PROGRAMS=(git curl sudo) # Sometimes curl is missing from base installs.

for PROGRAM in "${CORE_PROGRAMS[@]}"; do
    if ! command -v "$CORE_PROGRAMS" > /dev/null 2>&1; then
        apt-get install "$CORE_PROGRAMS" -qy
        echo "Installed $CORE_PROGRAMS"
    fi
    echo "$CORE_PROGRAMS already installed"
done

### Setup & install golang ###
# $(..) is command Substitution and is equivalent to `..`. Basically meaning to execute the command within. See "man bash".
ORIGINAL_GO=$(which go)
rm $ORIGINAL_GO
cd ~
VERSION=$(curl https://golang.org/VERSION?m=text) # Returns in form of "go1.13.5"
wget https://dl.google.com/go/$VERSION.linux-amd64.tar.gz
tar -C /usr/local -xzf $VERSION.linux-amd64.tar.gz
echo "export GOPATH=~/go" >> ~/.profile # source intentionally not used here as it appears on next line.
echo "export PATH='$PATH':/usr/local/go/bin:$GOPATH/bin" >> ~/.profile && source ~/.profile
rm $VERSION.linux-amd64.tar.gz
echo "Installed golang"

### Install everything else. The for loop will check if the application exists before attempting an install ###
PROGRAMS=(xfce4 xfce4-goodies gnome-icon-theme tightvncserver iceweasel)

for PROGRAM in "${PROGRAMS[@]}"; do
    if ! command -v "$PROGRAMS" > /dev/null 2>&1; then
        apt-get install "$PROGRAMS" -qy
        echo "Installed $PROGRAMS"
    fi
    echo "$PROGRAMS already installed"
done

### Setup VNC ###
# Generate a random password for later
AUTO_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
# Create new user 'vnc'
useradd --create-home --shell "/bin/bash" --groups sudo vnc # --create-home intentionally used for practicality purposes
# Set 'vnc'' users password
echo -e "$AUTO_PASSWORD\n$AUTO_PASSWORD" | passwd vnc
# Running next commands as vnc user until 2nd EOF: https://www.cyberciti.biz/faq/how-to-run-multiple-commands-in-sudo-under-linux-or-unix/
sudo -u vnc -- sh -c <<EOF
echo -e "$AUTO_PASSWORD\n$AUTO_PASSWORD" | vncpasswd
# Start vncserver. Connections are on port 5901. Your second display will be served on port 5902. Running now to auto Initialise some files.
vncserver
# To stop your VNC server on Display 1 - We're stopping here to make changes to systemd.
vncserver -kill :1
# Creating a systemd Service to Start VNC Server Automatically
# Our script will help us to modify settings and start/stop VNC Server easily
echo "[label /usr/local/bin/myvncserver] #!/bin/bash PATH="$PATH:/usr/bin/" DISPLAY="1" DEPTH="16" GEOMETRY="1024x768" OPTIONS="-depth ${DEPTH} -geometry ${GEOMETRY} :${DISPLAY}" case "$1" in start) /usr/bin/vncserver ${OPTIONS} ;; stop) /usr/bin/vncserver -kill :${DISPLAY} ;; restart) $0 stop $0 start ;; esac exit 0" > /usr/local/bin/myvncserver
# Make our file executable
chmod +x /usr/local/bin/myvncserver
#
# If you'd like, you can call the script manually to start/stop VNC Server on port 5901 with your desired configuration:
#   sudo /usr/local/bin/myvncserver start
#   sudo /usr/local/bin/myvncserver stop
#   sudo /usr/local/bin/myvncserver restart
#
# We can now create a unit file for our service. Unit files are used to describe services and tell the computer what to do to start/stop or restart the service.
echo "[label /lib/systemd/system/myvncserver.service] [Unit] Description=Manage VNC Server on this droplet [Service] Type=forking ExecStart=/usr/local/bin/myvncserver start ExecStop=/usr/local/bin/myvncserver stop ExecReload=/usr/local/bin/myvncserver restart User=vnc [Install] WantedBy=multi-user.target" > /lib/systemd/system/myvncserver.service
#Now we can reload systemctl and enable our service
systemctl daemon-reload
systemctl enable myvncserver.service
#
# You've enabled your new service now. Use these commands to start, stop or restart the service using the systemctl command
#   sudo systemctl start myvncserver.service
#   sudo systemctl stop myvncserver.service
#   sudo systemctl restart myvncserver.service
#
EOF

### Connection string from powershell to cloud server: https://www.revsys.com/writings/quicktips/ssh-tunnel.html
# ssh -f user@personal-server.com -L 2000:personal-server.com:25 -N

### FEEDBACK FOR USER ###
echo "Your VNC and 'vnc' users password are both set to $AUTO_PASSWORD - WRITE IT DOWN OR CHANGE THEM NOW!!"
echo "As root:"
echo "  Run 'passwd vnc' to set the users password."
echo "  Run 'vncpasswd' to set the VNC one."

#####################
### END OF SCRIPT ###
#####################
#!/bin/bash

############################################
### CLOUD BASED DEBIAN INITIALISATION    ###
### VERSION: 0.1                         ###
### TWITTER: @jeffreyshran               ###
### GITHUB:  github.com/JeffreyShran     ###
############################################

#---------------------------------------------------------------------------------------------------------------------------------------------------
# Initial script idea and some techniques taken from:
#    https://www.digitalocean.com/community/tutorials/automating-initial-server-setup-with-ubuntu-18-04
#    https://dotnetrussell.com/SetupBare.sh
#    https://unix.stackexchange.com/a/434061
#
# VNC Tested on UltraVNC:
#    https://www.uvnc.com/downloads/ultravnc/126-download-ultravnc-1224.html
#
# To execute the script, run the below command. Taken from - https://askubuntu.com/a/992451. "-O -" Allows us to output to nowhere and into the bash pipe.
#    wget -O - https://raw.githubusercontent.com/JeffreyShran/Snippets/master/fresh-debian-setup.sh | sudo bash
#---------------------------------------------------------------------------------------------------------------------------------------------------

# This helps us to keep the script tidy in respect to error handling
# -e exits as soon as any line in the bash script fails.
# -x prints each command that is going to be executed.
set -x

# Needs root access to continue
if ! [ $(id -u) = 0 ] > /dev/null 2>&1; then                                  # id -u used as POSIX compliant: https://askubuntu.com/a/30157
   echo "This script needs to be ran as interactive root. Switch to 'sudo -i' and try again."
   exit 1
fi

# Change the frontend default behaviour of debconf to noninteractive
# This helps to make the installs and updates etc non-interactive.
# (i.e You don't get asked questions)
# Otherwise you have to run something like this each time as the 
# noninteractive will not persist:
#     sudo DEBIAN_FRONTEND=noninteractive apt-get install slrn.
dpkg-reconfigure debconf --frontend=noninteractive

# Update, upgrade and clean up
apt update -qy && apt upgrade -qy && apt autoremove -qy                       # -qq should imply -y but didn't work under testing so using -qy here. TODO: Why not?

# Remove ~/.bash_aliases and recreate from GitHub file.
# These are personalised bash commands and entirely optional
rm -f ~/.bash_aliases                                                         # -f will ignore nonexistent files, never prompt.
wget -q https://raw.githubusercontent.com/JeffreyShran/Snippets/master/bash_aliases -O ~/.bash_aliases # -q Quiet -O Output file.

# Install core utilities.
# dpkg will check if the application exists before attempting an install
pkgs='git curl sudo xfce4 xfce4-goodies gnome-icon-theme tightvncserver iceweasel' # Sometimes curl is missing from base installs.
if ! dpkg -s $pkgs >/dev/null 2>&1; then                                      # Script from - https://stackoverflow.com/a/54239534 dpkg -s exits with status 1 if any of the packages is not installed
  sudo apt-get install -qy $pkgs                                              # TODO: One of these pkgs asks us to set the keyboard language.
fi

# Setup & install golang
if ! [[ $(which go) ]]; then                                                  # $(..) is command Substitution and is equivalent to `..`. Basically meaning to execute the command within. See "man bash".
   rm $(which go)                                                             # remove  current golang if exists
fi
cd ~
VERSION=$(curl https://golang.org/VERSION?m=text)                              # Returns in form of "go1.13.5"
wget https://dl.google.com/go/$VERSION.linux-amd64.tar.gz
tar -C /usr/local -xzf $VERSION.linux-amd64.tar.gz
echo "export GOPATH=~/go" >> ~/.profile                                        # source intentionally not used here as it appears on next line.
echo "export PATH='$PATH':/usr/local/go/bin:$GOPATH/bin" >> ~/.profile && source ~/.profile
rm $VERSION.linux-amd64.tar.gz

# Setup VNC
AUTOPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) # Generate a random password for later
useradd --create-home --shell "/bin/bash" --groups sudo vnc                    # Create new user 'vnc'--create-home intentionally used for practicality purposes
echo -e "$AUTOPASSWORD\n$AUTOPASSWORD" | passwd vnc                            # Set 'vnc'' users passwords for linux user
home_directory="/home/vnc"                                                     # Create SSH directory for sudo user

# Configure VNC password
umask 0077                                                                     # use safe default permissions
mkdir -p "$HOME/.vnc"                                                          # create config directory
chmod go-rwx "$HOME/.vnc"                                                      # enforce safe permissions
vncpasswd -f <<<"$AUTOPASSWORD" >"$HOME/.vnc/passwd"                           # generate and write a password

# Start vncserver. Connections are on port 5901.
# Your second display will be served on port 5902.
# Running now to auto Initialise some files.
vncserver
# To stop your VNC server on Display 1.
# We're stopping here to make changes to systemd.
vncserver -kill :1
# Creating a systemd Service to Start VNC Server Automatically
mkdir --parents "${home_directory}/.ssh"                                       # Create sudo user ssh key location
cp /root/.ssh/authorized_keys "${home_directory}/.ssh"                         # Copy authorized_keys file from root
chmod 0700 "${home_directory}/.ssh"                                            # Adjust SSH configuration permissions
chmod 0600 "${home_directory}/.ssh/authorized_keys"                            # Adjust SSH configuration permissions
chown --recursive "vnc:vnc" "${home_directory}/.ssh"                           # Adjust SSH configuration ownership
# Configure Universal Firewall
ufw allow OpenSSH                                                              # Add firewall exception for SSH
ufw --force enable                                                             # Enable UFW firewall

# Our script will help us to modify settings and start/stop VNC Server easily
echo "[label /usr/local/bin/myvncserver] #!/bin/bash PATH="$PATH:/usr/bin/" DISPLAY="1" DEPTH="16" GEOMETRY="1024x768" OPTIONS="-depth ${DEPTH} -geometry ${GEOMETRY} :${DISPLAY}" case "$1" in start) /usr/bin/vncserver ${OPTIONS} ;; stop) /usr/bin/vncserver -kill :${DISPLAY} ;; restart) $0 stop $0 start ;; esac exit 0" > /usr/local/bin/myvncserver
chmod +x /usr/local/bin/myvncserver                                            # Make our file executable

# We can now create a unit file for our service.
# Unit files are used to describe services and tell the
# computer what to do to start/stop or restart the service.
echo "[label /lib/systemd/system/myvncserver.service] [Unit] Description=Manage VNC Server on this droplet [Service] Type=forking ExecStart=/usr/local/bin/myvncserver start ExecStop=/usr/local/bin/myvncserver stop ExecReload=/usr/local/bin/myvncserver restart User=vnc [Install] WantedBy=multi-user.target" > /lib/systemd/system/myvncserver.service
systemctl daemon-reload                                                        # Now we can reload systemctl
systemctl enable myvncserver.service                                           # and enable our service

#---------------------------------------------------------------------------------------------------------------------------------------------------
# You've enabled your new service now. Use these commands to start, stop or restart the service using the systemctl command
#   sudo systemctl start myvncserver.service
#   sudo systemctl stop myvncserver.service
#   sudo systemctl restart myvncserver.service
#
# Connection string from powershell to cloud server: https://www.revsys.com/writings/quicktips/ssh-tunnel.html
#    ssh -f vnc@your_server_ip -L 5901:localhost:5901
#-----------------------------------------------------------------------------------------------------------------------------------------------------

# Feedback for the user
echo "Your VNC and 'vnc' users password are both set to $AUTOPASSWORD - WRITE IT DOWN OR CHANGE THEM NOW!!"
echo "As root:"
echo "Run 'passwd vnc' to set the users password."
echo "Run 'vncpasswd' to set the VNC one."

#####################
### END OF SCRIPT ###
#####################
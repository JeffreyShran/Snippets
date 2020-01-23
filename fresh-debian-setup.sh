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
# To execute the script, run the below command.
# Taken from - https://askubuntu.com/a/992451. "-O -" Allows us to output to nowhere and into the bash pipe. Frequent runs cause caching so added date var.
#    wget --no-cache -O - "https://raw.githubusercontent.com/JeffreyShran/Snippets/master/fresh-debian-setup.sh?$(date +%s)" | bash
#---------------------------------------------------------------------------------------------------------------------------------------------------

# This helps us to keep the script tidy in respect to error handling
# -e exits as soon as any line in the bash script fails
# -x prints each command that is going to be executed
#set -x

# Needs root access to continue
if ! [ $(id -u) = 0 ] >/dev/null 2>&1; then # id -u used as POSIX compliant: https://askubuntu.com/a/30157
  echo "This script needs to be ran as interactive root. Switch to 'sudo -i' and try again."
  exit 1
fi

# Change the frontend default behaviour of debconf to noninteractive
# This helps to make the installs and updates etc non-interactive
# (i.e You don't get asked questions)
# Otherwise you have to run something like this each time as the
# noninteractive will not persist:
#     sudo DEBIAN_FRONTEND=noninteractive apt-get install slrn
dpkg-reconfigure debconf --frontend=noninteractive

# Setup Kali repositories, mainly for burp.
wget -q -O - archive.kali.org/archive-key.asc | sudo apt-key add -
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list;
echo "deb-src http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list;

# Create directory structure
mkdir -p ~/hack_the_planet/{reconnaissance,scripts,tools,wordlists}

# Setup requirements for Docker
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
# Add Docker repository
apt-get remove docker docker-engine docker.io containerd runc # Older versions of Docker were called docker, docker.io, or docker-engine. If these are installed, uninstall them
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - # Add Docker’s official GPG key
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" # set up the stable repository

# Update, upgrade and clean up
apt update -qy && apt upgrade -qy && apt autoremove -qy # -qq should imply -y but didn't work under testing so using -qy here. TODO: Why not?

# Remove ~/.bash_aliases and recreate from GitHub file.
# These are personalised bash commands and entirely optional
rm -f ~/.bash_aliases                                                                                  # -f will ignore nonexistent files, never prompt.
wget -q https://raw.githubusercontent.com/JeffreyShran/Snippets/master/bash_aliases -O ~/.bash_aliases # -q Quiet -O Output file

# Install core utilities
# dpkg will check if the application exists before attempting an install
pkgs='
burpsuite
git
iceweasel
openjdk-8-jre
sudo
task-kde-desktop
tightvncserver
x2goserver
x2goserver-xsession
'
if ! dpkg -s $pkgs >/dev/null 2>&1; then # Script from - https://stackoverflow.com/a/54239534 dpkg -s exits with status 1 if any of the packages is not installed
  sudo apt-get install -qy $pkgs
fi

# Setup & install golang
# Debian sources are out of date so we need to sort it out manually
function version() { # https://apple.stackexchange.com/a/123408 - You need to define functions in advance of you calling them in your script
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

AVAILABLEVERSION=$(curl -s https://golang.org/VERSION?m=text) # Returns in form of "go1.13.5"

function installGoFromTheGOOG() { # Pulls down latest golang direct from Google and sets PATH / GOPATH
  cd ~
  wget https://dl.google.com/go/$AVAILABLEVERSION.linux-amd64.tar.gz
  tar -C /usr/local -xzf $AVAILABLEVERSION.linux-amd64.tar.gz
  echo "export GOPATH=~/hack_the_planet/scripts/go" >>~/.profile # source intentionally not used here as it appears on next line
  echo "export PATH='$PATH':/usr/local/go/bin:$GOPATH/bin" >>~/.profile && source ~/.profile
  rm $AVAILABLEVERSION.linux-amd64.tar.gz
}

if [[ $(which go | tr -d ' \n\r\t ' | head -c1 | wc -c) -ne 0 ]]; then # https://stackoverflow.com/a/35165216/4373967
  echo "Found golang installation"

  INSTALLEDVERSION=$(go version | {
    read _ _ v _
    echo ${v#go}
  }) # Strips out the response and returns in the form of "1.13.5"

  if [ $(version $INSTALLEDVERSION | cut -c 3-) -lt $(version $AVAILABLEVERSION) ]; then # Comparison Operators - http://tldp.org/LDP/abs/html/comparison-ops.html also pipe to cut and remove leading 2 characters
    echo "Current go version is older than the one available from Google"
    rm -f $(which go)    # remove current golang if exists. -f will ignore nonexistent files, never prompt
    installGoFromTheGOOG # Update to latest verion
  else
    echo "Currently installed golang v$INSTALLEDVERSION is already latest version"
  fi

else
  echo "Installing golang from source as no current version exists"
  installGoFromTheGOOG
fi





# Clone some wordlists
git clone https://github.com/danielmiessler/SecLists.git ~/hack_the_planet/wordlists

# Install tools
go get -u github.com/tomnomnom/assetfinder
go get -u github.com/tomnomnom/httprobe
go get -u github.com/tomnomnom/meg
go get github.com/tomnomnom/waybackurls


cat <<"EOF"
                ___
            ,-'"   "`-.
          ,'_          `.  
         / / \  ,-       \ 
    __   | \_0 ---        |
   /  |  |                |
   \  \  `--.______,-/    |
 ___)  \  ,--""    ,/     |
/    _  \ \-_____,-      / 
\__-/ \  | `.          ,'  
  \___/ <    ---------'    
   \__/\ |             
    \__//
EOF
#####################
### END OF SCRIPT ###
#####################

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
# Taken from - https://askubuntu.com/a/992451. "-O -" Allows us to output to nowhere and into the bash pipe. Frequent runs cause caching
#    wget --no-cache --no-cookies -O - https://raw.githubusercontent.com/JeffreyShran/Snippets/master/fresh-debian-setup.sh | sudo bash
#---------------------------------------------------------------------------------------------------------------------------------------------------

# This helps us to keep the script tidy in respect to error handling
# -e exits as soon as any line in the bash script fails
# -x prints each command that is going to be executed
set -x

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

# Update, upgrade and clean up
apt update -qy && apt upgrade -qy && apt autoremove -qy # -qq should imply -y but didn't work under testing so using -qy here. TODO: Why not?

# Remove ~/.bash_aliases and recreate from GitHub file.
# These are personalised bash commands and entirely optional
rm -f ~/.bash_aliases # -f will ignore nonexistent files, never prompt.
wget -q https://raw.githubusercontent.com/JeffreyShran/Snippets/master/bash_aliases -O ~/.bash_aliases # -q Quiet -O Output file

# Install core utilities
# dpkg will check if the application exists before attempting an install
pkgs='
x2goserver
x2goserver-xsession
git
curl
sudo
xfce4
xfce4-goodies
tightvncserver
iceweasel
'
if ! dpkg -s $pkgs >/dev/null 2>&1; then # Script from - https://stackoverflow.com/a/54239534 dpkg -s exits with status 1 if any of the packages is not installed
  sudo apt-get install -qy $pkgs # TODO: Why does one of these pkgs (xfce?) ask us to set the keyboard language. How to stop it?
fi

# Setup & install golang
INSTALLEDVERSION=$(go version | {
    read _ _ v _
    echo ${v#go}
  }) # Strips out the response and returns in the form of "1.13.5"

AVAILABLEVERSION=$(curl -s https://golang.org/VERSION?m=text) # Returns in form of "go1.13.5"

function version() { # https://apple.stackexchange.com/a/123408 - You need to define functions in advance of you calling them in your script
echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

function installGoFromTheGOOG() { # Pulls down latest golang direct from Google and sets PATH / GOPATH
    cd ~
    wget https://dl.google.com/go/$VERSION.linux-amd64.tar.gz
    tar -C /usr/local -xzf $AVAILABLEVERSION.linux-amd64.tar.gz
    echo "export GOPATH=~/go" >>~/.profile # source intentionally not used here as it appears on next line
    echo "export PATH='$PATH':/usr/local/go/bin:$GOPATH/bin" >>~/.profile && source ~/.profile
    rm $AVAILABLEVERSION.linux-amd64.tar.gz
}

if [[ $(which go) ]]; then # $(..) is command Substitution and is equivalent to `..`. Basically meaning to execute the command within. See "man bash"

  if [ $(version $INSTALLEDVERSION | cut -c 3-) -lt $(version $AVAILABLEVERSION) ]; then # Comparison Operators - http://tldp.org/LDP/abs/html/comparison-ops.html also pipe to cut and remove leading 2 characters
    rm -f $(which go) # remove current golang if exists. -f will ignore nonexistent files, never prompt
    installGoFromTheGOOG # Update to latest verion
  fi
  echo "Currently installed golang v$INSTALLEDVERSION is already latest version"
else
  installGoFromTheGOOG # Install from source as no current version exists
fi
cat << "EOF"
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
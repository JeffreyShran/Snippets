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
# SSH tunnel from powershell: ssh -D LOCALPORT USER@HOST -p REMOTEPORT
# Remove the old SSH key from the local machine after a rebuild: ssh-keygen -R HOST
# 
# To execute the script, run the below command. Taken from - https://askubuntu.com/a/992451. "-O -" Allows us to output to nowhere and into the bash pipe.
# apt update -qy && apt upgrade -qy && apt autoremove -qy && wget --no-cache -O - "https://raw.githubusercontent.com/JeffreyShran/Snippets/master/fresh-debian-setup.sh?$(date +%s)" | bash
#
# You'll need to exit the SSH session to force bash refresh and read some paths that 'source' isn't handling correctly.
#
# Any feedback welcomed here or on twitter.
# 
# This is a living script that will evolve as my personal needs change over time.
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

# Create directory structure
mkdir -p /root/hack/{git,reconnaissance,scopes,scripts,tools,wordlists}

# Install core utilities
# dpkg will check if the application exists before attempting an install
pkgs='
curl
git
libpcap-dev
jq
ncat
python3-pip
python3
'
if ! dpkg -s $pkgs >/dev/null 2>&1; then # Script from - https://stackoverflow.com/a/54239534 dpkg -s exits with status 1 if any of the packages is not installed
  apt-get install -qy $pkgs
fi

# Remove /root/.bash_aliases and recreate dotfile from GitHub.
# These are personalised bash commands and entirely optional
rm -f /root/.bash_aliases # -f will ignore nonexistent files, never prompt.
curl "https://raw.githubusercontent.com/JeffreyShran/Snippets/master/bash_aliases" --create-dirs -o "/root/.bash_aliases"

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
  chown -R root:root /usr/local/go
  mkdir -p $HOME/go/{bin,src}
  echo "export GOPATH=$HOME/go" >> /root/.profile; source /root/.profile
  echo "export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin" >> /root/.profile
  . /root/.profile
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

# Create > WORDLISTS
git clone https://github.com/danielmiessler/SecLists.git /root/hack/wordlists/seclists
git clone https://github.com/assetnote/commonspeak2-wordlists.git /root/hack/wordlists/commonspeak2

SOURCE_DIR=/root/hack/wordlists
rm -f "$SOURCE_DIR/jeffspeak/subdomains/jeffsecspeak2.txt"
mkdir -p /root/hack/wordlists/jeffspeak/subdomains/
files=(
"$SOURCE_DIR"/seclists/Discovery/DNS/deepmagic.com-prefixes-top500.txt
"$SOURCE_DIR"/commonspeak2/subdomains/subdomains.txt
)
sort -u "${files[@]}" >"$SOURCE_DIR/jeffspeak/subdomains/jeffsecspeak2.txt"

# Install tools > GO
export GO111MODULE=on && go get -v -u github.com/OWASP/Amass/v3/... 
go get -u github.com/tomnomnom/httprobe
go get -u github.com/tomnomnom/waybackurls
go get github.com/OJ/gobuster

# Install tools > PYTHON
git clone https://github.com/mazen160/bfac.git /root/hack/tools/bfac && pip3 install $_/.

# Install tools > C
git clone https://github.com/robertdavidgraham/masscan.git /root/hack/tools/masscan && make -j -C $_ && cp /root/hack/tools/masscan/bin/masscan /usr/local/bin
git clone https://github.com/blechschmidt/massdns.git /root/hack/tools/massdns && make -j -C $_ && cp /root/hack/tools/massdns/bin/massdns /usr/local/bin

# Install tools > Supporting scripts
wget https://raw.githubusercontent.com/OWASP/Amass/master/examples/config.ini -O amass.config.ini # This needs our keys adding into it.

# Change SSH port
echo "Port 4321" >> /etc/ssh/sshd_config
service sshd restart # restart to set listening port

# Some ASCII art, because, why the heck not!?
cat << EOF

       Well, I think we got away with that, eh? Pooch!
                   __
                 .'  '.
                :      :
                | _  _ |
             .-.|(o)(o)|.-.        _._          _._
            ( ( | .--. | ) )     .',_ '.      .' _,'.
             '-/ (    ) \-'     / /' `\ \ __ / /' `\ \
              /   '--'   \     / /     \.'  './     \ \
              \ `"===="` /     `-`     : _  _ :      `-`
               `\      /'              |(o)(o)|
                 `\  /'                |      |
                 /`-.-`\_             /        \
           _..:;\._/V\_./:;.._       /   .--.   \
         .'/;:;:;\ /^\ /:;:;:\'.     |  (    )  |
        / /;:;:;:;\| |/:;:;:;:\ \    _\  '--'  /__
       / /;:;:;:;:;\_/:;:;:;:;:\ \ .'  '-.__.-'   `-.
EOF
#####################
### END OF SCRIPT ###
#####################

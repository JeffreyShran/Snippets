#!/bin/bash

######################################
# Personalise a fresh Debian install #
######################################

# To execute the script, run the below command. Taken from - https://askubuntu.com/a/992451 
# -O -  Allows us to output to nowhere and into the bash pipe.
# wget -O - https://raw.githubusercontent.com/tooth-N-tail/Snippets/master/fresh-debian-setup.sh | sudo bash

# This allows us to keep the script tidy.
# -e exits as soon as any line in the bash script fails.
# -x prints each command that is going to be executed.
set -ex

# Before we proceed check that we have a connection to the scary outside world.
# -q Quiet.
# -c Number of pings to perform.
# $? Returns the exit status of the command previously executed. If ping is successful, $? will return 0. If not, it will return another number.
ping -q -c1 google.co.uk > /dev/null

# Provide a username to use as the main user.
USERNAME='jeff'

# Change the frontend default behavior of debconf to noninteractive.
# This helps to make the installs and updates etc non-interactive. (i.e You don't get asked questions)
# Otherwise you have to run something like this each time as the noninteractive will not persist: sudo DEBIAN_FRONTEND=noninteractive apt-get install slrn.
dpkg-reconfigure debconf --frontend=noninteractive

# Update, upgrade and clean up.
# -qq should imply -y but doesn't work so using -qy here.
apt update -qy && apt upgrade -qy && apt autoremove -qy

# Remove ~/.bash_aliases and recreate from GitHub file. These are personalised bash commands.
# -q Quiet.
# -O Output file.
rm ~/.bash_aliases
wget -q https://raw.githubusercontent.com/tooth-N-tail/Snippets/master/bash_aliases -O ~/.bash_aliases

# Add sudo user and grant privileges
useradd --create-home --shell "/bin/bash" --groups sudo $USERNAME

# Create SSH 
# Guide from - https://www.digitalocean.com/community/tutorials/automating-initial-server-setup-with-ubuntu-18-04


# Install core utilities. The for loop will check if the application exists before attempting an install.
# Script from - https://unix.stackexchange.com/a/434061
CORE_PROGRAMS=(git python3 python3-pip curl)

for PROGRAM in "${CORE_PROGRAMS[@]}"; do
    if ! command -v "$CORE_PROGRAMS" > /dev/null 2>&1; then
        apt-get install "$CORE_PROGRAMS" -qy
    fi
done

# Setup & install golang.
# $(..) is command Substitution and is equivalent to `..`. Basically menaing to execute the command within. See "man bash".
ORIGINAL_GO=$(which go)
rm $ORIGINAL_GO
cd ~
VERSION=$(curl https://golang.org/VERSION?m=text) # Returns in form of "go1.13.5"
wget https://dl.google.com/go/$VERSION.linux-amd64.tar.gz
tar -C /usr/local -xzf $VERSION.linux-amd64.tar.gz
echo "export GOPATH=~/go" >> ~/.profile # source intentionally not used here as it appears on next line.
echo "export PATH='$PATH':/usr/local/go/bin:$GOPATH/bin" >> ~/.profile && source ~/.profile
rm $VERSION.linux-amd64.tar.gz

# Install everything else
# Script from - https://unix.stackexchange.com/a/434061
PROGRAMS=(git python3 python3-pip curl)

for PROGRAM in "${PROGRAMS[@]}"; do
    if ! command -v "$PROGRAMS" > /dev/null 2>&1; then
        apt-get install "$PROGRAMS" -qy
    fi
done

# Reminders and advisories
echo "As root run 'passwd $USERNAME' to set the password. Currently it is blank and insecure."
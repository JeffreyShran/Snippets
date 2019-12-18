#!/bin/bash

######################################
# Personalise a fresh Debian install #
######################################

# To execute the script, run the below command. Taken from https://askubuntu.com/a/992451 
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
 
# Update, upgrade and clean up before we begin.
# -qq Implies -y so is omitted.
apt update -qq && apt upgrade -qq && apt autoremove -qq

# Remove ~/.bash_aliases and recreate from GitHub file.
rm ~/.bash_aliases
wget -q https://raw.githubusercontent.com/tooth-N-tail/Snippets/master/bash_aliases -O ~/.bash_aliases
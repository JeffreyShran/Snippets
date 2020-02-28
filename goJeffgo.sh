#!bin/bash

######################################################################################################################################################
# goJeffgo
#
# Installs golang unattended directly from google
#
# RUN: wget -O - "https://raw.githubusercontent.com/JeffreyShran/Snippets/master/goJeffgo.sh" | bash
######################################################################################################################################################

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
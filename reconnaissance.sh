#!/bin/bash

set -o errexit # added || true to commands that are allowed to fail.

((!$#)) && echo No arguments supplied! && exit 1 # Exit in the absence of any arguments

# https://github.com/mazen160/bfac # An automated tool that checks for backup artifacts that may disclose the web-application's source code.

# Amass - Install from kali repository
# Project Sonar - AWS, then build autonomous method in future
# commonspeak2 - Python script, later rewrite in golang
# waybackurls - go get github.com/tomnomnom/waybackurls
# dnsgen - pip3 install dnsgen
# httprobe - go get -u github.com/tomnomnom/httprobe

if [ -z ${var+x} ];
then
    echo "var is unset";
else
    echo "var is set to '$var'";
fi

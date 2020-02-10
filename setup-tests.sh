#!/bin/bash

pkgs='
curl
foo
dnsutils
git
bar
jq
pip3
python3
go
amass
httprobe
waybackurls
gobuster
bfac
'
for p in $pkgs; do 
    hash "$p" &>/dev/null && echo "Y: $p" || echo "N: $p"
done 
#!/bin/bash

pkgs='
curl
foo
dnsutils
git
bar
jq
python3-pip
python3
go
'
for p in $pkgs; do 
    hash "$p" &>/dev/null && echo "Y: $p" || echo "N: $p"
done 
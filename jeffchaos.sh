#!/bin/bash

############################################
### Get new data for chaos project       ###
### VERSION: 0.1                         ###
### TWITTER: @jeffreyshran               ###
### GITHUB:  github.com/JeffreyShran     ###
############################################


# What's in @arkadiyt's data and not in the Chaos project yet
# Compares url fields for exact matches
readarray -t COMM_DATA < <(
{
    comm -13 \
    <(curl -s https://raw.githubusercontent.com/projectdiscovery/public-bugbounty-programs/master/chaos-bugbounty-list.json | jq -r '.programs | .[] | .url' | sed -e 's#/$##' | sort -u) \
    <(curl -s https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/master/data/hackerone_data.json | jq -r '.[] | .url' | sed -e 's#/$##' | sort -u) |
    xargs --max-args 1 --max-procs 50 curl --connect-timeout 5 --silent --output /dev/null --head --write-out '%{url_effective},%{remote_ip},%{redirect_url},%{http_code}\n' |
    rg --invert-match '(000$)|(302$)' |
    cut -d',' -f1 |
    xargs | sed 's/ /","/g;s/^/\"/;s/$/\"/'
})

# Exit if we haven't found any new programs, otherwise
# grab all the fields we need to upload to chaos
if [ ${#COMM_DATA[@]} -eq 0 ]; then
    exit 1
else
    curl -s https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/master/data/hackerone_data.json |
    jq '[ .[] | select(.url|inside('${COMM_DATA[@]}')) | {name: .name, url: .url, bounty: .offers_bounties, domains: [.targets.in_scope[] | select(.asset_type=="URL") | .asset_identifier]} ]'
    # use python3 jeffchaos.py to tidy up
fi

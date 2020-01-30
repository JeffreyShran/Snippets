#!bin/bash

############################################
### EXPANDS TARGETS ATTACK SURFACE       ###
### VERSION: 0.1                         ###
### TWITTER: @jeffreyshran               ###
### GITHUB:  github.com/JeffreyShran     ###
############################################

#---------------------------------------------------------------------------------------------------------------------------------------------------
# Takes a domain and passes it through various tools generating output files onto github.
#
# INPUT: DOMAIN
# OUTPUT FILES: amass
#---------------------------------------------------------------------------------------------------------------------------------------------------

if [[ $# = 0 ]]; then # Check for a domain being passed to the script.
	echo "Nothing passed in."
	exit 1
fi

DOMAIN=$1
PATH_RECON="~/hack_the_planet/reconnaissance"
PATH_WORDS="~/hack_the_planet/wordlists"
PATH_TOOLS="~/hack_the_planet/tools"

# Amass
	# Check for wildcard configuration on DNS before running Amass.
	# REF: medium.com/@noobhax/my-recon-process-dns-enumeration-d0e288f81a8a
if [[ $(dig @1.1.1.1 A,CNAME {$RANDOM,$RANDOM,$RANDOM}.$DOMAIN +short | wc -l) < 2 ]]; then # 1 match allowed for tolerance.
	amass enum --passive -d $DOMAIN > "$PATH_RECON/amass.subdomains.$DOMAIN.txt"
fi

# ffuf
	# vhosts? Also see - https://twitter.com/joohoi/status/1222655322621390848?s=20
	# https://github.com/ffuf/ffuf

# Project Sonar
	# https://github.com/erbbysam/DNSGrep - Roll Own. Limited to 100,000 rows returned.
	# https://blog.erbbysam.com/index.php/2019/02/09/dnsgrep/
	# https://blog.rapid7.com/2018/10/16/how-to-conduct-dns-reconnaissance-for-02-using-rapid7-open-data-and-aws/
	# TODO: Large datasets return "jq: error (at <stdin>:16): Cannot iterate over null (null)"
curl 'https://dns.bufferover.run/dns?q=${DOMAIN}' 2> /dev/null | jq '.FDNS_A[],.RDNS[]' | sed 's/[^,]*,//;s/.$//'

# commonspeak2
	# https://github.com/assetnote/commonspeak2-wordlists
cat "$PATH_WORDS/commonspeak2/subdomains/subdomains.txt" |
awk -v awkvar="$DOMAIN" '{ print $0 "." awkvar;}' > "$PATH_RECON/commonspeak2.subdomains.$DOMAIN.txt"

# Sort and remove duplicates from current subdomains shortlist candidates.
find "${PATH_RECON}/" -name "*$DOMAIN*" -print0 | xargs -0 sort -u > "${PATH_RECON}/unique.sorted.subdomains.${DOMAIN}.txt"

# dnsgen - pip3 install dnsgen
	#
# httprobe - go get -u github.com/tomnomnom/httprobe
	#
# gobuster - go get github.com/OJ/gobuster
	# gobuster dir -u <DOMAIN> -w ~/wordlists/shortlist.txt -q -n -e
# waybackurls
	# waybackurls internet.org | grep "\.js" | uniq | sort
# bfac - git clone https:#github.com/mazen160/bfac.git
	# bfac --list testing_list.txt (read help)
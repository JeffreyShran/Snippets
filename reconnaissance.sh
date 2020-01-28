#!bin/bash

############################################
### EXPANDS TARGETS ATTACK SURFACE       ###
### VERSION: 0.1                         ###
### TWITTER: @jeffreyshran               ###
### GITHUB:  github.com/JeffreyShran     ###
############################################

#---------------------------------------------------------------------------------------------------------------------------------------------------
# Takes a domain and passes it through various tools 
#
#
#
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Amass - Install from kali repository
	# amass enum --passive -d <DOMAIN>
# Project Sonar - AWS, then build autonomous method in future
	# 
# commonspeak2 - Python script, later rewrite in golang
	# 
# waybackurls - go get github.com/tomnomnom/waybackurls
	#
# SORT ALL DATA
# dnsgen - pip3 install dnsgen
	#
# httprobe - go get -u github.com/tomnomnom/httprobe
	#
# gobuster - go get github.com/OJ/gobuster
	# gobuster dir -u <DOMAIN> -w ~/wordlists/shortlist.txt -q -n -e
# bfac - git clone https:#github.com/mazen160/bfac.git
	# bfac --list testing_list.txt (read help)

DOMAIN=$1

# Check for wildcard configuration on DNS before running Amass.
# REF: medium.com/@noobhax/my-recon-process-dns-enumeration-d0e288f81a8a
if [[ $(dig @1.1.1.1 A,CNAME {$RANDOM,$RANDOM,$RANDOM}.$DOMAIN +short | wc -l) < 2 ]]; then # 1 match allowed for tolerance.
	amass enum --passive -d $DOMAIN # TODO: Refine Command
fi
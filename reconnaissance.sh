#!bin/bash

############################################
### EXPANDS TARGETS ATTACK SURFACE       ###
### VERSION: 0.1                         ###
### TWITTER: @jeffreyshran               ###
### GITHUB:  github.com/JeffreyShran     ###
############################################

######################################################################################################################################################
# Takes a domain and passes it through various tools generating output files onto github.
#
# INPUT: DOMAIN
# RUN: wget --no-cache -qO - "https://raw.githubusercontent.com/JeffreyShran/Snippets/master/reconnaissance.sh?$(date +%s)" | bash -s drhanson.dev
######################################################################################################################################################


#------------------------------------------------------------------------------
# Get input
# doesn't support long options, only single-character options
# https://stackoverflow.com/a/21128172/4373967
#------------------------------------------------------------------------------

print_usage() {
cat << EOF
usage: reconnaissance [OPTION]

	-d DOMAIN	(required) 		Do not include https. i.e. supply as example.com.
	-s SCOPE	(Not required) 	Must be path to HackerOne burp configuration for burp, include full path. If included the whole thing is faster and more accurate.
	-h HELP		(Not required)	Prints this usage information.
	-v VERSION	(Not required)	Prints current version.

Report bugs to: @jeffreyshran (twitter)
EOF
}

while getopts 'd:' flag; do
  case "${flag}" in
    d) domain="${OPTARG}" [ -z "${d}" ] || print_usage;;
    s) scope="${OPTARG}" ;;
	v) version='0.1' ;;
    h | *) print_usage ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;

  esac
done

DOMAIN=$1
PATH_RECON="/root/hack/reconnaissance"
PATH_WORDS="/root/hack/wordlists"
PATH_TOOLS="/root/hack/tools"
PATH_SCRIPTS="/root/hack/scripts"
PATH_SCOPES="/root/hack/scopes"

#------------------------------------------------------------------------------
# scope
#
# Before we do anything establish whats in or out of scope.
#------------------------------------------------------------------------------
# jq -rc '.target.scope.exclude | map(.host) | unique_by([]) | @csv' <"$PATH_RECON/rapyd.json" | tr -d '"' >"$PATH_RECON/rapyd.excludes"

#------------------------------------------------------------------------------
# Amass
#------------------------------------------------------------------------------
# Check for wildcard configuration on DNS before running Amass.
# REF: medium.com/@noobhax/my-recon-process-dns-enumeration-d0e288f81a8a
if [[ $(dig @1.1.1.1 A,CNAME {$RANDOM,$RANDOM,$RANDOM}.$DOMAIN +short | wc -l) < 2 ]]; then # 1 match allowed for tolerance.
	amass enum -config "$PATH_SCRIPTS/amass.config.ini" --passive -d $DOMAIN > "$PATH_RECON/amass.subdomains.$DOMAIN.txt"
fi

#------------------------------------------------------------------------------
# rapid7
#
# https://github.com/erbbysam/DNSGrep - Roll Own. Limited to 100,000 rows returned.
# https://blog.erbbysam.com/index.php/2019/02/09/dnsgrep/
# https://blog.rapid7.com/2018/10/16/how-to-conduct-dns-reconnaissance-for-02-using-rapid7-open-data-and-aws/
# TODO: Large datasets return "jq: error (at <stdin>:16): Cannot iterate over null (null)"
#------------------------------------------------------------------------------
curl "https://dns.bufferover.run/dns?q=$DOMAIN" 2> /dev/null > "$PATH_RECON/rapid7.temp.subdomains.$DOMAIN.txt"

if [[ $(cat "$PATH_RECON/rapid7.temp.subdomains.$DOMAIN.txt" | grep "output limit reached" | wc -l) = 0 ]]; then
	jq '.FDNS_A[]?,.RDNS[]?' "$PATH_RECON/rapid7.temp.subdomains.$DOMAIN.txt" |
	sed 's/[^,]*,//;s/.$//' > "$PATH_RECON/rapid7.subdomains.$DOMAIN.txt"
fi

rm -f "$PATH_RECON/rapid7.temp.subdomains.$DOMAIN.txt"

#------------------------------------------------------------------------------
# JeffSecSpeak2
#------------------------------------------------------------------------------
cat "$PATH_WORDS/jeffspeak/subdomains/jeffsecspeak2.txt" |
awk -v awkvar="$DOMAIN" '{ print $0 "." awkvar;}' > "$PATH_RECON/jeffspeak.subdomains.$DOMAIN.txt"

#------------------------------------------------------------------------------
# unique/sort & httprobe
#------------------------------------------------------------------------------
sort -u "${PATH_RECON}/*$DOMAIN*" | tee "${PATH_RECON}/unique.subdomains.${DOMAIN}.txt" |
httprobe -c 500 -t 5000 > "${PATH_RECON}/httprobe.subdomains.${DOMAIN}.txt"

# FUTURE ADDITIONS...

#------------------------------------------------------------------------------
# gobuster - go get github.com/OJ/gobuster
#------------------------------------------------------------------------------
	# gobuster dir -u <DOMAIN> -w /root/wordlists/shortlist.txt -q -n -e
#------------------------------------------------------------------------------
# waybackurls
#------------------------------------------------------------------------------
	# waybackurls internet.org | grep "\.js" | uniq | sort
#------------------------------------------------------------------------------
# bfac - git clone https:#github.com/mazen160/bfac.git
#------------------------------------------------------------------------------
	# bfac --list testing_list.txt (read help)
#------------------------------------------------------------------------------
# dnsgen - pip3 install dnsgen
#------------------------------------------------------------------------------
	#
#------------------------------------------------------------------------------
# ffuf
#------------------------------------------------------------------------------
# vhosts? Also see - https://twitter.com/joohoi/status/1222655322621390848?s=20
# https://github.com/ffuf/ffuf
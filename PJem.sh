#!bin/bash

############################################
### EXPANDS TARGETS ATTACK SURFACE       ###
### VERSION: 0.1                         ###
### TWITTER: @jeffreyshran               ###
### GITHUB:  github.com/JeffreyShran     ###
############################################

#------------------------------------------------------------------------------
# Get input
# doesn't support long options, only single-character options
# https://stackoverflow.com/a/21128172/4373967
#------------------------------------------------------------------------------

print_usage() {
cat << EOF

######################################################################################################################################################
# ___  ,  _ ____ _  _ 
# |__]    | |___ |\/| 
# |      _| |___ |  | 
#
# Takes a domain and passes it through various tools generating output files onto github.
#
# INPUT: DOMAIN
# RUN: wget -O - "https://raw.githubusercontent.com/JeffreyShran/Snippets/master/pjem.sh" | bash /dev/stdin -d att.com
######################################################################################################################################################

usage: pjem [OPTION]

	-d DOMAIN	(required)      Do not include https. i.e. supply as example.com.
	-s SCOPE	(Not required) 	Must be path to HackerOne burp configuration for burp, include full path. If included the whole thing is faster and more accurate.
	-h HELP		(Not required)  Prints this usage information.
	-v VERSION	(Not required)  Prints current version.

Report bugs to: @jeffreyshran (Twitter)

EOF
1>&2;
exit 1; 
}

while getopts ":d:s:vh" opt; do
  case "${opt}" in
    d )
      DOMAIN=${OPTARG}
      ;;
	s )
      SCOPE=${OPTARG}
      ;;
	v )
      echo "0.1" 1>&2;
	  exit 1;
      ;;
	h )
	  print_usage 1>&2;
	  exit 1;
	  ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2;
	  exit 1;
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2;
	  exit 1;
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$DOMAIN" ]; then
	echo "Need a domain to continue..."
	exit 1;
fi

PATH_RECON="/root/hack/reconnaissance"
PATH_WORDS="/root/hack/wordlists"
PATH_TOOLS="/root/hack/tools"
PATH_SCRIPTS="/root/hack/scripts"
PATH_SCOPES="/root/hack/scopes"

#------------------------------------------------------------------------------
# scope
#
# TODO: Before we do anything establish whats in or out of scope.
#------------------------------------------------------------------------------
# https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/master/data/hackerone_data.json
# jq -rc '.target.scope.exclude | map(.host) | unique_by([]) | @csv' <"$PATH_SCOPES/${scope}" | tr -d '"' >"$PATH_SCOPES/excludes.${scope}"

#https://bgp.he.net/

#https://github.com/Edu4rdSHL/findomain

#https://github.com/projectdiscovery/subfinder

#https://github.com/projectdiscovery/shuffledns

#------------------------------------------------------------------------------
# Amass
#------------------------------------------------------------------------------
# Check for wildcard configuration on DNS before running Amass.
# REF: medium.com/@noobhax/my-recon-process-dns-enumeration-d0e288f81a8a
echo "Starting Amass"
if [[ $(dig @1.1.1.1 A,CNAME {$RANDOM,$RANDOM,$RANDOM}.${DOMAIN} +short | wc -l) < 2 ]]; then # 1 match allowed for tolerance.
	amass enum -config "$PATH_SCRIPTS/amass.config.ini" --passive -d ${DOMAIN} > "$PATH_RECON/amass.subdomains.${DOMAIN}.txt"
fi

#------------------------------------------------------------------------------
# anubis
# TODO: Create mega sub domain list.
#------------------------------------------------------------------------------
curl "https://jonlu.ca/anubis/subdomains/${DOMAIN}" | jq .[]? -rc 2> /dev/null > "$PATH_RECON/anubis.subdomains.${DOMAIN}.txt"

#------------------------------------------------------------------------------
# rapid7
#
# https://github.com/erbbysam/DNSGrep - Roll Own. Limited to 100,000 rows returned.
# https://blog.erbbysam.com/index.php/2019/02/09/dnsgrep/
# https://blog.rapid7.com/2018/10/16/how-to-conduct-dns-reconnaissance-for-02-using-rapid7-open-data-and-aws/
#------------------------------------------------------------------------------
echo "Starting rapid7"
curl "https://dns.bufferover.run/dns?q=${DOMAIN}" 2> /dev/null > "$PATH_RECON/rapid7.temp.subdomains.${DOMAIN}.txt"

if [[ $(cat "$PATH_RECON/rapid7.temp.subdomains.${DOMAIN}.txt" | grep "output limit reached" | wc -l) = 0 ]]; then
	jq '.FDNS_A[]?,.RDNS[]?' "$PATH_RECON/rapid7.temp.subdomains.${DOMAIN}.txt" |
	sed 's/[^,]*,//;s/.$//' > "$PATH_RECON/rapid7.subdomains.${DOMAIN}.txt"
fi

rm -f "$PATH_RECON/rapid7.temp.subdomains.${DOMAIN}.txt"

#------------------------------------------------------------------------------
# JeffSecSpeak2
#------------------------------------------------------------------------------
echo "Starting JeffSecSpeak2"
cat "$PATH_WORDS/jeffspeak/subdomains/jeffsecspeak2.txt" |
awk -v awkvar="${DOMAIN}" '{ print $0 "." awkvar;}' > "$PATH_RECON/jeffspeak.subdomains.${DOMAIN}.txt"

#------------------------------------------------------------------------------
# unique/sort & httprobe
#------------------------------------------------------------------------------
echo "Starting unique/sort & httprobe"
FILES=("$PATH_RECON"/*"${DOMAIN}"*); sort -u "${FILES[@]}" |
tee "${PATH_RECON}/unique.subdomains.${DOMAIN}.txt" |
massdns ?????????????
# httprobe -c 10000 -t 5000 > "${PATH_RECON}/httprobe.subdomains.${DOMAIN}.txt"

#------------------------------------------------------------------------------
# timer
#------------------------------------------------------------------------------
echo "Script finished in $SECONDS seconds."

### END ###

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
#


# https://github.com/urbanadventurer/whatweb
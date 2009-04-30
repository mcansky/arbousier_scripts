#!bin/bash

# basic network filtering and natting
#
#
#	Wild | Livebox (   Wi-Fi   )  ath0 | FON | eth0 --- lan
#

MODULES="ip_tables \
	ipt_string \
	ip_conntrack \
	ip_conntrack_ftp \
	ip_nat_ftp"

EXT_IF="ath0"
INTERNET_NAT="ath0"
INT_IF="eth0"
INT_NET="192.168.42.0/24"
EXT_NET="192.168.1.0/24"

IPTABLES=`which iptables`
MODPROBE=`which modprobe`
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NORMAL="\033[m"
BOLD="\033[1m"


# erasing oldies 
echo -en "${BOLD}${YELLOW}Erasing old rules :${NORMAL}"
${IPTABLES} -t filter -F INPUT
${IPTABLES} -t filter -F OUTPUT
${IPTABLES} -t filter -F FORWARD
${IPTABLES} -t nat    -F PREROUTING
${IPTABLES} -t nat    -F OUTPUT
${IPTABLES} -t nat    -F POSTROUTING
${IPTABLES} -t mangle -F PREROUTING
${IPTABLES} -t mangle -F OUTPUT
echo -e "\t\t\t\t${GREEN}OK${NORMAL}"


# back to zeros
echo -en "${BOLD}${YELLOW}Reseting to zero :${NORMAL}"
${IPTABLES} -t filter -Z
${IPTABLES} -t nat    -Z
${IPTABLES} -t mangle -Z
echo -e "\t\t\t\t${GREEN}OK${NORMAL}"


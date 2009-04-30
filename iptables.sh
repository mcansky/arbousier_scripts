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

# default policy : tous au karcher !
echo -en "${BOLD}${YELLOW}Default policy setup :${NORMAL}"
${IPTABLES} -t filter -P INPUT   DROP
${IPTABLES} -t filter -P OUTPUT  ACCEPT
${IPTABLES} -t filter -P FORWARD DROP
echo -e "\t\t\t\t${GREEN}OK${NORMAL}\n"


# filtering
echo -en "${BOLD}${YELLOW}Setting up the filters :${NORMAL}"
${IPTABLES} -A INPUT -i lo -j ACCEPT
${IPTABLES} -A INPUT -i ${EXT_IF} -s ${INT_NET} -j DROP
${IPTABLES} -A INPUT -i ${INT_IF} -j ACCEPT
# network specific
${IPTABLES} -A INPUT -i ${INT_IF} -d ${EXT_NET} -j ACCEPT
${IPTABLES} -A INPUT -i ${INT_IF} -d ${INT_NET} -p udp -j ACCEPT

${IPTABLES} -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
${IPTABLES} -A FORWARD -i ${EXT_IF} -o ${INT_IF} -m state --state RELATED,ESTABLISHED -j ACCEPT 
echo -e "\t\t\t${GREEN}OK${NORMAL}"


# nat
echo -en "${BOLD}${YELLOW}Setting up NAT :${NORMAL}"
${IPTABLES} -t nat -A POSTROUTING -s ${INT_NET} -o ${EXT_IF} -j MASQUERADE
${IPTABLES} -A FORWARD -i ${INT_IF} -o ${EXT_IF} -s ${INT_NET} -j ACCEPT
echo -e "\t\t\t\t${GREEN}OK${NORMAL}"

# letting things out
echo -en "${BOLD}${YELLOW}Letting things out :${NORMAL}"
${IPTABLES} -A OUTPUT -s ${INT_NET} -o ${EXT_IF} -j ACCEPT
${IPTABLES} -A OUTPUT -o ${EXT_IF} -j ACCEPT
${IPTABLES} -A OUTPUT -o ${INT_IF} -p udp -j ACCEPT
echo -e "\t\t\t\t${GREEN}OK${NORMAL}"

# end, dropping what's left
${IPTABLES} -A INPUT -j DROP

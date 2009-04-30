#!bin/bash

# basic network filtering and natting
#
#
#	Wild | Livebox (   Wi-Fi   )  eth2 | this box | eth1 --- sekioure network
#

MODULES="ip_tables \
	ipt_string \
	ip_conntrack \
	ip_conntrack_ftp \
	ip_nat_ftp"

EXT_IF="wlan0"
INTERNET_NAT="wlan0"
INT_IF="eth0"
INT_NET="169.254.255.0/24"
EXT_NET="192.168.1.0/24"

IPTABLES=`which iptables`
MODPROBE=`which modprobe`
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NORMAL="\033[m"
BOLD="\033[1m"


# reseting rules
${IPTABLES} -F
${IPTABLES} -t nat -F


# rejecting everything
${IPTABLES} -P INPUT DROP

${IPTABLES} -P FORWARD ACCEPT
#${IPTABLES} -P FORWARD DROP 
#${IPTABLES} -P OUTPUT DROP

# filtering
${IPTABLES} -A INPUT -i lo -j ACCEPT
${IPTABLES} -A INPUT -i ${EXT_IF} -j ACCEPT
${IPTABLES} -A INPUT -i ${EXT_IF} -s ${INT_NET} -j DROP
${IPTABLES} -A INPUT -i ${INT_IF} -j ACCEPT
# network specific
${IPTABLES} -A INPUT -i ${EXT_IF} -d ${INT_NET} -j ACCEPT
${IPTABLES} -A INPUT -i ${INT_IF} -d ${EXT_NET} -j ACCEPT
${IPTABLES} -A INPUT -i ${INT_IF} -d ${INT_NET} -p udp -j ACCEPT


${IPTABLES} -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT  

# nat
${IPTABLES} -t nat -A POSTROUTING -s ${INT_NET} -o $EXT_IF -j MASQUERADE
${IPTABLES} -A FORWARD -i ${INT_IF} -s ${INT_NET} -o ${EXT_IF} -j ACCEPT

# optimisation
#${IPTABLES} -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS -o $INTERNET --clamp-mss-to-pmtu

# letting things out
${IPTABLES} -A OUTPUT -s ${INT_NET} -o ${EXT_IF} -j ACCEPT
${IPTABLES} -A OUTPUT -o ${EXT_IF} -j ACCEPT
${IPTABLES} -A OUTPUT -o ${INT_IF} -p udp -j ACCEPT

# end, dropping what's left
${IPTABLES} -A INPUT -j DROP

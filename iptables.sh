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


###################################################
## EFFACEMENT DES ANCIENNES REGLES		 ## 
###################################################

echo -en "${BOLD}${YELLOW}Effacement des anciennes regles :${NORMAL}"
${IPTABLES} -t filter -F INPUT
${IPTABLES} -t filter -F OUTPUT
${IPTABLES} -t filter -F FORWARD
${IPTABLES} -t nat    -F PREROUTING
${IPTABLES} -t nat    -F OUTPUT
${IPTABLES} -t nat    -F POSTROUTING
${IPTABLES} -t mangle -F PREROUTING
${IPTABLES} -t mangle -F OUTPUT
echo -e "\t\t\t${GREEN}OK${NORMAL}"


###################################################
## REMISE A ZERO DES CHAINES			 ##
###################################################

echo -en "${BOLD}${YELLOW}Remise a zero des chaines :${NORMAL}"
${IPTABLES} -t filter -Z
${IPTABLES} -t nat    -Z
${IPTABLES} -t mangle -Z
echo -e "\t\t\t\t${GREEN}OK${NORMAL}"

###################################################
## MISE EN PLACE DE LA POLITIQUE PAR DEFAUT	 ##
###################################################

echo -en "${BOLD}${YELLOW}Mise en place de la polique par defaut :${NORMAL}"
${IPTABLES} -t filter -P INPUT   DROP
${IPTABLES} -t filter -P OUTPUT  ACCEPT
${IPTABLES} -t filter -P FORWARD DROP
echo -e "\t\t${GREEN}OK${NORMAL}\n"


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

###################################################
## FUCK nimda and codered :)                     ##
###################################################

echo -e "${BOLD}${YELLOW}Protection contre Nimda et codered :${NORMAL}\t\t\t${GREEN}OK${NORMAL}"
${IPTABLES} -I INPUT -j DROP -m string -p tcp -s 0.0.0.0/0 --string "c+dir"
${IPTABLES} -I INPUT -j DROP -m string -p tcp -s 0.0.0.0/0 --string "c+tftp"
${IPTABLES} -I INPUT -j DROP -m string -p tcp -s 0.0.0.0/0 --string "cmd.exe"
${IPTABLES} -I INPUT -j DROP -m string -p tcp -s 0.0.0.0/0 --string "default.ida"
${IPTABLES} -I FORWARD -j DROP -m string -p tcp -s 0.0.0.0/0 --string "c+dir"
${IPTABLES} -I FORWARD -j DROP -m string -p tcp -s 0.0.0.0/0 --string "c+tftp"
${IPTABLES} -I FORWARD -j DROP -m string -p tcp -s 0.0.0.0/0 --string "cmd.exe"
${IPTABLES} -I FORWARD -j DROP -m string -p tcp -s 0.0.0.0/0 --string "default.ida"

# end, dropping what's left
${IPTABLES} -A INPUT -j DROP

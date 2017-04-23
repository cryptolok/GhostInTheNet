#!/usr/bin/env bash
# if you decide to run it on BSD

# cyan cyberpunk style
echo -e "\033[01;36m"
echo '
						 ^		
						/ \		
  _____ _    _  ____   _____ _______ 	       /   \		 _   _ ______ _______ 
 / ____| |  | |/ __ \ / ____|__   __|	      /	    \		| \ | |  ____|__   __|
| |  __| |__| | |  | | (___    | |  	     /	     \		|  \| | |__     | |   
| | |_ |  __  | |  | |\___ \   | |     	    /	in    \		| . ` |  __|    | |   
| |__| | |  | | |__| |____) |  | |  	   /	       \	| |\  | |____   | |   
 \_____|_|  |_|\____/|_____/   |_|     	  /	the	\	|_| \_|______|  |_|   
				   	 /		 \	
					/_________________\	
'

# check for root access
#[ "${UID}" -eq 0 ] || { echo -e "sudo !!\n" ; exit 1; }
if [[ $UID -ne 0 ]]
then
	echo 'sudo !!'
	echo
	exit 1
fi
# just type it and it will execute the last command as root

# arguments/variables assignments
#SWITCH=$(echo $1 | tr '[:upper:]' '[:lower:]')
SWITCH=${1,,*}
INTERFACE=$2

# network stealther
#[ $# -gt 1 ] || { echo 'Usage: GhostInTheNet on|off $INTERFACE'; exit 2; }
if [[ "$INTERFACE" = "" ]]
then
	echo 'Usage: GhostInTheNet on|off $INTERFACE'
	echo
	exit 2
fi

#case $SWITCH in on)
if [[ "$SWITCH" = "on" ]]
then
	echo 'Spoofing MAC address ...'
	echo
#	ifdown $INTERFACE &> /dev/null
	ifconfig $INTERFACE down 
#[[ $? -eq 0 ]] || { echo -e 'Wrong INTERFACE? Try eth0 or wlan0 or execute `ip a`' ; exit 3; }
	if [[ $? -ne 0 ]]
	then
		echo 'Wrong INTERFACE? Try eth0 or wlan0 or execute `ip a`'
		echo
		exit 3
	fi
	MAC=$(echo $RANDOM|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/64:\1:\2:\3:\4:\5/')
# random MAC, but with 0x64 in the beginning to avoid reserved addresses (unicast, etc)
#TODO add vendors choice (dell,hp,intel,vmware,cisco,belkin...) ?
	ifconfig $INTERFACE hw ether $MAC
#	ip link set $INTERFACE address $MAC > /dev/null
	echo "New MAC addresse : $MAC"
	echo
	echo 'Configuring kernel to restrict ARP/NDP requests in linking network mode ...'
	echo
	sysctl net.ipv4.conf.$INTERFACE.arp_ignore=8 > /dev/null
# ignore ARP broadcasts
	sysctl net.ipv4.conf.$INTERFACE.arp_announce=2 > /dev/null
# restrict ARP announces to unicast
	ip6tables -I INPUT 1 -i $INTERFACE --protocol icmpv6 --icmpv6-type echo-request -j DROP
# ignore ICMPv6 echo requests type 128 code 0
	ip6tables -I INPUT 2 -i $INTERFACE --protocol icmpv6 --icmpv6-type neighbor-solicit -j DROP
# ignore ICMPv6/NDP neighbor solicitation requests type 135 code 0
# IPv6 scanning isn't too much realistic though
	echo 'Reinitializing network interface ...'
	echo 'If not connected or taking too long - reconnect manually'
	echo
#	ifup $INTERFACE &> /dev/null
	ifconfig $INTERFACE up
	dhclient $INTERFACE &> /dev/null
#TODO use already achived IP configuration to avoir broadcast ?
	echo 'Now you are a cyberspy, robotic guy'
	echo
#;;off)
elif [[ "$SWITCH" = "off" ]]
then
	echo 'Reinitializing MAC address ...'
	echo
#	ifdown $INTERFACE &> /dev/null
	ifconfig $INTERFACE down 
#	MAC=$(ethtool -P eth0 | cut -d ':' -f 2-)
	MAC=$(ethtool -P $INTERFACE)
	MAC=${MAC#*:}
	ifconfig $INTERFACE hw ether $MAC
#	ip link set $INTERFACE address $MAC &> /dev/null
	if [[ $? -ne 0 ]]
	then
		echo 'Wrong INTERFACE? Try eth0 or wlan0 or execute `ip a`'
		echo
		exit 3
	fi
	echo 'Reconfiguring kernel to normal ARP/NDP linking network mode ...'
	echo
	sysctl net.ipv4.conf.$INTERFACE.arp_ignore=0 > /dev/null
	sysctl net.ipv4.conf.$INTERFACE.arp_announce=0 > /dev/null
	ip6tables -D INPUT -i $INTERFACE --protocol icmpv6 --icmpv6-type echo-request -j DROP
	ip6tables -D INPUT -i $INTERFACE --protocol icmpv6 --icmpv6-type neighbor-solicit -j DROP
	echo 'Reinitializing network interface ...'
	echo 'If not connected or taking too long - reconnect manually'
	echo
#	ifup $INTERFACE &> /dev/null
	ifconfig $INTERFACE up
	dhclient $INTERFACE &> /dev/null
	echo 'Waiting like a ghost, when you need me the most'
	echo
#;;*)
else
	echo 'Usage: GhostInTheNet on|off $INTERFACE'
	echo
	exit 4
#;;esac
fi
#exit 0

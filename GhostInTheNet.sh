#!/bin/bash

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
if [[ $UID -ne 0 ]]
then
	echo 'sudo !!'
	echo
	exit 1
fi

SWITCH=$(echo $1 | tr '[:upper:]' '[:lower:]')
INTERFACE=$2

if [[ "$INTERFACE" = "" ]]
then
	echo 'Usage: GhostInTheNet on|off $INTERFACE'
	echo
	exit 2
fi

if [[ "$SWITCH" = "on" ]]
then
	echo 'Spoofing MAC address ...'
	echo
#	ifdown $INTERFACE &> /dev/null
	ifconfig $INTERFACE down 
	if [[ $? -ne 0 ]]
	then
		echo 'Wrong INTERFACE? Try eth0 or wlan0 or execute `ip a`'
		echo
		exit 3
	fi
	MAC=$(echo $RANDOM|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/64:\1:\2:\3:\4:\5/')
	ifconfig $INTERFACE hw ether $MAC
#	ip link set $INTERFACE address $MAC > /dev/null
	echo "New MAC addresse : $MAC"
	echo
	echo 'Configuring kernel to restrict ARP requests in linking network mode ...'
	echo
	sysctl net.ipv4.conf.$INTERFACE.arp_ignore=8 > /dev/null
	sysctl net.ipv4.conf.$INTERFACE.arp_announce=2 > /dev/null
	echo 'Reinitializing network interface ...'
	echo 'If not connected or taking too long - reconnect manually'
	echo
#	ifup $INTERFACE &> /dev/null
	ifconfig $INTERFACE up
	dhclient $INTERFACE &> /dev/null
	echo 'Now you are a cyberspy, robotic guy'
	echo
elif [[ "$SWITCH" = "off" ]]
then
	echo 'Reinitializing MAC address ...'
	echo
#	ifdown $INTERFACE &> /dev/null
	ifconfig $INTERFACE down 
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
	echo 'Reconfiguring kernel to normal ARP linking network mode ...'
	echo
	sysctl net.ipv4.conf.$INTERFACE.arp_ignore=0 > /dev/null
	sysctl net.ipv4.conf.$INTERFACE.arp_announce=0 > /dev/null
	echo 'Reinitializing network interface ...'
	echo 'If not connected or taking too long - reconnect manually'
	echo
#	ifup $INTERFACE &> /dev/null
	ifconfig $INTERFACE up
	dhclient $INTERFACE &> /dev/null
	echo 'Waiting like a ghost, when you need me the most'
	echo
else
	echo 'Usage: GhostInTheNet on|off $INTERFACE'
	echo
	exit 4
fi


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
echo -e "\e[0m"

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
TMPMAC=/tmp/mac.ghost
# here we are going to store the original MAC address
ORGHOST=/tmp/host.ghost
# the original hostname, because volatility is somehow misrupted by systemd/nm
ORGMAC=""

# network stealther
#[ $# -gt 1 ] || { echo 'Usage: GhostInTheNet on|off $INTERFACE'; exit 2; }
if [[ "$INTERFACE" = "" ]]
then
	echo 'Usage: GhostInTheNet on|off $INTERFACE'
	echo
	exit 2
fi

# let's use ifconfig by default
CMD=$( which ifconfig 2>/dev/null)
if [[ $? -gt 0 ]]; then
    # or ip if not present
    CMD=$( which ip )
fi

#case $SWITCH in on)
if [[ "$SWITCH" = "on" ]]
then
    # storing original MAC
    if [ ! $(which ethtool) ] && [ ! -f /etc/udev/rules.d/70-persistent-net.rules ]
    then
        if [[ $CMD =~ .*ifconfig ]]; then
            ORGMAC=$( $CMD $INTERFACE | grep ether | awk '{print $2}' )
        else
            ORGMAC=$( $CMD link show $INTERFACE | awk '$1~/^link/{print $2}' )
        fi
    else
        if [[ $(which ethtool) ]]
        then
            ORGMAC=$(ethtool -P $INTERFACE)
            ORGMAC=${ORGMAC#*:}
        else
            ORGMAC=$(cat /etc/udev/rules.d/70-persistent-net.rules | grep $INTERFACE | cut -d '"' -f 8)
        fi
    fi

    echo "Saving original MAC address for $INTERFACE"
    echo -n $ORGMAC > $TMPMAC
	echo 'Spoofing MAC address ...'
	echo
#	ifdown $INTERFACE &> /dev/null
#	nmcli con down $INTERFACE &>/dev/null
	/etc/init.d/network-manager stop &>/dev/null
    if [[ $CMD =~ .*ifconfig ]]; then
        $CMD $INTERFACE down
    else
	    $CMD link set $INTERFACE down
    fi
#[[ $? -eq 0 ]] || { echo -e 'Wrong INTERFACE? Try eth0 or wlan0 or execute `ip a`' ; exit 3; }
	if [[ $? -ne 0 ]]
	then
		echo 'Wrong INTERFACE? Try eth0 or wlan0 or execute `ip a`'
		echo
		exit 3
	fi
	VENDORS="0001E6 0001E7 0002A5 0004EA 000802 000883 000A57 000BCD 000D9D 000E7F 000EB3 000F20 000F61 0010E3 00110A 001185 001279 001321 0014C2 001560 001635 001708 0017A4 001871 0018FE 0019BB 001A4B 001B78 001CC4 001E0B 001F29 00215A 002264 00237D 002481 0025B3 002655 00306E 0030C1 00508B 0080A0 009C02 082E5F 101F74 10604B 1458D0 18A905 1CC1DE 24BE05 288023 28924A 2C233A 2C27D7 2C4138 2C44FD 2C59E5 2C768A 308D99 30E171 3464A9 3863BB 38EAA7 3C4A92 3C5282 3CA82A 3CD92B 40A8F0 40B034 441EA1 443192 480FCF 5065F3 5820B1 5C8A38 5CB901 643150 645106 68B599 6C3BE5 6CC217 705A0F 7446A0 784859 78ACC0 78E3B5 78E7D1 80C16E 843497 8851FB 8CDCD4 9457A5 984BE1 98E7F4 9C8E99 9CB654 A01D48 A02BB8 A0481C A08CFD A0B3CC A0D3C1 A45D36 AC162D B05ADA B499BA B4B52F B8AF67 BCEAFA C4346B C8CBB8 C8D3FF CC3E5F D07E28 D0BF9C D48564 D4C9EF D89D67 D8D385 DC4A3E E4115B E83935 EC8EB5 EC9A74 ECB1D7 F0921C F4CE46 FC15B4 FC3FDB"
# Hewlett Packard (HP) possible vendors MACs list, taken from https://gist.github.com/aallan/b4bb86db86079509e6159810ae9bd3e4
	VENDOR=$(echo "$VENDORS" | tr '\t' '\n' | head -n $((RANDOM%128+1))| tail -n 1)
	MAC=$VENDOR$(cat /proc/sys/kernel/random/uuid | head -c 6)
# random HP vendors MAC, to avoid reserved addresses (unicast, etc) and MAC blacklisting
#TODO add vendors choice (dell,hp,intel,vmware,cisco,belkin...) ?
    if [[ $CMD =~ .*ifconfig ]]; then
	    $CMD $INTERFACE hw ether $MAC
    else
        $CMD link set dev $INTERFACE address $MAC
    fi

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
#	nmcli radio wifi off
#	rfkill unblock wlan
    if [[ $CMD =~ .*ifconfig ]]; then
	    $CMD $INTERFACE up
    else
        $CMD link set $INTERFACE up
    fi
    	/etc/init.d/network-manager start &>/dev/null
	hostname > $ORGHOST
#	hostnamectl set-hostname $RANDOM
	NAME=DESKTOP-$(tr -dc A-Z0-9 < /dev/urandom | head -c 7)
# typical Windows-like name
	nmcli general hostname "$NAME"
# NetworkManager will force DHCP host regarless, so changing the hostname through it is more preferable
	echo -e "127.0.0.1\t$NAME" >> /etc/hosts
# no DNS queries will be made to the "new" hostname
#	hostname $RANDOM
	echo 'New hostname : '$(hostname)
# TODO analyze hostname order change and revert with xauth
	xauth add $(hostname)/$(xauth list | cut -d '/' -f 2 | tail -n 1)
	chown $(echo "$XAUTHORITY" | cut -d '/' -f 3): "$XAUTHORITY" 2>/dev/null
# ~/.Xauthority file must have user's privileges with an authorized hostname
#	nmcli con up $INTERFACE &>/dev/null
	echo 'Perform Ethernet DHCP (unless you want to specify your own IP or connect later)? (y/n)'
	read dhcp
	dhcp=${dhcp,,*}
	dhcp=${dhcp::1}
	if [[ "$dhcp" = "y" ]]
	then
		dhclient $INTERFACE &> /dev/null
	fi
	if [[ $CMD =~ .*ip ]]
	then
		echo 'Erasing previous IP...'
		sleep 3
		$CMD addr del $(ip addr show dev $INTERFACE | grep second | cut -d ' ' -f 6 | cut -d '/' -f 1) dev $INTERFACE
	fi
# TODO use already achived IP configuration to avoid broadcast ? done if using ip cmd
# TODO investigate previous IP for different OSes or just ip cmd
	echo 'Now you are a cyberspy, robotic guy'
	echo
#;;off)


elif [[ "$SWITCH" = "off" ]]
then
    # load original MAC address
    if [ ! $(which ethtool) ] && [ ! -f /etc/udev/rules.d/70-persistent-net.rules ]
    then
        ORGMAC=$( cat $TMPMAC )
    else
        if [[ $(which ethtool) ]]
        then
            ORGMAC=$(ethtool -P $INTERFACE)
            ORGMAC=${ORGMAC#*:}
        else
            ORGMAC=$(cat /etc/udev/rules.d/70-persistent-net.rules | grep $INTERFACE | cut -d '"' -f 8)
        fi
    fi
	echo 'Reinitializing MAC address ...'
	echo
#	ifdown $INTERFACE &> /dev/null
#	nmcli con down $INTERFACE &>/dev/null
	/etc/init.d/network-manager stop &>/dev/null
    if [[ $CMD =~ .*ifconfig ]]; then
	    $CMD $INTERFACE down 
#	    rfkill unblock wlan
#	    nmcli radio wifi on
	    $CMD $INTERFACE hw ether $ORGMAC
    else
        $CMD link set $INTERFACE down
#	rfkill unblock wlan
#	nmcli radio wifi on
        $CMD link set dev $INTERFACE address $ORGMAC
    fi

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
	echo 'Restoring hostname ...'
    	/etc/init.d/network-manager start &>/dev/null
#	nmcli con up $INTERFACE &>/dev/null
	xauth remove $(hostname)/$(xauth list | cut -d '/' -f 2 | tail -n 1) 2>/dev/null
	chown $(echo $XAUTHORITY | cut -d '/' -f 3): "$XAUTHORITY" 2>/dev/null
#	hostnamectl set-hostname "$(cat $ORGHOST)"
	nmcli general hostname "$(cat $ORGNAME)"
	sed -i '$ d' /etc/hosts
#	hostname $(cat /etc/hostname)
	echo 'Reinitializing network interface ...'
	echo 'If not connected or taking too long - reconnect manually'
	echo
#	ifup $INTERFACE &> /dev/null
    if [[ $CMD =~ .*ifconfig ]]; then
	    $CMD $INTERFACE up
    else
        $CMD link set $INTERFACE up
    fi
	echo 'Perform Ethernet DHCP (unless you want to specify your own IP or connect later)? (y/n)'
	read dhcp
	dhcp=${dhcp,,*}
	dhcp=${dhcp::1}
	if [[ "$dhcp" = "y" ]]
	then
		dhclient $INTERFACE &> /dev/null
	fi
	sleep 2
	/etc/init.d/network-manager restart &>/dev/null
	rm -f $TMPMAC
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

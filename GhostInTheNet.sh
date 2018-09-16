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
	MAC=$(head -c 6 /proc/sys/kernel/random/uuid | sed 's/^\(..\)\(..\)\(..\).*$/48:0f:cf:\1:\2:\3/')
# random HP vendor MAC, to avoid reserved addresses (unicast, etc) and MAC blacklisting due to lack of randomness
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
	hostnamectl set-hostname $RANDOM
#	hostname $RANDOM
	echo 'New hostname : '$(hostname)
# TODO analyze hostname order change and revert with xauth
# hostnamectl is preferable because of network-manager
	xauth add $(hostname)/$(xauth list | cut -d '/' -f 2 | tail -n 1)
	chown $(echo $XAUTHORITY | cut -d '/' -f 3): $XAUTHORITY 2>/dev/null
# ~/.Xauthority file must have user's privileges with an authorized hostname
#	nmcli con up $INTERFACE &>/dev/null
	echo 'Perform DHCP (unless you want to specify your own IP)? (y/n)'
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
	xauth remove $(hostname)/$(xauth list | cut -d '/' -f 2 | tail -n 1) 2>/dev/null
	chown $(echo $XAUTHORITY | cut -d '/' -f 3): $XAUTHORITY 2>/dev/null
	hostnamectl set-hostname $(cat $ORGHOST)
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
    	/etc/init.d/network-manager start &>/dev/null
#	nmcli con up $INTERFACE &>/dev/null
	echo 'Perform DHCP (unless you want to specify your own IP)? (y/n)'
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

# GhostInTheNet
Ultimate Network Stealther that makes Linux a Ghost In The Net and protects from MITM/DOS

Properties:
* Network Invisibility
* Network Anonymity
* Protects from MITM/DOS
* Transparent
* Cross-platform
* Minimalistic

Dependencies:
* **Linux 2.4.26+** - will work on any Linux-based OS, including Whonix and RaspberryPI
	- BASH - the whole script
	- root privileges - for kernel controlling

Limitations:
* You can still be found with VLAN logs if using ethernet or by triangulation if using WiFi
* MAC spoofing won't work if appropriate mitigations have been taken, like DAI or sticky MAC
* Might be buggy with some CISCO switches
* Not suitable for production servers

## How it works

The basic and primary network protocol is ARP for IPv4 and NDP (ICMPv6) for IPv6, located in the link layer, provides main connectivity in a LAN.

Despite its utility and simplicity, it has numerous vulnerabilities that can lead to the MITM attack and leak of confidentiality.

Patching of such a widely used standard is a practically impossible task.


A very simple, but at the same time effective solution is to disable ARP and NDP responses on an interface and be very cautious with broadcasting.

Considering the varieties of implementations, this means that anyone in the network wouldn't be able to communication with such host, only if the host is willing it-self.

The ARP/NDP cache will be erased quickly afterwards.

Here is an example schema:


A >>> I need MAC address of B >>> B


A <<<        Here it is       <<< B


A <<< I need MAC address of A <<< B


A >>>    I'm not giving it    >>> B


To increase privacy, it's advised to spoof the MAC address, which will provide a better concealment.

All this is possible using simple commands in Linux kernel and a script that automates it all.

## Analysis

No ARP/NDP means no connectivity, so an absolute stealth and obscurity on the network/link layer.

This protects from all possible DOSes and MITMs (ARP, DNS, DHCP, ICMP, Port Stealing) and far less resource consuming like ArpON.

Such mitigation implies impossibility of being scanned (nmap, arping).

Besides, it doesn't impact a normal internet or LAN connection on the host perspective.

If you're connecting to a host, it will be authorised to do so, but shortly after stopping the communication, the host will forget about you because, ARP tables won't stay long without a fresh request.

Regarding the large compatibility and cross-platforming, it's very useful for offsec/pentest/redteaming as well.

You see everyone, but nobody sees you, you're a ghost.

Mitigation and having real supervision on the network will require deep reconfiguration of OSes, IDPSes and all other equipement, so hardly feasible.

### HowTo

You can execute the script after the connection to the network or just before:
```bash
sudo GhostInTheNet.sh on eth0
```
This will activate the solution until reboot.

If you want to stop it:
```bash
sudo GhostInTheNet.sh off eth0
```
Of course, you will have to make the script executable in the first place:
```bash
chmod u+x GhostInTheNet.sh
```

#### Notes

ARP/NDP protocol can be exploited for defensive purpose.

Now your Poisontap is literally undetectable and your Tails is even more anonymous.

You should learn some stuff about IPv6.

> "Stars, hide your fires; Let not light see my black and deep desires."

William Shakespeare, *Macbeth*

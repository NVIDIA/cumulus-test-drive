# Cumulus Linux Test Drive: Lab Guide
This document will guide you through some basic Cumulus Linux configuration on the NVIDIA Air platform. You will connect to your Cumulus lab, configure interfaces, and enable BGP. 

This lab runs **Cumulus Linux 5.14**.

# Topology
The lab runs the following topology: 

![air_simulation-1](https://gitlab.com/cumulus-consulting/goldenturtle/cumulus_ansible_modules/-/raw/evpn_demo_nvue_5.x/Workshop_topology_5.14.png?ref_type=heads)    

# Login Credentials

| System Name | Username | Password |
| --- | --- | --- |
| oob-mgmt-server | ubuntu | nvidia |
| leaf01 | cumulus | Cumu1usLinux! |
| leaf02 | cumulus | Cumu1usLinux! |
| spine01 | cumulus | Cumu1usLinux! |
| server01 | ubuntu | nvidia |
| server02 | ubuntu | nvidia |
| server03 | ubuntu | nvidia |
| server04 | ubuntu | nvidia |

# Lab 1: Verifying Lab Connectivity & Setup

 Let's connect to the out-of-band management server in your lab(`oob-mgmt-server`). The OOB network connects all your nodes together. Then, we will run an Ansible playbook to prepare the simulation for configuration.

### Goals:

- Log into your `oob-mgmt-server`.
- From your `oob-mgmt-server`, run the setup Ansible playbook.


## Accessing Nodes

1. Ensure your simulation is **Powered On**.
2. Open the console to the `oob-mgmt-server`. Double click on the node to do so. 
3. Login with the credentials found in the [Login Credentials](#login-credentials) section.

## Run Setup Playbooks

We must run an Ansible playbook to prepare our nodes for the lab.
The GitLab repository for the playbook has already been cloned for you in the `Test-Drive-Automation` directory. 

To run the playbook:

1.	In the `oob-mgmt-server`, change to the `Test-Drive-Automation` directory.
```
ubuntu@oob-mgmt-server:~$ cd Test-Drive-Automation
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$
```
2. Ensure you are using the `main` branch.
```
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$ git checkout main
Switched to branch 'main'
```

3. Perform a `git pull` to sync/fetch changes.

```
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$ git pull 
Already up-to-date
```
3. Run the `start-lab.yml` Ansible playbook.
```
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$ ansible-playbook start-lab.yml
[WARNING]: Invalid characters were found in group names but not replaced, use
-vvvv to see details

PLAY [host] ********************************************************************

TASK [Setting up the test hosts config] ****************************************
Monday 29 July 2024  12:00:42 +0000 (0:00:00.026)       0:00:00.026 ***********
ok: [server01]
ok: [server02]
ok: [server03]
ok: [server04]

TASK [install traceroute] ******************************************************
Monday 29 July 2024  12:00:44 +0000 (0:00:01.480)       0:00:01.506 ***********
ok: [server01]
ok: [server02]
ok: [server03]
ok: [server04]

TASK [flush arp] ***************************************************************
Monday 29 July 2024  12:00:46 +0000 (0:00:01.879)       0:00:03.386 ***********
changed: [server01]
changed: [server02]
changed: [server03]
changed: [server04]

PLAY RECAP *********************************************************************
server01                   : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server02                   : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server03                   : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server04                   : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Monday 29 July 2024  12:00:47 +0000 (0:00:01.077)       0:00:04.464 ***********
===============================================================================
install traceroute ------------------------------------------------------ 1.88s
Setting up the test hosts config ---------------------------------------- 1.48s
flush arp --------------------------------------------------------------- 1.08s
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$
```

##

**This concludes Lab 1.**

<!-- AIR:page -->

# Lab 2: Interface Configuration

This lab will configure our Cumulus interfaces. 

First, we configure a bond between `leaf01` and `leaf02`. We configure this bond as a trunk to pass `vlan10` and `vlan20`. We configure access ports between leafs and servers. Because `Server01` and `Server02` are in different subnets, `leaf01` and `leaf02` are configured to route for each vlan using VRR to provide high availability gateways for each vlan.

This lab assumes you have completed [Lab 1: Verifying Lab Connectivity & Setup](#Lab-1:-Verifying-Lab-Connectivity-&-Setup).

### Goals:
- Configure loopback addresses for `leaf01` and `leaf02`
- Configure a bond between `leaf01` and `leaf02`
- Configure a bridge
- Create a trunk port and access port
- Configure SVIs on `leaf01` and `leaf02`
- Configure VRR addresses on `leaf01` and `leaf02`

## Configure Loopbacks

| Interface↓ / Switch→ | leaf01 | leaf02 |
| --- | --- | --- |
| Loopback IP | 10.255.255.1/32 | 10.255.255.2/32 | 

1. **[leaf01]**: On `leaf01`, assign **10.255.255.1/32** to `lo`. Apply to the running configuration.
```
cumulus@leaf01:mgmt:~$ nv set interface lo ip address 10.255.255.1/32
cumulus@leaf01:mgmt:~$ nv config apply 
```
2. **[leaf02]**: On `leaf02`, assign **10.255.255.2/32** to `lo`. Apply to the running configuration.
```
cumulus@leaf02:mgmt:~$ nv set interface lo ip address 10.255.255.2/32
cumulus@leaf02:mgmt:~$ nv config apply
```

### Verify

1. **[leaf01]**: Verify.
```
cumulus@leaf01:mgmt:~$ nv show interface lo
                         operational        applied
-----------------------  -----------------  ---------------
type                     loopback           loopback
router
  ospf
    enable                                  off
  pim
    enable                                  off
  ospf6
    enable                                  off
neighbor
  [ipv4]
  [ipv6]
ip
  igmp
    enable                                  off
  ipv4
    forward                                 on
  ipv6
    enable                                  on
    forward                                 on
  vrf                                       default
  [address]              10.255.255.1/32    10.255.255.1/32
  [address]              127.0.0.1/8
  [address]              ::1/128
link
  mtu                    65536
  state                  up
  stats
    in-bytes             776.02 KB
    in-pkts              11960
    in-drops             0
    in-errors            0
    out-bytes            776.02 KB
    out-pkts             11960
    out-drops            0
    out-errors           0
    carrier-transitions  0
  mac                    00:00:00:00:00:00
  protodown              disabled
  oper-status            unknown
  admin-status           up
ifindex                  1


```

2.  **[leaf02]**: Verify.
```
cumulus@leaf02:mgmt:~$ nv show interface lo
                         operational        applied
-----------------------  -----------------  ---------------
type                     loopback           loopback
router
  ospf
    enable                                  off
  pim
    enable                                  off
  ospf6
    enable                                  off
neighbor
  [ipv4]
  [ipv6]
ip
  igmp
    enable                                  off
  ipv4
    forward                                 on
  ipv6
    enable                                  on
    forward                                 on
  vrf                                       default
  [address]              10.255.255.2/32    10.255.255.2/32
  [address]              127.0.0.1/8
  [address]              ::1/128
link
  mtu                    65536
  state                  up
  stats
    in-bytes             792.01 KB
    in-pkts              12208
    in-drops             0
    in-errors            0
    out-bytes            792.01 KB
    out-pkts             12208
    out-drops            0
    out-errors           0
    carrier-transitions  0
  mac                    00:00:00:00:00:00
  protodown              disabled
  oper-status            unknown
  admin-status           up
ifindex                  1

```

## Configure Bonds

| Bond↓ / Switch→ | leaf01 |  leaf02 |
| --- | --- | --- |
| Bond name | BOND0 | BOND0 | 
| Bond members | swp49, swp50 | swp49, swp50 |


1. **[leaf01]**: Create a bond **bond0** with members `swp49` and `swp50`. Apply to the running configuration.
```
cumulus@leaf01:mgmt:~$ nv set interface bond0 bond member swp49-50
cumulus@leaf01:mgmt:~$ nv config apply
```

2. **[leaf02]**: Create a bond **bond0** with members `swp49` and `swp50`. Apply to the running configuration.
```
cumulus@leaf02:mgmt:~$ nv set interface bond0 bond member swp49-50
cumulus@leaf02:mgmt:~$ nv config apply
```

### Verify

1. **[leaf01]**: Verify the bond is applied.
```
cumulus@leaf01:mgmt:~$ nv show interface bond0 bond
             operational  applied
-----------  -----------  -------
down-delay   0            0
lacp-bypass  off          off
lacp-rate    fast         fast
mode                      lacp
up-delay     0            0
[member]     swp49        swp49
[member]     swp50        swp50
mlag
  enable                  off
```
2. **[leaf01]**: Verify the bond is operational.
```
cumulus@leaf01:mgmt:~$ nv show interface bond0 bond member
       bonding-state  mii-status
-----  -------------  ----------
swp49  active         up
swp50  active         up

```

3. **[leaf02]**: Verify the bond is applied.
```
cumulus@leaf02:mgmt:~$ nv show interface bond0 bond
             operational  applied
-----------  -----------  -------
down-delay   0            0
lacp-bypass  off          off
lacp-rate    fast         fast
mode                      lacp
up-delay     0            0
[member]     swp49        swp49
[member]     swp50        swp50
mlag
  enable                  off
```
4. **[leaf02]**: Verify the bond is operational.
```
cumulus@leaf02:mgmt:~$ nv show interface bond0 bond member
       bonding-state  mii-status
-----  -------------  ----------
swp49  active         up
swp50  active         up

```

 **Important things to observe:**
- The speed of the bond is the cumulative speed of all member interfaces.

## Configure Bridges and Access Ports

| Bridge↓ / Switch→ | leaf01 |  leaf02 |
| --- | --- | --- |
| **Bridge vlans**  | 10, 20 | 10, 20 | 
| **Bridge members** | bond0, swp1 | bond0, swp2 |
| **Bridge access port** |  swp1 | swp2 |
| **Bridge access vlan** |  10 | 20 |

1. **[leaf01]**: Create a bridge **br_default** on `vlan10` & `vlan20`.
```
 cumulus@leaf01:mgmt:~$ nv set bridge domain br_default vlan 10,20
```

2. **[leaf01]**: Add `swp1` and `bond0` as a member to the bridge. 
 
 _**Note:** The name `bond0` is case-sensitive._
```
cumulus@leaf01:mgmt:~$ nv set interface swp1,bond0 bridge domain br_default
```

3. **[leaf01]**: Configure `swp1` as an access port for `vlan10`.
```
cumulus@leaf01:mgmt:~$ nv set interface swp1 bridge domain br_default access 10
```

4. **[leaf01]**: Apply to the running configuration.
```
cumulus@leaf01:mgmt:~$ nv config apply
```

5. **[leaf02]**: Repeat for `leaf02`.
```
cumulus@leaf02:mgmt:~$ nv set bridge domain br_default vlan 10,20
cumulus@leaf02:mgmt:~$ nv set interface swp2,bond0 bridge domain br_default
cumulus@leaf02:mgmt:~$ nv set interface swp2 bridge domain br_default access 20
cumulus@leaf02:mgmt:~$ nv config apply
```
A code snippet is provided for easy copy and pasting into Cumulus: 
```
nv set bridge domain br_default vlan 10,20
nv set interface swp2,bond0 bridge domain br_default
nv set interface swp2 bridge domain br_default access 20
nv config apply
```

### Verify

1. **[leaf01]**: Verify `swp1` and `bond0` are part of the bridge.
```
cumulus@leaf01$ nv show bridge domain br_default
Bridge info:
    mac-address         : 44:38:39:22:01:80
    type                : vlan-aware
    encap               : 802.1Q
    ageing              : 1800
    stp mode            : rstp
    vlan-vni-offset     : -

Bridge Vlan Info :
untagged      tagged
------------- ---------------------------------------------------
1             10,20

Bridge Port Info:
Port           State
-------------- ---------------
bond0          forwarding
swp1           forwarding
```
2. **[leaf02]**: Verify `swp2` and `bond0` are part of the bridge.
```
cumulus@leaf02$ nv show bridge domain br_default
Bridge info:
    mac-address         : 44:38:39:22:01:c8
    type                : vlan-aware
    encap               : 802.1Q
    ageing              : 1800
    stp mode            : rstp
    vlan-vni-offset     : -

Bridge Vlan Info :
untagged      tagged
------------- ---------------------------------------------------
1             10,20

Bridge Port Info:
Port           State
-------------- ---------------
bond0          forwarding
swp2           forwarding
```


## Configure SVIs & VRR

| Setting↓ / Switch→ | leaf01 | leaf02 |
| --- | --- | --- |
| **VLAN10 real IP address** | 10.0.10.2/24 | 10.0.10.3/24 |
| **VLAN10 VRR IP address** | 10.0.10.1/24 | 10.0.10.1/24 |
| **VLAN10 VRR MAC address** | 00:00:00:00:1a:10 | 00:00:00:00:1a:10 |
| **VLAN20 real IP address** | 10.0.20.2/24 | 10.0.20.3/24 |
| **VLAN20 VRR IP address** | 10.0.20.1/24 | 10.0.20.1/24 |
| **VLAN20 VRR MAC address** | 00:00:00:00:1a:20 | 00:00:00:00:1a:20 |
| **Server01 VLAN** | 10 | 10 |
| **Server01 VLAN** | 20 | 20 |

1. **[leaf01]**: Create an SVI **10.0.10.2/24** for `vlan10`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan10 ip address 10.0.10.2/24
```

2. **[leaf01]**: Create an SVI **10.0.20.2/24** for `vlan20`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan20 ip address 10.0.20.2/24
```

3. **[leaf01]**: Apply a VRR **10.0.10.1/24** for `vlan10`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan10 ip vrr address 10.0.10.1/24
```
4. **[leaf01]**: Apply a MAC **00:00:00:00:1a:10** for `vlan10`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan10 ip vrr mac-address 00:00:00:00:1a:10
```

5. **[leaf01]**: Bring up the VRR for `vlan10`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan10 ip vrr state up
```



6. **[leaf01]**: Apply a VRR **10.0.20.1/24** for `vlan20`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan20 ip vrr address 10.0.20.1/24
```
7. **[leaf01]**: Apply a MAC **00:00:00:00:1a:20** for `vlan20`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan20 ip vrr mac-address 00:00:00:00:1a:20
```

8. **[leaf01]**: Bring up the VRR for `vlan20`.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan20 ip vrr state up
```


9. **[leaf01]**: Apply to the running configuration.
```
cumulus@leaf01:mgmt:~$ nv config apply
```

10.  **[leaf02]**: Repeat for `leaf02` with the following configuration.
```
cumulus@leaf02:mgmt:~$ nv set interface vlan10 ip address 10.0.10.3/24
cumulus@leaf02:mgmt:~$ nv set interface vlan20 ip address 10.0.20.3/24
cumulus@leaf02:mgmt:~$ nv set interface vlan10 ip vrr address 10.0.10.1/24
cumulus@leaf02:mgmt:~$ nv set interface vlan10 ip vrr mac-address 00:00:00:00:1a:10
cumulus@leaf02:mgmt:~$ nv set interface vlan10 ip vrr state up
cumulus@leaf02:mgmt:~$ nv set interface vlan20 ip vrr address 10.0.20.1/24
cumulus@leaf02:mgmt:~$ nv set interface vlan20 ip vrr mac-address 00:00:00:00:1a:20
cumulus@leaf02:mgmt:~$ nv set interface vlan20 ip vrr state up
cumulus@leaf02:mgmt:~$ nv config apply
```

A code snippet is provided for easy copy and pasting into Cumulus: 
```
nv set interface vlan10 ip address 10.0.10.3/24
nv set interface vlan20 ip address 10.0.20.3/24
nv set interface vlan10 ip vrr address 10.0.10.1/24
nv set interface vlan10 ip vrr mac-address 00:00:00:00:1a:10
nv set interface vlan10 ip vrr state up
nv set interface vlan20 ip vrr address 10.0.20.1/24
nv set interface vlan20 ip vrr mac-address 00:00:00:00:1a:20
nv set interface vlan20 ip vrr state up
nv config apply
```


## Verify Connectivity

1. **[server01]**: Ping the VRR gateway address for `vlan10`.
```
ubuntu@server01:~$ ping 10.0.10.1 -c 2
PING 10.0.10.1 (10.0.10.1) 56(84) bytes of data.
64 bytes from 10.0.10.1: icmp_seq=1 ttl=64 time=0.686 ms
64 bytes from 10.0.10.1: icmp_seq=2 ttl=64 time=0.922 ms

--- 10.0.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.686/0.804/0.922/0.118 ms
```

2. **[server01]**: Ping the real IP Address of `leaf01` for `vlan10`.
```
ubuntu@server01:~$ ping 10.0.10.2 -c 2
PING 10.0.10.2 (10.0.10.2) 56(84) bytes of data.
64 bytes from 10.0.10.2: icmp_seq=1 ttl=64 time=0.887 ms
64 bytes from 10.0.10.2: icmp_seq=2 ttl=64 time=0.835 ms

--- 10.0.10.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.835/0.861/0.887/0.026 ms
```

3. **[server01]**: Ping the real IP Address of `leaf02` for `vlan10`.
```
ubuntu@server01:~$ ping 10.0.10.3 -c 2
PING 10.0.10.3 (10.0.10.3) 56(84) bytes of data.
64 bytes from 10.0.10.3: icmp_seq=1 ttl=64 time=0.528 ms
64 bytes from 10.0.10.3: icmp_seq=2 ttl=64 time=0.876 ms

--- 10.0.10.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.528/0.702/0.876/0.174 ms
```

4. **[server01]**: Check the IP neighbor table to view each MAC address. You can also use the `arp -a` command.
```
ubuntu@server01:~$ ip neighbor show
192.168.200.1 dev eth0 lladdr 44:38:39:00:00:11 REACHABLE
10.0.10.1 dev eth1 lladdr 00:00:00:00:1a:10 STALE
10.0.10.2 dev eth1 lladdr 44:38:39:00:00:05 STALE
10.0.10.3 dev eth1 lladdr 44:38:39:00:00:0b STALE
fe80::4638:39ff:fe00:5 dev eth1 lladdr 44:38:39:00:00:05 router STALE
fe80::4638:39ff:fe00:12 dev eth0 lladdr 44:38:39:00:00:12 router STALE
fe80::4638:39ff:fe00:b dev eth1 lladdr 44:38:39:00:00:0b router REACHABLE
```

5. **[server01]**: Ping `server02`.
```
ubuntu@server01:~$ ping 10.0.20.102 -c 2
PING 10.0.20.102 (10.0.20.102) 56(84) bytes of data.
64 bytes from 10.0.20.102: icmp_seq=1 ttl=63 time=0.790 ms
64 bytes from 10.0.20.102: icmp_seq=2 ttl=63 time=1.35 ms
^C
--- 10.0.20.102 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.790/1.070/1.351/0.282 ms
```

6. **[server01]**: Observe routes with `traceroute`.
```
ubuntu@server01:~$ traceroute 10.0.20.102
traceroute to 10.0.20.102 (10.0.20.102), 30 hops max, 60 byte packets
1 10.0.10.1 (10.0.10.1) 1.628 ms 1.672 ms 1.855 ms
2 10.0.20.102 (10.0.20.102) 7.947 ms 7.973 ms 8.155 ms
ubuntu@server01:~$
```

7. **[server02]**: Ping the VRR gateway address for `vlan20`.
```
ubuntu@server02:~$ ping 10.0.20.1 -c 2
PING 10.0.20.1 (10.0.20.1) 56(84) bytes of data.
64 bytes from 10.0.20.1: icmp_seq=1 ttl=64 time=1.22 ms
64 bytes from 10.0.20.1: icmp_seq=2 ttl=64 time=0.672 ms

--- 10.0.20.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.672/0.949/1.226/0.277 ms
```

8. **[server02]**: Ping the real IP Address of `leaf01` for `vlan20`.
```
ubuntu@server02:~$ ping 10.0.20.2 -c 2
PING 10.0.20.2 (10.0.20.2) 56(84) bytes of data.
64 bytes from 10.0.20.2: icmp_seq=1 ttl=64 time=0.735 ms
64 bytes from 10.0.20.2: icmp_seq=2 ttl=64 time=1.02 ms

--- 10.0.20.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.735/0.882/1.029/0.147 ms
```

9. **[server02]**: Ping the real IP Address of `leaf02` for `vlan20`.
```
ubuntu@server02:~$ ping 10.0.20.3 -c 2
PING 10.0.20.3 (10.0.20.3) 56(84) bytes of data.
64 bytes from 10.0.20.3: icmp_seq=1 ttl=64 time=0.993 ms
64 bytes from 10.0.20.3: icmp_seq=2 ttl=64 time=1.08 ms

--- 10.0.20.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.993/1.040/1.087/0.047 ms
```

10. **[server02]**: Check the IP neighbor table to view each MAC address. You can also use the `arp -a` command.
```
ubuntu@server02:~$ ip neighbor show
192.168.200.1 dev eth0 lladdr 44:38:39:00:00:11 REACHABLE
10.0.20.2 dev eth2 lladdr 44:38:39:00:00:05 REACHABLE
10.0.20.3 dev eth2 lladdr 44:38:39:00:00:0b REACHABLE
10.0.20.1 dev eth2 lladdr 00:00:00:00:1a:20 STALE
fe80::4638:39ff:fe00:5 dev eth2 lladdr 44:38:39:00:00:05 router STALE
fe80::4638:39ff:fe00:12 dev eth0 lladdr 44:38:39:00:00:12 router STALE
fe80::4638:39ff:fe00:b dev eth2 lladdr 44:38:39:00:00:0b router STALE
```

11. **[server02]**: Ping `server01`.
```
ubuntu@server02:~$  ping 10.0.10.101 -c 2
PING 10.0.10.101 (10.0.10.101) 56(84) bytes of data.
64 bytes from 10.0.10.101: icmp_seq=1 ttl=63 time=1.08 ms
64 bytes from 10.0.10.101: icmp_seq=2 ttl=63 time=1.36 ms

--- 10.0.10.101 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.089/1.225/1.361/0.136 ms
```


12. **[server02]**: Observe routes with `traceroute`.
```
ubuntu@server02:~$ traceroute 10.0.10.101
traceroute to 10.0.10.101 (10.0.10.101), 30 hops max, 60 byte packets
1 10.0.20.1 (10.0.20.1) 2.813 ms 2.776 ms 3.307 ms
2 10.0.10.101 (10.0.10.101) 9.199 ms 7.836 ms 7.766 ms
ubuntu@server02:~$
```

### Verify MAC Address Tables

1. **[leaf01]**: Verify MACs are learned correctly.
```
cumulus@leaf01:mgmt:~$ nv show bridge domain br_default mac-table
entry-id  MAC address        vlan  interface   remote-dst  src-vni  entry-type  last-update  age
--------  -----------------  ----  ----------  ----------  -------  ----------  -----------  -------
1         48:b0:2d:db:95:44  10    swp1                                         0:00:00      0:01:43
2         48:b0:2d:f8:3d:4c        swp1                             permanent   0:16:37      0:16:37
3         48:b0:2d:46:ba:d2  20    bond0                                        0:00:29      0:07:15
4         00:00:00:00:1a:20  20    bond0                                        0:00:39      0:10:08
5         44:38:39:22:01:c8  20    bond0                                        0:00:24      0:10:08
6         44:38:39:22:01:c8  10    bond0                                        0:01:43      0:04:22
7         44:38:39:22:01:c8  1     bond0                                        0:14:17      0:14:19
8         48:b0:2d:44:7b:d7  1     bond0                                        0:00:27      0:16:27
9         48:b0:2d:4e:b6:de  1     bond0                                        0:00:27      0:16:27
10        48:b0:2d:8b:5f:13  1     bond0                            permanent   0:16:37      0:16:37
11        48:b0:2d:8b:5f:13        bond0                            permanent   0:16:37      0:16:37
12        00:00:00:00:1a:10        br_default                       permanent
13        44:38:39:22:01:80  20    br_default                       permanent   0:10:34      0:10:34
14        00:00:00:00:1a:10  10    br_default                       permanent   0:10:34      0:10:34
15        44:38:39:22:01:80  10    br_default                       permanent   0:10:34      0:10:34
16        44:38:39:22:01:80  1     br_default                       permanent   0:16:37      0:16:37
17        44:38:39:22:01:80        br_default                       permanent   0:16:37      0:16:37

```

2. **[leaf02]**: Verify MACs are learned correctly.

```
cumulus@leaf02:mgmt:~$ nv show bridge domain br_default mac-table
entry-id  MAC address        vlan  interface   remote-dst  src-vni  entry-type  last-update  age
--------  -----------------  ----  ----------  ----------  -------  ----------  -----------  -------
1         48:b0:2d:46:ba:d2  20    swp2                                         0:00:30      0:02:11
2         48:b0:2d:cc:6c:c4        swp2                             permanent   0:16:04      0:16:04
3         48:b0:2d:db:95:44  10    bond0                                        0:01:07      0:07:25
4         44:38:39:22:01:80  20    bond0                                        0:02:11      0:02:11
5         44:38:39:22:01:80  10    bond0                                        0:01:09      0:12:17
6         48:b0:2d:19:9b:8a  1     bond0                                        0:00:09      0:15:39
7         48:b0:2d:8b:5f:13  1     bond0                                        0:00:00      0:16:02
8         48:b0:2d:44:7b:d7  1     bond0                            permanent   0:16:04      0:16:04
9         48:b0:2d:44:7b:d7        bond0                            permanent   0:16:04      0:16:04
10        00:00:00:00:1a:10        br_default                       permanent
11        00:00:00:00:1a:20        br_default                       permanent
12        00:00:00:00:1a:20  20    br_default                       permanent   0:11:50      0:11:50
13        44:38:39:22:01:c8  20    br_default                       permanent   0:11:50      0:11:50
14        44:38:39:22:01:c8  10    br_default                       permanent   0:11:50      0:11:50
15        00:00:00:00:1a:10  10    br_default                       permanent   0:11:50      0:11:50
16        44:38:39:22:01:c8  1     br_default                       permanent   0:16:04      0:16:04
17        44:38:39:22:01:c8        br_default                       permanent   0:16:04      0:16:04

```
**Important things to observe:**
-   The MAC addresses of servers should be learned on `bond0` and `swp` interfaces of the switch.

**This concludes Lab 2.**

<!-- AIR:page -->

##
## Lab 3: FRR & BGP Unnumbered

This lab will configure BGP unnumbered between `leaf01/leaf02` and `spine01`. This configuration will share the IP addresses of the loopback interfaces on each device as well as the `vlan10` and `vlan20` subnets on the `leaf01` and `leaf02` devices.

This lab assumes you have completed [Lab 1: Verifying Lab Connectivity & Setup](#Lab-1:-Verifying-Lab-Connectivity-&-Setup) and [Lab 2: Interface Configuration](#Lab-2:-Interface-Configuration) .

### Goals:

- Configure BGP unnumbered on `leaf01`, `leaf02` & `spine01`
- Advertise loopback addresses into BGP
- Advertise SVI subnets of leafs into BGP
- Verify BGP peering
- Verify BGP route advertisements
- Verify routed connectivity and path between servers


## Run Setup Playbooks
We must run another Ansible playbook to prepare our nodes for the lab.

1. In the `oob-mgmt-server`, change to the `Test-Drive-Automation` directory.
```
ubuntu@oob-mgmt-server:~$ cd Test-Drive-Automation
```
2. Run the `lab3.yml` Ansible playbook.
```
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$ ansible-playbook lab3.yml
```

## Configure Loopback on Spine

Configure the `lo` address for `spine01`. We already configured loopbacks for `leaf01` and `leaf01` in the previous lab.

| Configuration↓ / Switch→ | leaf01 | leaf02 | spine01 |
| --- | --- | --- | --- |
| **Loopback IP address** | 10.255.255.1/32 | 10.255.255.2/32 | 10.255.255.101/32 |

1. **[spine01]**: On `spine01`, assign **10.255.255.101/32** to `lo`. Apply to the running configuration.
```
cumulus@spine01:mgmt:~$ nv set interface lo ip address 10.255.255.101/32
cumulus@spine01:mgmt:~$ nv config apply
```


## Configure BGP Unnumbered

1. **[spine01]**: Configure a BGP Autonomous System (AS) number for the routing instance. Multipath-relax is typically configured to more easily accommodate load sharing via ECMP.
```
cumulus@spine01:mgmt:~$ nv set vrf default router bgp autonomous-system 65201
cumulus@spine01:mgmt:~$ nv set vrf default router bgp path-selection multipath aspath-ignore on
cumulus@spine01:mgmt:~$ nv set router bgp router-id 10.255.255.101
```


2. **[spine01]**: Configure BGP peering on `swp1` towards `leaf01` and `swp2` towards `leaf02`.
```
cumulus@spine01:mgmt:~$ nv set vrf default router bgp neighbor swp1 remote-as external
cumulus@spine01:mgmt:~$ nv set vrf default router bgp neighbor swp2 remote-as external 
```
3. **[spine01]**: Apply to the running configuration.
```
cumulus@spine01:mgmt:~$ nv config apply 
```
4. **[leaf01]**: Repeat for `leaf01`.
```
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp autonomous-system 65101
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp path-selection multipath aspath-ignore on 
cumulus@leaf01:mgmt:~$ nv set router bgp router-id 10.255.255.1
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp neighbor swp51 remote-as external
cumulus@leaf01:mgmt:~$ nv config apply 
```

A code snippet is provided for easy copy and pasting into Cumulus:
```
nv set vrf default router bgp autonomous-system 65101
nv set vrf default router bgp path-selection multipath aspath-ignore on
nv set router bgp router-id 10.255.255.1
nv set vrf default router bgp neighbor swp51 remote-as external
nv config apply
```
5. **[leaf02]**: Repeat for `leaf02`.
```
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp autonomous-system 65102
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp path-selection multipath aspath-ignore on
cumulus@leaf02:mgmt:~$ nv set router bgp router-id 10.255.255.2
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp neighbor swp51 remote-as external 
cumulus@leaf02:mgmt:~$ nv config apply
```

A code snippet is provided for easy copy and pasting into Cumulus:
```
nv set vrf default router bgp autonomous-system 65102
nv set vrf default router bgp path-selection multipath aspath-ignore on
nv set router bgp router-id 10.255.255.2
nv set vrf default router bgp neighbor swp51 remote-as external 
nv config apply
```

### Verify BGP Connectivity Between Fabric Nodes

Verify BGP peers are connected. We can use `vtysh` to observe peering. 

Learn more about [vtysh](https://docs.frrouting.org/projects/dev-guide/en/latest/vtysh.html).

1.  **[spine01]**: Verify BGP peering between spine and leafs.
```
cumulus@spine01:mgmt:~$ sudo vtysh -c " show ip bgp summary"

IPv4 Unicast Summary (VRF default):
BGP router identifier 10.255.255.101, local AS number 65201 vrf-id 0
BGP table version 5
RIB entries 9, using 1728 bytes of memory
Peers 2, using 40 KiB of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
leaf01(swp1)    4      65101        83        83        0    0    0 00:03:51            2        5 N/A
leaf02(swp2)    4      65102        78        78        0    0    0 00:03:38            2        5 N/A

Total number of neighbors 2
```

2. **[leaf01]**: Verify BGP peering between leafs and spine.
```
cumulus@leaf01:mgmt:~$ sudo vtysh -c " show ip bgp summary"

IPv4 Unicast Summary (VRF default):
BGP router identifier 10.255.255.1, local AS number 65101 vrf-id 0
BGP table version 5
RIB entries 9, using 1728 bytes of memory
Peers 1, using 20 KiB of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
spine01(swp51)  4      65201        92        93        0    0    0 00:04:18            3        5 N/A

Total number of neighbors 1
```

3. **[leaf02]**: Verify BGP peering between leafs and spine.
```
cumulus@leaf02:mgmt:~$ sudo vtysh -c " show ip bgp summary"

IPv4 Unicast Summary (VRF default):
BGP router identifier 10.255.255.2, local AS number 65102 vrf-id 0
BGP table version 5
RIB entries 9, using 1728 bytes of memory
Peers 1, using 20 KiB of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
cumulus(swp51)  4      65201        96        97        0    0    0 00:04:31            3        5 N/A

Total number of neighbors 1
```

 **Important things to observe:**
- The BGP neighbor displays the hostname of the BGP peer.
- No routes are being advertised yet.
- The BGP router identifier uses the loopback address.
- You can use either NVUE (`nv`) commands or `vtysh` to observe BGP peering.


## Advertise Loopback and SVI Subnets into the Fabric

| Routes↓ / Switch→ | leaf01 | leaf02 | spine01 |
| --- | --- | --- | --- |
| **Subnets to be advertised** | 10.255.255.1/32 | 10.255.255.2/32 | 10.255.255.101/32 |
| | 10.0.10.0/24 | 10.0.20.0/24 | |

1. **[spine01]**: Advertise the loopback address into BGP. Apply to the running configuration.
```
cumulus@spine01:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.101/32
cumulus@spine01:mgmt:~$ nv config apply
```
2. **[leaf01]**: Advertise the loopback address into BGP.
```
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.1/32
```
3. **[leaf01]**: Advertise the subnet for `vlan10`.
```
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.0.10.0/24
```
4. **[leaf01]**: Apply to the running configuration.
```
cumulus@leaf01:mgmt:~$ nv config apply
```

5. **[leaf02]**: Repeat for `leaf02`.
```
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.2/32
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.0.20.0/24
cumulus@leaf02:mgmt:~$ nv config apply
```

A code snippet is provided for easy copy and pasting into Cumulus:
```
nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.2/32
nv set vrf default router bgp address-family ipv4-unicast network 10.0.20.0/24
nv config apply
```


## Verify BGP Route Advertisement

1.  **[spine01]**: Verify routes are learned.
```
cumulus@spine01:mgmt:~$ sudo vtysh -c "show ip bgp ipv4 unicast"
BGP table version is 5, local router ID is 10.255.255.101, vrf id 0
Default local pref 100, local AS 65201
Status codes:  s suppressed, d damped, h history, u unsorted, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 10.0.10.0/24     swp1                     0             0 65101 i
*> 10.0.20.0/24     swp2                     0             0 65102 i
*> 10.255.255.1/32  swp1                     0             0 65101 i
*> 10.255.255.2/32  swp2                     0             0 65102 i
*> 10.255.255.101/32
                    0.0.0.0(spine01)
                                             0         32768 i

Displayed  5 routes and 5 total paths
```

**Important things to observe:**
- AS_PATH identifies where routes are originating.
- Because we configured BGP unnumbered, NEXT_HOP is an interface and not an IP address.
- An 0.0.0.0 address means a locally originated route.


## Verify Server Connectivity

1. **[server01]**: Ping `server02`.
```
ubuntu@server01:~$ ping 10.0.20.102 -c 2
PING 10.0.20.102 (10.0.20.102) 56(84) bytes of data.
64 bytes from 10.0.20.102: icmp_seq=1 ttl=63 time=1.05 ms
64 bytes from 10.0.20.102: icmp_seq=2 ttl=63 time=1.15 ms

--- 10.0.20.102 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.052/1.102/1.153/0.060 ms
```

2. **[server01]**: Traceroute to `server02`. Identify the hops.
```
ubuntu@server01:~$ traceroute 10.0.20.102
traceroute to 10.0.20.102 (10.0.20.102), 30 hops max, 60 byte packets
 1  10.0.10.1 (10.0.10.1)  0.357 ms  0.289 ms  0.257 ms
 2  10.255.255.101 (10.255.255.101)  0.899 ms  0.878 ms  0.855 ms
 3  10.255.255.2 (10.255.255.2)  0.737 ms  0.708 ms  0.686 ms
 4  10.0.20.102 (10.0.20.102)  1.401 ms  1.342 ms  1.320 ms
ubuntu@server01:~$ 
```

**Important things to observe:**
- With Unnumbered interfaces, traceroute (ICMP source interface) packets come from the loopback IPv4 address of the node.

**This concludes the Cumulus Linux Test Drive.**

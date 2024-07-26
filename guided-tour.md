# Cumulus Linux Test Drive: Lab Guide

## Topology Diagram
![Workshop Topology diagram-1](https://raw.githubusercontent.com/NVIDIA/cumulus-test-drive/main/CL_Workshop.svg)


## Lab 1: Verifying Lab Connectivity

**Objective:**

In Lab 1, we'll access the oob-mgmt-server .  The first part of this lab includes how to access Cumulus In the Cloud and your lab workbench.

**Goals:**

- Connect to the oob-mgmt-server  
- Run the setup playbook

##
## Connect to the oob-mgmt-server

1. In the window below labeled `Nodes` click on the `oob-mgmt-server` device. This will pop open a new browser window that provides console access to the device.  

2. Log into the oob-mgmt-server with the username `ubuntu` and password `nvidia`

3. Then, follow the instructions to set a new password.

##
## Run the setup playbook

1. Change directories to the folder named `Test-Drive-Automation` from the user cumulus home directory.
```
ubuntu@oob-mgmt-server:~$ cd Test-Drive-Automation
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$
```
2. Perform a `git pull` to sync/fetch changes
```
cumulus@oob-mgmt-server:~/Test-Drive-Automation$ git checkout CL_demo_5.6
Switched to branch 'CL_demo_5.6'
Your branch is ahead of 'origin/CL_demo_5.6' by 1 commit.
  (use "git push" to publish your local commits)
cumulus@oob-mgmt-server:~/github_public/cumulus-test-drive$
cumulus@oob-mgmt-server:~/Test-Drive-Automation$ git pull 
Already up-to-date
cumulus@oob-mgmt-server:~/Test-Drive-Automation$ 
```
3. Run the `start-lab.yml` Ansible playbook.
```
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$ ansible-playbook start-lab.yml
 [WARNING]: Invalid characters were found in group names but not replaced, useml
-vvvv to see details

PLAY [localhost] ***************************************************************

TASK [place license on webserver] **********************************************
Thursday 11 February 2021  18:12:41 +0000 (0:00:00.061)       0:00:00.061 *****
changed: [localhost]

PLAY [server01:server02] *******************************************************

TASK [Setting up the test hosts config] ****************************************
Thursday 11 February 2021  18:12:42 +0000 (0:00:00.781)       0:00:00.842 *****
changed: [server01]
changed: [server02]

TASK [install traceroute] ******************************************************
Thursday 11 February 2021  18:12:45 +0000 (0:00:03.115)       0:00:03.957 *****
[WARNING]: Updating cache and auto-installing missing dependency: python-apt
changed: [server01]
changed: [server02]

TASK [remove netq] *************************************************************
Thursday 11 February 2021  18:12:58 +0000 (0:00:12.826)       0:00:16.783 *****
changed: [server02]
changed: [server01]

RUNNING HANDLER [apply interface config] ***************************************
Thursday 11 February 2021  18:13:08 +0000 (0:00:10.080)       0:00:26.863 *****
changed: [server02]
changed: [server01]

PLAY RECAP *********************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server01                   : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server02                   : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Thursday 11 February 2021  18:13:10 +0000 (0:00:02.161)       0:00:29.025 *****
===============================================================================
install traceroute ----------------------------------------------------- 12.83s
remove netq ------------------------------------------------------------ 10.08s
Setting up the test hosts config ---------------------------------------- 3.12s
apply interface config -------------------------------------------------- 2.16s
place license on webserver ---------------------------------------------- 0.78s
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$
```

##

**This concludes Lab 1.**

<!-- AIR:page -->

# Lab 2: Interface Configuration
**Objective:**

This lab will configure several types of interfaces. First, a bond will be configured between leaf01 and leaf02. The bond will be configured as a trunk to pass vlan10 and vlan20. Connections between leafs and servers will be configured as access ports. Server01 and Server02 will be in different subnets, so leaf01 and leaf02 will be configured to route for each vlan using VRR to provide high availability gateways for each vlan.

**Dependencies on other Labs:**

- Ensure you run the Ansible playbook in Lab1. 
- Refer to the step `Run the setup playbook` from Lab1 on the previous page

**Goals:**
- Configure loopback addresses for leaf01 and leaf02
- Configure a bond between leaf01 and leaf02
- Configure a bridge
- Create a trunk port and access port
- Configure SVIs on leaf01 and leaf02
- Configure VRR addresses on leaf01 and leaf02
##
## Configure loopback addresses on leaf01 and leaf02

| Interface↓ / Switch→ | leaf01 | leaf02 |
| --- | --- | --- |
| Loopback IP | 10.255.255.1/32 | 10.255.255.2/32 | 

1. **On leaf01** : Assign an ip address to the loopback interface.
```
cumulus@leaf01:mgmt:~$ nv set interface lo ip address 10.255.255.1/32
cumulus@leaf01:mgmt:~$ nv config apply 
```
2. **On leaf02** : Assign an ip address to the loopback interface.
```
cumulus@leaf02:mgmt:~$ nv set interface lo ip address 10.255.255.2/32
cumulus@leaf02:mgmt:~$ nv config apply
```

##
## Verify loopback IP address configuration

1. **On leaf01** : Check that the address has been applied.
```
                         operational        applied
-----------------------  -----------------  ---------------
type                     loopback           loopback
router
  adaptive-routing
    enable                                  off
  ospf
    enable                                  off
  ospf6
    enable                                  off
  pim
    enable                                  off
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
    carrier-transitions  0
    in-bytes             210.70 KB
    in-drops             0
    in-errors            0
    in-pkts              3266
    out-bytes            210.70 KB
    out-drops            0
    out-errors           0
    out-pkts             3266
  mac                    00:00:00:00:00:00
ifindex                  1


```

2. **On leaf02** : Check that the address has been applied.
```
cumulus@leaf02:mgmt:~$ nv show interface lo
                         operational        applied
-----------------------  -----------------  ---------------
type                     loopback           loopback
router
  adaptive-routing
    enable                                  off
  ospf
    enable                                  off
  ospf6
    enable                                  off
  pim
    enable                                  off
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
    carrier-transitions  0
    in-bytes             213.07 KB
    in-drops             0
    in-errors            0
    in-pkts              3304
    out-bytes            213.07 KB
    out-drops            0
    out-errors           0
    out-pkts             3304
  mac                    00:00:00:00:00:00
ifindex                  1

```

**Important things to observe:**
- Loopback has user-defined IP address as well as home address assigned to it
- Loopback has a predefined default configuration on Cumulus Linux. Make sure not to delete it.

##
## Configure bond between leaf01 and leaf02
**Bond Configuration Details:**

| Bond↓ / Switch→ | leaf01 |  leaf02 |
| --- | --- | --- |
| Bond name | BOND0 | BOND0 | 
| Bond members | swp49,swp50 | swp49,swp50 |


1. **On leaf01** : Create a bond with members swp49 and swp50.
```
cumulus@leaf01:mgmt:~$ nv set interface bond0 bond member swp49-50
cumulus@leaf01:mgmt:~$ nv config apply
```

2. **On leaf02**: Create a bond with members swp49 and swp50.
```
cumulus@leaf02:mgmt:~$ nv set interface bond0 bond member swp49-50
cumulus@leaf02:mgmt:~$ nv config apply
```

3. **On each leaf**: Check status of the bond between two switches. Verify that the bond is operational by checking the status of the bond and its members.
```
cumulus@leaf01:mgmt:~$ nv show interface bond0
                          operational        applied
------------------------  -----------------  ----------
type                      bond               bond
[acl]
bond
  down-delay              0                  0
  lacp-bypass             off                off
  lacp-rate               fast               fast
  mode                                       lacp
  up-delay                0                  0
  [member]                swp49              swp49
  [member]                swp50              swp50
  mlag
    enable                                   off
bridge
  [domain]                br_default         br_default
evpn
  multihoming
    uplink                                   off
    segment
      enable                                 off
ptp
  enable                                     off
router
  adaptive-routing
    enable                                   off
  ospf
    enable                                   off
  ospf6
    enable                                   off
  pbr
    [map]
  pim
    enable                                   off
ip
  igmp
    enable                                   off
  ipv4
    forward                                  on
  ipv6
    enable                                   on
    forward                                  on
  neighbor-discovery
    enable                                   on
    [dnssl]
    home-agent
      enable                                 off
    [prefix]
    [rdnss]
    router-advertisement
      enable                                 on
      fast-retransmit                        on
      hop-limit                              64
      interval                               600000
      interval-option                        off
      lifetime                               1800
      managed-config                         off
      other-config                           off
      reachable-time                         0
      retransmit-time                        0
      router-preference                      medium
  vrrp
    enable                                   off
  vrf                                        default
  [gateway]
link
  auto-negotiate          off                on
  duplex                  full               full
  speed                   2G                 auto
  fec                                        auto
  mtu                     9216               9216
  state                   up                 up
  stats
    carrier-transitions   1
    in-bytes              522.45 KB
    in-drops              0
    in-errors             0
    in-pkts               4140
    out-bytes             559.58 KB
    out-drops             0
    out-errors            0
    out-pkts              4837
  mac                     48:b0:2d:0c:c6:b9
ifindex                   15

cumulus@leaf01:mgmt:~$ net show interface bonds
    Name   Speed   MTU  Mode     Summary
--  -----  -----  ----  -------  ----------------------------------
UP  BOND0  2G     1500  802.3ad  Bond Members: swp49(UP), swp50(UP)

cumulus@leaf01:mgmt:~$ net show interface bondmems
    Name   Speed   MTU  Mode     Summary
--  -----  -----  ----  -------  -----------------
UP  swp49  1G     1500  LACP-UP  Master: BOND0(UP)
UP  swp50  1G     1500  LACP-UP  Master: BOND0(UP)

```
```
cumulus@leaf02:mgmt:~$ nv show interface bond0
                          operational        applied
------------------------  -----------------  ----------
type                      bond               bond
[acl]
bond
  down-delay              0                  0
  lacp-bypass             off                off
  lacp-rate               fast               fast
  mode                                       lacp
  up-delay                0                  0
  [member]                swp49              swp49
  [member]                swp50              swp50
  mlag
    enable                                   off
bridge
  [domain]                br_default         br_default
evpn
  multihoming
    uplink                                   off
    segment
      enable                                 off
ptp
  enable                                     off
router
  adaptive-routing
    enable                                   off
  ospf
    enable                                   off
  ospf6
    enable                                   off
  pbr
    [map]
  pim
    enable                                   off
ip
  igmp
    enable                                   off
  ipv4
    forward                                  on
  ipv6
    enable                                   on
    forward                                  on
  neighbor-discovery
    enable                                   on
    [dnssl]
    home-agent
      enable                                 off
    [prefix]
    [rdnss]
    router-advertisement
      enable                                 on
      fast-retransmit                        on
      hop-limit                              64
      interval                               600000
      interval-option                        off
      lifetime                               1800
      managed-config                         off
      other-config                           off
      reachable-time                         0
      retransmit-time                        0
      router-preference                      medium
  vrrp
    enable                                   off
  vrf                                        default
  [gateway]
link
  auto-negotiate          off                on
  duplex                  full               full
  speed                   2G                 auto
  fec                                        auto
  mtu                     9216               9216
  state                   up                 up
  stats
    carrier-transitions   1
    in-bytes              574.45 KB
    in-drops              0
    in-errors             0
    in-pkts               4974
    out-bytes             539.08 KB
    out-drops             0
    out-errors            0
    out-pkts              4273
  mac                     48:b0:2d:10:ba:d9
ifindex                   15

cumulus@leaf02:mgmt:~$ net show interface bonds
    Name   Speed   MTU  Mode     Summary
--  -----  -----  ----  -------  ----------------------------------
UP  BOND0  2G     1500  802.3ad  Bond Members: swp49(UP), swp50(UP)

cumulus@leaf02:mgmt:~$ net show interface bondmems
    Name   Speed   MTU  Mode     Summary
--  -----  -----  ----  -------  -----------------
UP  swp49  1G     1500  LACP-UP  Master: BOND0(UP)
UP  swp50  1G     1500  LACP-UP  Master: BOND0(UP)

```

 **Important things to observe:**
- The speed of the bond is the cumulative speed of all member interfaces
- Bond member interface status and bond interface status are displayed in output


##
## Configure bridge and access ports on leaf01 and leaf02
_Bridge Configuration Details:_

| Bridge↓ / Switch→ | leaf01 |  leaf02 |
| --- | --- | --- |
| **Bridge vlans**  | 10,20 | 10,20 | 
| **Bridge members** | BOND0,swp1 | BOND0,swp2 |
| **Bridge access port** |  swp1 | swp2 |
| **Bridge access vlan** |  10 | 20 |

1. **On leaf01** : Create a bridge with vlans 10 and 20.
```
 cumulus@leaf01:mgmt:~$ nv set bridge domain br_default vlan 10,20
```

2. On leaf01: Add swp1 and BOND0 as a member to the bridge. 
 _Note: The name BOND0 is case sensitive in all places._
```
cumulus@leaf01:mgmt:~$ nv set interface swp1,bond0 bridge domain br_default
```

3. On leaf01 : Configure swp1 as an access port for vlan 10.
```
cumulus@leaf01:mgmt:~$ nv set interface swp1 bridge domain br_default access 10
```

4. On leaf01 : Commit the changes.
```
cumulus@leaf01:mgmt:~$ nv config apply
```

5. **On leaf02** : Repeat the same steps but use swp2 as the access port towards the server.
```
cumulus@leaf02:mgmt:~$ nv set bridge domain br_default vlan 10,20
cumulus@leaf02:mgmt:~$ nv set interface swp2,bond0 bridge domain br_default
cumulus@leaf02:mgmt:~$ nv set interface swp2 bridge domain br_default access 20
cumulus@leaf02:mgmt:~$ nv config apply
```
_Note: The section below is provided for easier copying and pasting._ 
```
nv set bridge domain br_default vlan 10,20
nv set interface swp2,bond0 bridge domain br_default
nv set interface swp2 bridge domain br_default access 20
nv config apply
```

##
## Verify bridge configuration on leaf01 and leaf02

1. **On leaf01** : Verify the configuration on leaf01 by checking that swp1 and BOND0 are part of the bridge.
```
cumulus@leaf01$ net show bridge vlan

Interface   VLAN    Flags
----------- ------  ---------------------
swp1        10      PVID, Egress Untagged
BOND0       1       PVID, Egress Untagged
            10
            20
```
2. **On leaf02** : Verify the same configuration on leaf02 by checking that swp2 and BOND0 are part of the bridge.
```
cumulus@leaf02$ net show bridge vlan

Interface   VLAN    Flags
----------- ------  ---------------------
swp2        20      PVID, Egress Untagged
BOND0       1         PVID, Egress Untagged
            10
            20
```
 **Important things to observe:**
- Access ports (`swpN`) are only a single line with the VLAN associated with the port and flags `PVID, Egress Untagged`
- Trunk ports are multiple lines with each VLAN associated with the trunk listed. The native vlan will show flags `PVID, Egress Untagged`

##
## Configure SVIs and VRR on leaf01 and leaf02
_VRR Configuration details:_ 

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

1. **On leaf01** : Create an SVI for vlan10.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan10 ip address 10.0.10.2/24
```

2. On leaf01 : Create an SVI for vlan 20.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan20 ip address 10.0.20.2/24
```

3. On leaf01 : Apply a VRR address and MAC for vlan10.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan10 ip vrr address 10.0.10.1/24
cumulus@leaf01:mgmt:~$ nv set interface vlan10 ip vrr mac-address 00:00:00:00:1a:10
nv set interface vlan10 ip vrr state up
```

4. On leaf01 : Apply a VRR address and MAC for vlan20.
```
cumulus@leaf01:mgmt:~$ nv set interface vlan20 ip vrr address 10.0.20.1/24
cumulus@leaf01:mgmt:~$ nv set interface vlan20 ip vrr mac-address 00:00:00:00:1a:20
nv set interface vlan20 ip vrr state up
```

5. On leaf01: Apply the changes.
```
cumulus@leaf01:mgmt:~$ nv config apply
```

6. **On leaf02** : Repeat steps 1-6.
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

_Note: The section below is provided for easier copying and pasting._
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

##
## Test VRR connectivity

1. **On server01:** Test connectivity from server01 to the VRR gateway address. The login and password on servers is `ubuntu` / `nvidia`
```
ubuntu@server01:~$ ping 10.0.10.1
PING 10.0.10.1 (10.0.10.1) 56(84) bytes of data.
64 bytes from 10.0.10.1: icmp_seq=1 ttl=64 time=0.686 ms
64 bytes from 10.0.10.1: icmp_seq=2 ttl=64 time=0.922 ms
^C
--- 10.0.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.686/0.804/0.922/0.118 ms
```

2. On server01: Test connectivity from server01 to leaf01 real IP address.
```
ubuntu@server01:~$ ping 10.0.10.2
PING 10.0.10.2 (10.0.10.2) 56(84) bytes of data.
64 bytes from 10.0.10.2: icmp_seq=1 ttl=64 time=0.887 ms
64 bytes from 10.0.10.2: icmp_seq=2 ttl=64 time=0.835 ms
^C
--- 10.0.10.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.835/0.861/0.887/0.026 ms
```

3. On server01: Test connectivity from server01 to leaf02 real IP address.
```
ubuntu@server01:~$ ping 10.0.10.3
PING 10.0.10.3 (10.0.10.3) 56(84) bytes of data.
64 bytes from 10.0.10.3: icmp_seq=1 ttl=64 time=0.528 ms
64 bytes from 10.0.10.3: icmp_seq=2 ttl=64 time=0.876 ms
^C
--- 10.0.10.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.528/0.702/0.876/0.174 ms
```

4. **On server01:** Check the IP neighbor table which is similar to the ARP table, to view each MAC address. The arp table could also be evaluated using the `arp -a` command.
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

5. **On server02**: Repeat the same connectivity tests in step 10-13 from server02 to switch IP addresses.
```
ubuntu@server02:~$ ping 10.0.20.1
PING 10.0.20.1 (10.0.20.1) 56(84) bytes of data.
64 bytes from 10.0.20.1: icmp_seq=1 ttl=64 time=1.22 ms
64 bytes from 10.0.20.1: icmp_seq=2 ttl=64 time=0.672 ms
^C
--- 10.0.20.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.672/0.949/1.226/0.277 ms
```
```
ubuntu@server02:~$ ping 10.0.20.2
PING 10.0.20.2 (10.0.20.2) 56(84) bytes of data.
64 bytes from 10.0.20.2: icmp_seq=1 ttl=64 time=0.735 ms
64 bytes from 10.0.20.2: icmp_seq=2 ttl=64 time=1.02 ms
^C
--- 10.0.20.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.735/0.882/1.029/0.147 ms
```
```
ubuntu@server02:~$ ping 10.0.20.3
PING 10.0.20.3 (10.0.20.3) 56(84) bytes of data.
64 bytes from 10.0.20.3: icmp_seq=1 ttl=64 time=0.993 ms
64 bytes from 10.0.20.3: icmp_seq=2 ttl=64 time=1.08 ms
^C
--- 10.0.20.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.993/1.040/1.087/0.047 ms
```
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

6. **On server01 and server02**: Ping to verify connectivity between the servers.
```
ubuntu@server01:~$ ping 10.0.20.102
PING 10.0.20.102 (10.0.20.102) 56(84) bytes of data.
64 bytes from 10.0.20.102: icmp_seq=1 ttl=63 time=0.790 ms
64 bytes from 10.0.20.102: icmp_seq=2 ttl=63 time=1.35 ms
^C
--- 10.0.20.102 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.790/1.070/1.351/0.282 ms
```
```
ubuntu@server02:~$  ping 10.0.10.101
PING 10.0.10.101 (10.0.10.101) 56(84) bytes of data.
64 bytes from 10.0.10.101: icmp_seq=1 ttl=63 time=1.08 ms
64 bytes from 10.0.10.101: icmp_seq=2 ttl=63 time=1.36 ms
^C
--- 10.0.10.101 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.089/1.225/1.361/0.136 ms
```
7. **On server01 and server02**: Traceroute to the other server to confirm the routed path.
```
ubuntu@server01:~$ traceroute 10.0.20.102
traceroute to 10.0.20.102 (10.0.20.102), 30 hops max, 60 byte packets
1 10.0.10.1 (10.0.10.1) 1.628 ms 1.672 ms 1.855 ms
2 10.0.20.102 (10.0.20.102) 7.947 ms 7.973 ms 8.155 ms
ubuntu@server01:~$
```
```
ubuntu@server02:~$ traceroute 10.0.10.101
traceroute to 10.0.10.101 (10.0.10.101), 30 hops max, 60 byte packets
1 10.0.20.1 (10.0.20.1) 2.813 ms 2.776 ms 3.307 ms
2 10.0.10.101 (10.0.10.101) 9.199 ms 7.836 ms 7.766 ms
ubuntu@server02:~$
```

##
## Verify MAC address tables on leaf01 and leaf02

1. **On leaf01 and leaf02:** Check to verify that the MAC addresses are learned correctly.
```
cumulus@leaf01:mgmt:~$ nv show bridge domain br_default mac-table
   age   bridge-domain  entry-type  interface   last-update  MAC address        src-vni  vlan  vni  Summary
-  ----  -------------  ----------  ----------  -----------  -----------------  -------  ----  ---  -------
0  3     br_default                 swp1        110          48:b0:2d:f1:21:f0           10
1  4856  br_default     permanent   swp1        4856         48:b0:2d:de:f4:11
2                       permanent   br_default               00:00:00:00:1a:10
3                       permanent   br_default               00:00:00:00:1a:20
4  2138  br_default     permanent   br_default  2138         44:38:39:22:01:80           20
5  93    br_default                 bond0       2017         48:b0:2d:15:93:0e           20
6  92    br_default                 bond0       92           44:38:39:22:01:8a           10
7  22    br_default                 bond0       2542         48:b0:2d:12:7f:72           1
8  22    br_default                 bond0       2554         48:b0:2d:10:ba:d9           1
9  2556  br_default     permanent   bond0       2556         48:b0:2d:0c:c6:b9

```
```
cumulus@leaf02:mgmt:~$ nv show bridge domain br_default mac-table
   age   bridge-domain  entry-type  interface   last-update  MAC address        src-vni  vlan  vni  Summary
-  ----  -------------  ----------  ----------  -----------  -----------------  -------  ----  ---  -------
0  2     br_default                 swp2        133          48:b0:2d:15:93:0e           20
1  4878  br_default     permanent   swp2        4878         48:b0:2d:3b:a0:f4
2                       permanent   br_default               00:00:00:00:1a:20
3                       permanent   br_default               00:00:00:00:1a:10
4  2144  br_default     permanent   br_default  2144         44:38:39:22:01:8a           10
5  114   br_default                 bond0       2107         48:b0:2d:f1:21:f0           10
6  115   br_default                 bond0       115          44:38:39:22:01:80           20
7  14    br_default                 bond0       2564         48:b0:2d:eb:69:d7           1
8  1     br_default                 bond0       2578         48:b0:2d:0c:c6:b9           1
9  2593  br_default     permanent   bond0       2593         48:b0:2d:10:ba:d9

```
**Important things to observe:**
-   The MAC addresses of servers should be learned on `BOND0` and `swp` interfaces of switch

**This concludes Lab 2.**

<!-- AIR:page -->

# Cumulus Linux Test Drive: Lab Guide
## Lab 3: FRR & BGP Unnumbered

**Objective:**

This lab will configure BGP unnumbered between the leaf01/leaf02 to spine01. This configuration will share the ip addresses of the loopback interfaces on each device as well as the vlan10 and vlan20 subnets on the leaf01 and leaf02 devices.

**Dependencies on other Labs:**

- None. 
- An Ansible playbook, `lab3.yml` configures all prerequisites.

**Goals:**

- Configure BGP unnumbered on spine01
- Configure BGP unnumbered on leaf01/leaf02
- Advertise loopback addresses into BGP
- Advertise SVI subnets of leafs into BGP
- Verify BGP peering
- Verify BGP route advertisements
- Verify routed connectivity and path between servers

##
## Run Lab3 setup playbook

1. **On oob-mgmt-server:** Run the playbook named `lab3.yml`. Even if you fully completed the previous lab, you must run this playbook.
```
ubuntu@oob-mgmt-server:~/Test-Drive-Automation$ ansible-playbook lab3.yml
```
##
## Apply loopback address to spine01

| Configuration↓ / Switch→ | leaf01 | leaf02 | spine01 |
| --- | --- | --- | --- |
| **Loopback IP address** | 10.255.255.1/32 | 10.255.255.2/32 | 10.255.255.101/32 |

1. **On spine01**: Configure a loopback interface
```
cumulus@spine01:mgmt:~$ nv set interface lo ip address 10.255.255.101/32
cumulus@spine01:mgmt:~$ nv config apply
```
**Note:** Leaf01 and Leaf02 loopback addresses are already configured.
##
## Configure BGP unnumbered on spine01, leaf01 and leaf02

1. **On spine01**: Configure a BGP Autonomous System (AS) number for the routing instance. Multipath-relax is typically configured to more easily accommodate load sharing via ECMP.
```
cumulus@spine01:mgmt:~$ nv set vrf default router bgp autonomous-system 65201
cumulus@spine01:mgmt:~$ nv set vrf default router bgp path-selection multipath aspath-ignore on
cumulus@spine01:mgmt:~$ nv set router bgp router-id 10.255.255.101
```
2. On spine01: Configure BGP peering on swp1 towards leaf01 and swp2 towards leaf02.
```
cumulus@spine01:mgmt:~$ nv set vrf default router bgp neighbor swp1 remote-as external
cumulus@spine01:mgmt:~$ nv set vrf default router bgp neighbor swp2 remote-as external 
```
3. On spine01: Commit the changes.
```
cumulus@spine01:mgmt:~$ nv config apply 
```
4. **On leaf01** : Repeat steps 1-3, but with small differences specific to this leaf
```
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp autonomous-system 65101
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp path-selection multipath aspath-ignore on 
cumulus@leaf01:mgmt:~$ nv set router bgp router-id 10.255.255.1
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp neighbor swp1 remote-as external
cumulus@leaf01:mgmt:~$ nv config apply 
```
For copy/paste convenience:
```
nv set vrf default router bgp autonomous-system 65101
nv set vrf default router bgp path-selection multipath aspath-ignore on
nv set router bgp router-id 10.255.255.1
nv set vrf default router bgp neighbor swp1 remote-as external
nv config apply
```
5. **On leaf02** : Repeat steps 1-3, but with small differences specific to this leaf
```
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp autonomous-system 65102
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp path-selection multipath aspath-ignore on
cumulus@leaf02:mgmt:~$ nv set router bgp router-id 10.255.255.2
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp neighbor swp1 remote-as external 
cumulus@leaf02:mgmt:~$ nv config apply
```
For copy/paste convenience:
```
nv set vrf default router bgp autonomous-system 65102
nv set vrf default router bgp path-selection multipath aspath-ignore on
nv set router bgp router-id 10.255.255.2
nv set vrf default router bgp neighbor swp1 remote-as external 
nv config apply
```
##
## Verify BGP connectivity between fabric nodes

1. **On spine01:** Verify BGP peering between spine and leafs.
```
cumulus@spine01:mgmt:~$ net show bgp summary

show bgp ipv4 unicast summary
=============================
BGP router identifier 10.255.255.101, local AS number 65201 vrf-id 0
BGP table version 0
RIB entries 0, using 0 bytes of memory
Peers 2, using 39 KiB of memory

Neighbor        V         AS MsgRcvd MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd
leaf01(swp1)    4      65101      26      27        0    0    0 00:01:09            0
leaf02(swp2)    4      65102      15      16        0    0    0 00:00:38            0

Total number of neighbors 2


show bgp ipv6 unicast summary
=============================
% No BGP neighbors found

show bgp l2vpn evpn summary
===========================
% No BGP neighbors found
```

2. **On leaf01** : Verify BGP peering between leafs and spine
```
cumulus@leaf01:mgmt:~$ net show bgp summary

show bgp ipv4 unicast summary
=============================
BGP router identifier 10.255.255.1, local AS number 65101 vrf-id 0
BGP table version 0
RIB entries 0, using 0 bytes of memory
Peers 1, using 20 KiB of memory

Neighbor        V         AS MsgRcvd MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd
spine01(swp51)  4      65201      13      15        0    0    0 00:00:35            0

Total number of neighbors 1


show bgp ipv6 unicast summary
=============================
% No BGP neighbors found

show bgp l2vpn evpn summary
===========================
% No BGP neighbors found
```
```
cumulus@leaf02:mgmt:~$ net show bgp sum

show bgp ipv4 unicast summary
=============================
BGP router identifier 10.255.255.2, local AS number 65102 vrf-id 0
BGP table version 0
RIB entries 0, using 0 bytes of memory
Peers 1, using 20 KiB of memory

Neighbor        V         AS MsgRcvd MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd
spine01(swp51)  4      65201       4       6        0    0    0 00:00:07            0

Total number of neighbors 1
```

 **Important things to observe:**
- The BGP neighbor shows the hostname of the BGP peer
- Only the peer is up, no routes are being advertised yet
- The BGP router identifier uses the loopback address
- Show commands can be a mix of "nv show" and legacy "net show". Here we are using "net show" commands.

##
## Advertise Loopback and SVI subnets into the fabric

_Routing Advertisement Configuration:_ 

| Routes↓ / Switch→ | leaf01 | leaf02 | spine01 |
| --- | --- | --- | --- |
| **Subnets to be advertised** | 10.255.255.1/32 | 10.255.255.2/32 | 10.255.255.101/32 |
| | 10.0.10.0/24 | 10.0.20.0/24 | |

1. **On spine01**: Advertise loopback address into BGP.
```
cumulus@spine01:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.101/32
cumulus@spine01:mgmt:~$ nv config apply
```
2. On leaf01 : Advertise loopback address into BGP.
```
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.1/32
```
3. On leaf01 : Advertise subnet for VLAN10.
```
cumulus@leaf01:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.0.10.0/24
```
4. On leaf01 : Commit the changes.
```
cumulus@leaf01:mgmt:~$ nv config apply
```

5. **On leaf02** : Repeat steps 2-4. Notice the different loopback IP and subnet that is advertised.
```
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.2/32
cumulus@leaf02:mgmt:~$ nv set vrf default router bgp address-family ipv4-unicast network 10.0.20.0/24
cumulus@leaf02:mgmt:~$ nv config apply
```
```
nv set vrf default router bgp address-family ipv4-unicast network 10.255.255.2/32
nv set vrf default router bgp address-family ipv4-unicast network 10.0.20.0/24
nv config apply
```

##
## Verify BGP is advertising routes

1. **On spine01**: Check that routes are being learned.
```
cumulus@spine01:mgmt:~$ net show bgp

show bgp ipv4 unicast
=====================
BGP table version is 5, local router ID is 10.255.255.101
Status codes: s suppressed, d damped, h history, * valid, > best, = multipath,
              i internal, r RIB-failure, S Stale, R Removed
Origin codes: i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
*> 10.0.10.0/24     swp1                     0             0 65101 i
*> 10.0.20.0/24     swp2                     0             0 65102 i
*> 10.255.255.1/32  swp1                     0             0 65101 i
*> 10.255.255.2/32  swp2                     0             0 65102 i
*> 10.255.255.101/32
                    0.0.0.0                  0         32768 i

Displayed  5 routes and 5 total paths


show bgp ipv6 unicast
=====================
No BGP prefixes displayed, 0 exist
cumulus@spine01:mgmt:~$ 
```

**Important things to observe:**
- AS PATH identifies where routes are originating
- NEXT HOP is the interface and not an IP address because of BGP unnumbered
- Where next hops is equal to 0.0.0.0, that route is originated locally.

##
## Verify connectivity and path between server01 and server02

1. **On Server01:** ping to Server02 (10.0.20.102)
```
ubuntu@server01:~$ ping 10.0.20.102
PING 10.0.20.102 (10.0.20.102) 56(84) bytes of data.
64 bytes from 10.0.20.102: icmp_seq=1 ttl=61 time=9.86 ms
64 bytes from 10.0.20.102: icmp_seq=2 ttl=61 time=5.96 ms
64 bytes from 10.0.20.102: icmp_seq=3 ttl=61 time=5.80 ms
^C
--- 10.0.20.102 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 5.806/7.211/9.864/1.877 ms
```

2. On Server01, traceroute to Server02 (10.0.20.102). Identify all of the hops.
```
ubuntu@server01:~$ traceroute 10.0.20.102
traceroute to 10.0.20.102 (10.0.20.102), 30 hops max, 60 byte packets
 1  10.0.10.1 (10.0.10.1)  1.280 ms  1.389 ms  1.553 ms
 2  10.255.255.101 (10.255.255.101)  4.702 ms  4.679 ms  4.789 ms
 3  10.255.255.2 (10.255.255.2)  8.438 ms  8.877 ms  9.476 ms
 4  10.0.20.102 (10.0.20.102)  9.541 ms  9.766 ms  13.549 ms
ubuntu@server01:~$ 
```

**Important things to observe:**
- With Unnumbered interfaces, traceroute (ICMP source interface) packets come from the loopback ipv4 address of the node.

**This concludes the Cumulus Linux Test Drive.**


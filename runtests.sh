#!/bin/bash

check_state(){
if [ "$?" != "0" ]; then
    echo "ERROR Could not bring up last series of devices, there was an error of some kind!"
    exit 1
fi
}

echo "Test Ansible Ping for all nodes"
ansible spine01:leaf01:leaf02:server01:server02 -m ping
check_state


### Lab 1

# initiate the lab steps that students use
cd /home/ubuntu/Test-Drive-Automation
check_state
sudo git pull
check_state
ansible-playbook start-lab.yml
check_state

### Lab 2

# initiate testing sequence for Lab 2
cd /home/ubuntu
git clone https://github.com/berkinkartal/virt-workshop-testing.git

#reset leaf01 and leaf02 to post Lab 2 setup
cd /home/ubuntu/virt-workshop-testing
ansible-playbook lab2config.yml

# Lab 2 verify

# ping VRR IP address from server01
ansible server01 -a 'ping -c 4 10.0.10.1'

# ping leaf01 vlan10 IP address from server01
ansible server01 -a 'ping -c 4 10.0.10.2'

# ping leaf02 vlan10 IP address from server01
ansible server01 -a 'ping -c 4 10.0.10.3'

# show server01 neighbor table
ansible server01 -a 'ip neighbor show'

# same as above but from leaf02 side
ansible server02 -a 'ping -c 4 10.0.20.1'
ansible server02 -a 'ping -c 4 10.0.20.2'
ansible server02 -a 'ping -c 4 10.0.20.3'
ansible server02 -a 'ip neighbor show'

# ping from server to server
ansible server01 -a 'ping -c 4 10.0.20.102'
ansible server02 -a 'ping -c 4 10.0.10.101'

# run traceroutes from each server
ansible server01 -a 'traceroute 10.0.20.102'
ansible server02 -a 'traceroute 10.0.10.101'

# show the MAC address table on each server after pings
ansible leaf01 -a 'nv show bridge domain br_default mac-table'
ansible leaf02 -a 'nv show bridge domain br_default mac-table'

### Lab 3

# reset spine01, leaf01 and leaf02 to post Lab 3 setup
ansible-playbook lab3config.yml

# show BGP summaries from spine and leaf nodes
ansible spine01 -a 'net show bgp summary'
ansible leaf01 -a 'net show bgp summary'
ansible leaf02 -a 'net show bgp summary'

# show BGP on the spine
ansible spine01 -a 'net show bgp'

# ping server02 from server01 and perform traceroute to verify routing through spine
ansible server01 -a 'ping -c 4 10.0.20.102'
ansible server01 -a 'traceroute 10.0.20.102'

# ping server01 from server02 and perform traceroute to verify routing through spine
ansible server02 -a 'ping -c 4 10.0.10.101'
ansible server02 -a 'traceroute 10.0.10.101'

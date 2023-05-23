# NVIDIA Cumulus Linux Virtual Workshop (aka Test Drive) Automation - cumulus-test-drive

This repository holds automation scripts for the NVIDIA Cumulus Linux Virtual Workshop (aka Test Drive) Lab. 

This repository is cloned by the `oob-mgmt-server-customizations.sh` script (located in the repository [here](https://gitlab.com/lsimpson762/virt-workshop-snapshot-creation)) in order to create the `Test-Drive-Automation` directory on the `oob-mgmt-server`. This is done during the CI/CD workflow to create the base snapshot and cloned simulation for testing purposes.

The attendees of the event use this automation during two steps that are documented in the lab guide. 

The first step in the lab guide is to run the ansible playbook `start-lab.yml` to set up the base configuration for the servers in the lab. The `lab3.yml` is run at the completetion of Lab 2 in order to provide a configuration that removes the interswitch links from leaf01-leaf02 so that BGP routing through the spine01 switch can be configured and tested.

The lab guide is available upon request and is provided to the attendees of the event through the marketing channel.

## Files/Folders
| File/Folder Name                    | Description                        |
| ---------------------------- | ---------------------------------- |
| lab2-configurations          | Folder for lab2 configs            |
| lab3-configurations          | Folder for lab3 configs            |
| lab3.yml                     | lab3 yml file                      |
| license.lic                  | license file                       |
| start-lab.yml                | Script for starting the lab        |
| testdrive_topology.png       | png format topology diagram        |
| testdrive_topology.pptx      | pptx format topology diagram       |
| testdrive_topology.svg       | svg format topology diagram        |

# virt-workshop-testing

## Files/Folders
| File/Folder Name                    | Description                               |
| ------------------- | --------------------------------------------------------- |
| .gitignore          | rules for git excemption                                  |
| lab2config.yml      | lab2 config                                               |
| lab3config.yml      | lab3 config                                               |
| runtests.sh         | helath-check script to run after everything is configured |
| testconfigs         | Config backups                                            |

## Configurations and a script to fully test a new NVIDIA Cumulus Linux Virtual Workshop (aka Test Drive)

This repository is meant to be cloned into the `/home/ubuntu` directory on the `oob-mgmt-server`. Once cloned, change directories into the `/home/ubuntu/virt-workshop-testing` directory and execute:

`./runtests.sh`

The script will run and send all output to the console. This output can be checked to see if all `ping`, `traceroute` and other verification steps complete properly.

## Prerequisites

1. Run the CI/CD workflow located [here](https://gitlab.com/lsimpson762/virt-workshop-snapshot-creation).
2. The CI/CD workflow will create a snapshot and a live simulation (clone) in order to test the snapshot.
3. Use the live simulation and login to its `oob-mgmt-server`.



# LICENSE
[Apache 2.0 License for this project](LICENSE)
#!/bin/bash


# Simple script to check if there is a running ssh-agent with personal SSH


# TODO(Conall): Add a conditional to only start the agent if it's not running

/usr/bin/ssh-agent >~/.ssh/personal-ssh-agent 
source ~/.ssh/personal-ssh-agent
# SSH key should be named after the hostname of the device
/usr/bin/ssh-add -K ".ssh/$(hostname -s)"


#!/bin/bash
sudo nmap -p 440-450 -sX --open --packet-trace --reason $1

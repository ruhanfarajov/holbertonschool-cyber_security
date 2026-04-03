#!/bin/bash
sudo nmap -p $2 --exclude-ports $3 -sW $1

#!/bin/bash
sudo nmap -sM -p http,https,ssh,ftp,telnet $1

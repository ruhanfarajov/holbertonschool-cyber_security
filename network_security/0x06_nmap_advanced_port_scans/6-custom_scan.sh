#!/bin/bash
sudo nmap -p $2 --scanflags FINSYNPSHRSTACKURG $1 &>custom_scan.txt

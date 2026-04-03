#!/bin/bash
sudo nmap -p "$2" --scanflags FINSYNPSHRSTACKURG "$1" -oN custom_scan.txt >/dev/null 2>&1

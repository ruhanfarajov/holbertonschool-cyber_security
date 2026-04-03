#!/bin/bash
sudo nmap -p 80,81,82,83,84,85 -sF -f -T2 $1

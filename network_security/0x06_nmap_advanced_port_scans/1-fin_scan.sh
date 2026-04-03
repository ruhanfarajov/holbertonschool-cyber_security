#!/bin/bash
sudo nmap -p 80,81,82,83,84,85 -sF -T2 $1

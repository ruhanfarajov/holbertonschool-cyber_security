#!/bin/bash
sudo nmap -sM -p 80,443,22,23,21 $1

#!/bin/bash
whois "$1" | awk -F': ' '/^(Registrant|Admin|Tech)/{v=$2; if($1~/Street/)v=v" "; if($1~/Ext$/)$1=$1":"; r=r (r==""?"":RS) $1","v} END{printf "%s", r}' > "$1.csv"

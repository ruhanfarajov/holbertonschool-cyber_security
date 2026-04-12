#!/bin/bash
awk '$1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1}' logs.txt | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}'

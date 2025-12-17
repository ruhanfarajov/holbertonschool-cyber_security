#!/usr/bin/env bash
echo $(lsb_release -a | grep -w ID) | cut -d ':' -f2 | tr -d '\t'| tr -d ' '

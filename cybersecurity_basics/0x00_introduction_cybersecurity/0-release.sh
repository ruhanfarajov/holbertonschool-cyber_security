#!/usr/bin/env bash

s=$(lsb_release -a | grep -w ID)

echo $s | cut -d ':' -f2 | tr -d '\t'| tr -d ' '

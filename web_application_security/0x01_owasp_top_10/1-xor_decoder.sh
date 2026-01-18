#!/usr/bin/env bash

input="$1"
[[ "$input" == {xor}* ]] && input="${input:5}"

echo "$input" | base64 -d | perl -pe '$_ ^= "_" x length'

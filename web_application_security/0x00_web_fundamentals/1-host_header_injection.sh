#!/usr/bin/env bash
curl -X POST $2 -d $3 -H  "Host: $1"

#!/bin/bash
password=$(tr -cd "A-Za-z0-9" </dev/urandom|head -c $1); echo $password

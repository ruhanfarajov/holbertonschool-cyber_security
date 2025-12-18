#!/bin/bash
if [[ $(sha256sum $1) == $2 ]]; then echo "test_file: OK";fi 

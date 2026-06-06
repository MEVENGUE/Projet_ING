#!/bin/bash
ssh -o StrictHostKeyChecking=no root@100.84.166.8 \
  'curl -s --user admin:SUPFile2024! "http://192.168.99.40:8404/stats;csv" | grep -v "^#" | cut -d"," -f1,2,18,19'

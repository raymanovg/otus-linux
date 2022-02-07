#! /bin/bash
for i in {1...10}; do
    sgdisk -n ${i}:0:+10M /dev/sdb
done
slblk
#!/bin/bash

mkdir -p /mnt/tmp
mount -o loop disk.img /mnt/tmp
cp -v extras/* /mnt/tmp
umount /mnt/tmp
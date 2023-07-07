#!/bin/bash
DISK=/dev/mmcblk1p2
sync
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
sudo blockdev --flushbufs $DISK
hdparm -F $DISK >/dev/null 2>&1

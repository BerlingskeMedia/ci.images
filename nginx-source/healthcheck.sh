#!/bin/bash
DISK_USAGE=$(df -h | grep  '/$' | awk '{ print $5 }' | awk '{ print substr( $0, 1, length($0)-1 ) }')
MAX_DISK_USAGE=95

if [ $DISK_USAGE -gt $MAX_DISK_USAGE ]; then
  echo "Disk usage too high ($DISK_USAGE%). Stopping container."
  exit 1;
fi

I_NODES_USAGE=$(df -i | grep  '/$' | awk '{ print $5 }' | awk '{ print substr( $0, 1, length($0)-1 ) }')
MAX_I_NODES_USAGE=98

if [ $I_NODES_USAGE -gt $MAX_I_NODES_USAGE ]; then
  echo "INODES count too high ($I_NODES_USAGE%). Stopping container."
  exit 1;
fi

exit 0;

#!/bin/bash
## backup Ganglia RRDs to slowstore
## Sergio Ballestrero Jan 2012
## Managed by Puppet ##

TMPD=/dev/shm/rrds/
D=/net/somehost/nfsexp/ganglia/$(hostname -s)
mkdir -p $D || exit 1
rsync -a /var/lib/ganglia/rrds/ $TMPD
rsync -a /var/lib/ganglia/rrds/ $TMPD
rsync -a --bwlimit=100000 $TMPD $D/rrds/

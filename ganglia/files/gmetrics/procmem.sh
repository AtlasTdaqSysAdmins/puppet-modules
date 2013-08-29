#!/bin/bash
#######################
## Managed by Puppet ##
#######################
# send mem usage stats of a specific process to Ganglia
# Sergio Ballestrero 2012

function usage() {
    echo "Usage: $0 <procname> (-p <PID>|-f <PIDfile>) [rsz|vsz]"
}
if [ $# -lt 1 ]; then 
    usage
    exit 1
fi

## TODO: operstate is undef on silly Microsoft HyperV VMs
## silence the "broken pipe" errors from cat
if ! cat /sys/class/net/*/operstate 2>/dev/null | grep -q up ; then
    logger -t "procmem" "No network interface is up, not running"
    exit 1
fi

PN="$1"; shift

case $1 in
-p) ID="-p $2"; shift;shift ;;
-f) { [ -s "$2" ] && ID="-p $(<$2)"; } ;shift;shift ;;
*) ID="-C $PN" ;;
esac
TYPE=${1:-rsz}
SZ=0
if [ "$ID" ]; then
    for V in $(ps --no-headers -o $TYPE $ID); do SZ=$[SZ+V]; done
fi
[ "$SZ" ] || SZ=0
gmetric -c /etc/ganglia/gmond.conf -n proc_${PN}_${TYPE} -t uint32 -u MB -x 600 -d 7200 -g "process" -T "Process $PN $TYPE" -v ${SZ}

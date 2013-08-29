#!/bin/bash
## Send Nagios/Icinga performance stats to Ganglia
## Sergio Ballestrero, March 2012

# Managed by Puppet #

GRP=icinga
PREF=Icinga
ST=icingastats
commandfile='/var/spool/icinga/cmd/icinga.cmd'
now=`date +%s`
HS=$(hostname -s)

## send performance data to Ganglia.
## if a warning expression is given, send also to Nagios
function check() {
    local grp=$1
    local name=$2
    local v=$3
    local u=$4
    local comment=${5:-${grp} ${name}}
    local expr_warn=${6}
    local expr_crit=${7:-false}
    if [ "$v" ] ; then
	gmetric -c /etc/ganglia/gmond.conf -n ${grp}_${name} -t float -u $u -x 600 -d 7200 -g ${grp} -T "$comment" -v ${v}
	if [ "$expr_warn" ] ; then
    	    r=0
	    eval "$expr_warn" && r=1
	    eval "$expr_crit" && r=2
	    printf "[%lu] PROCESS_SERVICE_CHECK_RESULT;$HS;loc/${grp}_${name};$r;$v $u\n" $now > $commandfile
	fi
    else
	[ "$expr_warn" ] && printf "[%lu] PROCESS_SERVICE_CHECK_RESULT;$HS;loc/${grp}_${name};3;no value\n" $now > $commandfile
    fi
}

T=$($ST -m -d PROGRUNTIMETT)
if [ $? -ne 0 ]; then
    echo "Icinga is not running"
    exit 1
fi

DT=$[now-T]
if [ "$DT" -lt 30 ]; then
    ## high latencies are expected at startup, skip nagios checks
    commandfile='/dev/null'
    exit 0
fi

T=$($ST -m -d MINACTSVCLAT)
#[ "$T" ] && gmetric -c /etc/ganglia/gmond.conf -n ${GRP}_minlat -t float -u ms -x 600 -d 7200 -g ${GRP} -T "${PREF} Min Latency" -v ${T}
check ${GRP} minlat "$T" ms "$PREF Min Latency"

T=$($ST -m -d AVGACTSVCLAT)
check ${GRP} avglat "$T" ms "$PREF Avg Latency" '[ $v -gt 1000 ]' '[ $v -gt 2000 ]'

T=$($ST -m -d MAXACTSVCLAT)
check ${GRP} maxlat "$T" ms "$PREF Max Latency" '[ $v -gt 5000 ]' '[ $v -gt 10000 ]'

T=$($ST -m -d NUMACTSVCCHECKS5M)
check ${GRP} activechk5 "$T" N "${PREF} Active Chk 5min"

T=$($ST -m -d NUMSERVICES)
check ${GRP} services "$T" N "${PREF} Services"



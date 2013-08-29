###
### Puppet module for Ganglia 
### Copyright 2012 ATLAS TDAQ SysAdmins
### LGPL v3.0
###
### Authors:
### Sergio Ballestrero

/**
 * Ganglia gmetad server, C version
 */
class ganglia::server::packages {
    $_rrdv=extlookup("rrdtool/version","present")
    $rrdv= $_rrdv ? {
    "present" => "present",
    default => $::slv ? {"5"=>"$_rrdv.el5.rf", "6"=>"$_rrdv.el6.rfx" }
    }
    package {
        "ganglia-gmetad": ensure=>present;
        "ganglia-gmetad-python": ensure=>absent, before=>Package["ganglia-gmetad"];
        "rrdtool":ensure=>$rrdv;
    }
    user{
        "ganglia":ensure=>present, uid=>480,
        #,system=>true # needs puppet 2.7 ?
    }
    mailalias{"ganglia":recipient=>"root"}
}

class ganglia::server ($clusters=["TEST","VH","SRV"]) {
    require ganglia::server::packages
    include ganglia::gmond::diskstats
    include ganglia::gmondsrv
    ganglia::gmondsrv::conf { $clusters: }

    ## Configure rrdcached
    $rrddir="/var/lib/ganglia/rrds/"
    file {
        "/etc/sysconfig/rrdcached":
        source=>"puppet:///modules/ganglia/ganglia/rrdcached.sysconfig",
        notify=>Service["rrdcached"];
        "/var/rrdtool/rrdcached/rrdcached.apache.sock":
        group=>apache;
        ["$rrddir","${rrddir}__SummaryInfo__"]:
        ensure=>directory,mode=>775,owner=>ganglia,group=>rrdcached;
    }
    # doing this via file recurse is too slow
    exec {
        "rrd_ganglia_perm":
        command=>"/bin/chgrp -R rrdcached ${rrddir};/bin/chmod -R g+w  ${rrddir}",
        refreshonly => true, subscribe => File["$rrddir"];
    }
    auth::local::group::user { "ganglia:rrdcached": }
    auth::local::group::user { "rrdcached:apache": }
    service {
        "rrdcached":
        ensure=>running, enable=>true;
    }

    # Gmetad configurations, workdirs
    ## TODO: templated or host-specific gmetad files
    file {
        "/etc/ganglia/gmetad.conf":
        source=>"puppet:///modules/ganglia/gmetad.conf^$SITE",
        owner=>root,group=>root,mode=>444,
        notify=>Service["gmetad"];
        "/etc/sysconfig/gmetad":
        content=>"# Managed by Puppet\nRRDCACHED_ADDRESS=\"unix:/var/rrdtool/rrdcached/rrdcached.sock\"\n",
        owner=>root,group=>root,mode=>444,
        notify=>Service["gmetad"];
    }
    service {
        "gmetad":
        ensure=>running, enable=>true, require=>Service["rrdcached"];
    }

    ## overall service script - not used as service, just as tool
    file {
       "/etc/init.d/ganglia":
       source=>"puppet:///modules/ganglia/ganglia/ganglia_initd",
       owner=>root,group=>root,mode=>775
    }
    ## TODO - backups in GPN
    if ( $SITE == "point1" ) {
        ## backup to slowstore
        file {
           "/usr/local/sbin/ganglia_rrd_backup.sh":
           source=>"puppet:///modules/ganglia/ganglia/ganglia_rrd_backup.sh",
           owner=>root,group=>root,mode=>544
       }
       $t=fqdn_rand(10)+20
       crond::job {
        "ganglia_rrd_backup":
            mail=>"root", # DEBUG
            comment=>"backup RRDs to slowstore",
            jobs=>"$t 07,19 * * * root /usr/local/sbin/ganglia_rrd_backup.sh",
            require=>File["/usr/local/sbin/ganglia_rrd_backup.sh"];
        }
    }
}

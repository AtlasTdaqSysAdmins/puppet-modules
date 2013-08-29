###
### Puppet module for Ganglia 
### Copyright 2012 ATLAS TDAQ SysAdmins
### LGPL v3.0
###
### Authors:
### Sergio Ballestrero

/**
 * Ganglia gmon, special server configuration
 * running multiple instances
 */
class ganglia::gmondsrv {
    ## a gentle way to make sure a client config has been defined elsewhere
    realize ganglia::gmond
    ## standard init kills all gmond instances on stop, replace with a smarter one
    file {
        "/etc/init.d/gmond":
        source=>"puppet:///modules/ganglia/gmond/gmond.initd",
        mode=>755,
        require=>Package["ganglia-gmond"],
        notify=>Service["gmond"];
    }
    # extended 'server' init script
    file {
        "/etc/init.d/gmondsrv":
        source=>"puppet:///modules/ganglia/gmond/gmondsrv.initd",
        mode=>755, 
        require=>Package["ganglia-gmond"];
    }
    service {
        "gmondsrv":
        ensure=>running, enable=>true,
        require=>File["/etc/init.d/gmondsrv"];
    }
}
define  ganglia::gmondsrv::conf () {
    file {
        "/etc/ganglia/gmond.$name.srvconf":
        source=>"puppet:///modules/ganglia/gmond/gmond.$name.srvconf^$SITE",
        notify=>Service["gmondsrv"];
    }
}

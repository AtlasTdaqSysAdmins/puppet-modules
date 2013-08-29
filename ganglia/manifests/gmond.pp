###
### Puppet module for Ganglia 
### Copyright 2012 ATLAS TDAQ SysAdmins
### LGPL v3.0
###
### Authors:
### Sergio Ballestrero

/**
 * Ganglia gmon client generic configuration
 */
class ganglia::gmond($cluster="TEST") {
    ## TODO: we don't yet have 32bit packages of Ganglia
    if $architecture == "x86_64" {
        require ganglia::gmond::packages
        class{"ganglia::gmond::conf":cluster=>$cluster}
        service {
            "gmond":
            ensure=>running, enable=>true,
            require=>Package["ganglia-gmond"];
        }
        include ganglia::gmond::diskstats
    }
}

class ganglia::gmond::packages {
    ## TODO: we don't yet have 32bit packages of Ganglia
    if $architecture == "x86_64" {
        $v=extlookup("ganglia/version")
        package { 
            ["ganglia-gmond"]: ensure=>$v;
            "ganglia":ensure=>absent, require=>Package["ganglia-gmond"];
        }
        package { ["ganglia-gmond-modules-python"]: ensure=>"$v" }
    }    
}

class ganglia::gmond::conf($cluster="TEST") {
    $location=extlookup("ganglia/location")
    $serverlist=extlookup("ganglia/servers")
    $port=extlookup("ganglia/port_$cluster")
    $recovertime=300
    file {
        "/etc/ganglia/gmond.conf":
        content=>template("ganglia/gmond.conf.erb"),
        require=>Package["ganglia-gmond"],
        notify=>Service["gmond"];
    }
}

class ganglia::gmond::diskstats {
    file {
        "/etc/ganglia/conf.d/diskstats.conf":
        source=>"puppet:///modules/ganglia/gmond_diskstats/conf.d/diskstats.conf",
        notify=>Service["gmond"],require=>Package["ganglia-gmond-modules-python"];
        "/usr/lib64/ganglia/python_modules/diskstats.py":
        source=>"puppet:///modules/ganglia/gmond_diskstats/python_modules/diskstats.py",
        notify=>Service["gmond"],require=>Package["ganglia-gmond-modules-python"];
    }
}

class ganglia::gmond::plugin::base {
    file {
    "/etc/ganglia/plugin.d": ensure=>directory,
    require=>Package["ganglia-gmond"];
    }
}

define ganglia::gmond::plugin {
    ## TODO: we don't yet have 32bit packages of Ganglia
    if $architecture == "x86_64" {
        require ganglia::gmond::plugin::base
            file {
               "/usr/lib64/ganglia/python_modules/$name.py":
               ensure=>link,
               target=>"/etc/ganglia/plugin.d/$name.py",
               require=>Package["ganglia-gmond-modules-python"];
               "/etc/ganglia/plugin.d/$name.py":
               source=>"puppet:///modules/ganglia/gmond_plugin/$name.py",
               notify=>Service["gmond"];
               "/etc/ganglia/conf.d/$name.pyconf":
               source=>"puppet:///modules/ganglia/gmond_plugin/$name.pyconf",
               notify=>Service["gmond"];
           }
   }
}

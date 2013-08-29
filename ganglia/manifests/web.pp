###
### Puppet module for Ganglia 
### Copyright 2012 ATLAS TDAQ SysAdmins
### LGPL v3.0
###
### Authors:
### Sergio Ballestrero

/**
 * New Ganglia web interface
 */
class ganglia::web {
    require ganglia::web::base
    require ganglia::server
    file {
        "/var/lib/ganglia/conf":ensure=>directory,owner=>root,group=>apache,mode=>775;
        "/var/lib/ganglia/dwoo":ensure=>directory,owner=>root,group=>apache,mode=>775,seltype=>tmp_t;
        "/var/lib/ganglia/conf/view_default.json":
        content=>'{"view_name":"default","items":[],"view_type":"standard"}',
        replace=>no,owner=>root,group=>apache,mode=>664;
        "/var/lib/ganglia/conf/default.json":
        content=>'{"included_reports": ["load_report","mem_report","cpu_report","network_report"]}',
        replace=>no,owner=>root,group=>apache,mode=>664;
        "/var/www/html/ganglia/conf.php":
        source=>"puppet:///modules/ganglia/ganglia/gweb_conf.php",
        replace=>no,owner=>root,group=>root,mode=>664;
    }
    # /var/www/html/ganglia/conf.php
    # $conf['rrdcached_socket'] = "/var/rrdtool/rrdcached/rrdcached.apache.sock";
    $conf="/var/www/html/ganglia/conf.php"
    exec {
        "gweb_rrdcache":
        command=>"/bin/sed -i -e 's|^.*rrdcached_socket.*$|\$conf[\"rrdcached_socket\"] = \"/var/rrdtool/rrdcached/rrdcached.apache.sock\";|' ${conf}",
        # Ouch the quotes, they hurt!
        unless=>"/bin/egrep '^\\$.*rrdcached.apache.sock' ${conf}"
    }
    auth::selinux::bool {"httpd_can_network_connect":}
}
class ganglia::web::base {
    include web::httpd
    user{"apache":ensure=>present, uid=>48, gid=>"apache"}
    package { 
        "gweb": ensure=>absent;
        "ganglia-web": ensure=>present;
    }
}


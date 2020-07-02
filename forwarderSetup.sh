#!/bin/bash
#
#  only doing all the sudos as cloud-init doesn't run as root, likely better to use Azure VM Extensions
#
#  $1 is the forwarder, $2 is the vnet IP range
#

sudo touch /tmp/forwarderSetup_start
echo "$@" > /tmp/forwarderSetup_params

#  Install Bind9
#  https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-14-04
sudo apt-get update -y
sudo apt-get install bind9 -y

# configure Bind9 for forwarding
sudo cat > named.conf.options << EndOFNamedConfOptions
acl goodclients {
    $2;
    localhost;
    localnets;
};

options {
        directory "/var/cache/bind";

        recursion yes;

        allow-query { goodclients; };

        forwarders {
            $1;
        };
        
	//forward only;

	dnssec-enable yes;
        dnssec-validation yes;

        auth-nxdomain no;    # conform to RFC1035
        listen-on { any; };
};
EndOFNamedConfOptions

sudo cp named.conf.options /etc/bind

# configure Bind9 for forwarding
sudo cat > named.conf.default-zones << EndOFNamedConfDefaultZones
// Forward Only!  Do not use root hints.
//zone "." {
//	type hint;
//	file "/etc/bind/db.root";
//};

// be authoritative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
	type master;
	file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
	type master;
	file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
	type master;
	file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
	type master;
	file "/etc/bind/db.255";
};

zone "svc.local" {
        type forward;
        forwarders {168.63.129.16;};
};
EndOFNamedConfDefaultZones

sudo cp named.conf.default-zones /etc/bind

azurednssuffix=$(hostname -f | cut -d "." -f2-)


# configure Bind9 for forwarding
sudo cat > named.conf.local << EndOFNamedConfLocal
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "dfs.core.windows.net" {
        type forward;
        forwarders {168.63.129.16;};
};

zone "database.windows.net" {
        type forward;
        forwarders {168.63.129.16;};
};

zone "$azurednssuffix" {
        type forward;
        forwarders {168.63.129.16;};
};
EndOFNamedConfLocal

sudo cp named.conf.local /etc/bind

sudo service bind9 restart

sudo touch /tmp/forwarderSetup_end

#!/bin/bash
sudo -i

#Variables
$NSIP = "Insert nameserver IP here"
$NS2IP = "Insert NS2 IP here"
$DOMAINNAME = "Insert domain name here"
$FORWARDERS @"
        0.0.0.0;
        0.0.0.0;
"@
$ADDON1 = "Insert additional req'd DNS records, leave blank otherwise"
$ADDON2 = "Insert additional req'd DNS records, leave blank otherwise"

apt-get update -y
apt-get upgrade -y

apt-get install bind9 bind9utils bind9-doc -y

#Configures Cacheing nameserver
sudo ufw allow Bind9

cat > /etc/bind/named.conf.options <<EOF
options {
        directory "/var/cache/bind";
		
		forwarders {
$FORWARDERS
        };
		
		dnssec-validation auto;
		
		listen-on { any; };
		allow-query { any; };
};
EOF

named-checkconf
systemctl restart bind9

#Configures primary nameserver
cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAINNAME}" {
type master;
file "/etc/bind/db.{$DOMAINNAME}";
allow-transfer { ${NS2IP}; };
also-notify { ${NS2IP}; };
};
EOF

systemctl reload bind9

cp /etc/bind/db.local /etc/bind/db.${DOMAINNAME}

cat >/etc/bind/db.${DOMAINNAME} <<EOF
;
;BIND data file for local loopback interface
;
$TTL    604800
@       IN      SOA     ns.${DOMAINNAME}. admin.${DOMAINNAME}. (
                              3         ; Serial
					     604800         ; Refresh
						  86400         ; Retry
						2419200         ; Expire
						 604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.${DOMAINNAME}.
@       IN      A       127.0.0.1
ns      IN      A       ${NSIP}
ns2     IN      A       ${NS2IP}
EOF

echo "${ADDON1}" >> /etc/bind/db.${DOMAINNAME}
echo "${ADDON2}" >> /etc/bind/db.${DOMAINNAME}

sudo rndc reload

echo "Done."
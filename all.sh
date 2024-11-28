#!/bin/bash
if [ "HOSTNAME" = ISP ]; then
mkdir /etc/net/ifaces/ens18
cat <<EOF > /etc/net/ifaces/ens18/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/ens19
mkdir /etc/net/ifaces/ens20
mkdir /etc/net/ifaces/ens21
 
cp /etc/net/ifaces/ens18/options /etc/net/ifaces/ens19/options
sed -i '5a\IPV6_CONFIG=yes' /etc/net/ifaces/ens19/options
cp /etc/net/ifaces/ens19/options /etc/net/ifaces/ens20/options
cp /etc/net/ifaces/ens19/options /etc/net/ifaces/ens21/options
 
echo 10.0.54.20/24 > /etc/net/ifaces/ens18/ipv4address
echo "default via 10.0.54.1" > /etc/net/ifaces/ens18/ipv4route
echo 11.11.11.1/24 > /etc/net/ifaces/ens19/ipv4address
echo 22.22.22.1/24 > /etc/net/ifaces/ens20/ipv4address
echo 33.33.33.1/24 > /etc/net/ifaces/ens21/ipv4address
echo 2001:11::1/64 > /etc/net/ifaces/ens19/ipv6address
echo 2001:22::1/64 > /etc/net/ifaces/ens20/ipv6address
echo 2001:33::1/64 > /etc/net/ifaces/ens21/ipv6address
 
sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update && apt-get install -y firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --add-interface=ens18
firewall-cmd --permanent --zone=trusted --add-interface=ens19
firewall-cmd --permanent --zone=trusted --add-interface=ens20
firewall-cmd --permanent --zone=trusted --add-interface=ens21
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload
systemctl restart firewalld
systemctl restart network
 
apt-get install  -y iperf3
systemctl enable --now iperf3
else
echo "this is not ISP" 
fi
if [ "$HOSTNAME" = HQ-R ]; then 
rm -rf /etc/net/ifaces/ens18
 
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
mkdir /etc/net/ifaces/ens18
cat <<EOF > /etc/net/ifaces/ens18/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
IPV6_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/ens19
mkdir /etc/net/ifaces/ens20
 
cp /etc/net/ifaces/ens18/options /etc/net/ifaces/ens19/options
cp /etc/net/ifaces/ens18/options /etc/net/ifaces/ens20/options
 
echo 11.11.11.11/24 > /etc/net/ifaces/ens18/ipv4address
echo 192.168.100.62/26 > /etc/net/ifaces/ens19/ipv4address
echo 44.44.44.44/24 > /etc/net/ifaces/ens20/ipv4address
echo 2001:11::11/64 > /etc/net/ifaces/ens18/ipv6address
echo 2000:100::3f/124 > /etc/net/ifaces/ens19/ipv6address
echo 2001:44::44/64 > /etc/net/ifaces/ens20/ipv6address
echo default via 11.11.11.1 > /etc/net/ifaces/ens18/ipv4route
echo default via 2001:11::1 > /etc/net/ifaces/ens18/ipv6route  
 
sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
systemctl restart network
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update && apt-get install -y firewalld
apt-get update && apt-get install -y frr
apt-get update && apt-get install -y dhcp-server

systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --add-interface=ens18
firewall-cmd --permanent --zone=trusted --add-interface=ens19
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload
systemctl restart firewalld
 
mkdir /etc/net/ifaces/tun1
cat <<EOF > /etc/net/ifaces/tun1/options
TYPE=iptun
TUNTYPE=gre
TUNLOCAL=11.11.11.11
TUNREMOTE=22.22.22.22
TUNOPTIONS='ttl 64'
HOST=ens18
EOF
 
echo 172.16.100.1/24 > /etc/net/ifaces/tun1/ipv4address
echo 2001:100::1/64 > /etc/net/ifaces/tun1/ipv6address
 
systemctl restart network
modprobe gre

firewall-cmd --permanent --zone=trusted --add-interface=tun1
firewall-cmd --reload
systemctl restart firewalld

resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
sed -i 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons
systemctl enable --now frr
 
cat <<EOF >> /etc/frr/frr.conf
!
interface tun1
 ipv6 ospf6 area 0
 no ip ospf passive
exit
!
interface ens19
 ipv6 ospf6 area 0
exit
!
router ospf
 passive-interface default
 network 172.16.100.0/24 area 0
 network 192.168.100.0/26 area 0
exit
!
router ospf6
 ospf6 router-id 11.11.11.11
exit
!
EOF
systemctl restart frr
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf

sed -i 's/DHCPDARGS=/DHCPDARGS=ens19/g' /etc/sysconfig/dhcpd
sed -i 's/DHCPDARGS=/DHCPDARGS=ens19/g' /etc/sysconfig/dhcpd6
 
cp /etc/dhcp/dhcpd.conf.example /etc/dhcp/dhcpd.conf
 
cat <<EOF > /etc/dhcp/dhcpd.conf
# dhcpd.conf
 
default-lease-time 6000;
max-lease-time 72000;
 
authoritative;
 
subnet 192.168.100.0 netmask 255.255.255.192 {
  range 192.168.100.5 192.168.100.61;
  option routers 192.168.100.62;
}
 
#host hq-srv {
# hardware ethernet "mac-address hq-srv";
#  fixed-address 192.168.100.1;
#}
EOF
systemctl enable --now dhcpd
 
cp /etc/dhcp/dhcpd6.conf.sample /etc/dhcp/dhcpd6.conf
 
cat <<EOF > /etc/dhcp/dhcpd6.conf
# Server configuration file example for DHCPv6
default-lease-time 2592000;
preferred-lifetime 604000;
option dhcp-renewal-time 36000;
option dhcp-rebinding-time 72000;
 
allow leasequery;
 
option dhcp6.preference 255;
 
option dhcp6.info-refresh-time 21600;
 
subnet6 2000:100::/122 {
	range6 2000:100::2 2000:100::3f;
}
 
#host hq-srv {
#	host-identifier option
#		dhcp6.client-id <DUID>;
#	fixed-address6 2000:100::1;
#	fixed-prefix6 2000:100::/122;
#}
EOF
systemctl enable --now dhcpd6
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
apt-get update && apt-get install -y radvd
 
echo net.ipv6.conf.ens19.accept_ra = 2 >> /etc/net/sysctl.conf 
systemcrtl restart network
 
cat <<EOF  > /etc/radvd.conf
# NOTE: there is no such thing as a working "by-default" configuration file.
#       At least the prefix needs to be specified.  Please consult the radvd.conf(5)
#       man page and/or /usr/share/doc/radvd-*/radvd.conf.example for help.
#
#
interface ens19
{
	AdvSendAdvert on;
	AdvManagedFlag on;
	AdvOtherConfigFlag on;
	prefix 2000:100::/122
	{
		AdvOnLink on;
		AdvAutonomous on;
		AdvRouterAddr on;
	};
};
EOF
 
systemctl restart dhcpd6
systemctl enable --now radvd
 
useradd admin -m -c "Admin" -U
echo -e "P@ssw0rd\nP@ssw0rd" | passwd admin

 
useradd network-admin -m -c "Network admin" -U
echo -e "P@ssw0rd\nP@ssw0rd" | passwd network-admin
 
apt-get install -y iperf3
systemctl enable --now iperf3
 
iperf3 -c 11.11.11.1 --get-server-output > /root/iperf3_logfile.txt
 
chmod +x /root/momo/backup.sh
sh /root/momo/backup.sh
cp /root/momo/backup.sh /root/
 
#firewall-cmd --permanent --zone=public --add-forward-port=port=22:proto=tcp:toport=2222:toaddr=192.168.100.1
#firewall-cmd --permanent --zone=public --add-forward-port=port=22:proto=tcp:toport=2222:toaddr=2000:100::1
#firewall-cmd --reload

timedatectl set-timezone Europe/Moscow
apt-get update && apt-get install -y chrony

cat <<EOF > /etc/chrony.conf
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (https://www.pool.ntp.org/join.html).
# pool pool.ntp.org iburst

server 127.0.0.1 iburst prefer
hwtimestamp *
local stratum 5
allow 0/0
allow ::/0

#allow 11.11.11.0/24
#allow 22.22.22.0/24
#allow 33.33.33.0/24
#allow 44.44.44.0/24
#allow 192.168.100.0/26
#allow 192.168.200.0/28
#allow 172.16.100.0/24
#allow 2001:11::/64
#allow 2001:22::/64
#allow 2001:33::/64
#allow 2001:44::/64
#allow 2000:100::/122
#allow 2000:200::/124
#allow 2001:100::/64
EOF
systemctl enable --now chronyd
else 
echo "This is not HQ-R"
fi
if [ "HOSTNAME" = HQ-SRV ]; then
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

apt-get update && apt-get install bind bind-utils chrony -y

cat <<EOF > /etc/bind/options.conf
options {
	version "unknown";
	directory "/etc/bind/zone";
	dump-file "/var/run/named_dump.db";
	statistics-file "/var/run/named.stats";
	recursing-file "/var/run/recursing";

	// disables the use of a PID file
	pid-file none;

	/*
	 * Oftenly used directives are listed below.
	 */

	listen-on { any; };
	listen-on-v6 { any; };

	/*
	 * If the forward directive is set to "only", the server will only
	 * query the forwarders.
	 */
	forward only;
	forwarders { 77.88.8.8; };
	//include "/etc/bind/resolvconf-options.conf";

	/*
	 * Specifies which hosts are allowed to ask ordinary questions.
	 */
	allow-query { any; };

	/*
	 * This lets "allow-query" be used to specify the default zone access
	 * level rather than having to have every zone override the global
	 * value. "allow-query-cache" can be set at both the options and view
	 * levels.  If "allow-query-cache" is not set then "allow-recursion" is
	 * used if set, otherwise "allow-query" is used if set unless
	 * "recursion no;" is set in which case "none;" is used, otherwise the
	 * default (localhost; localnets;) is used.
	 */
	//allow-query-cache { localnets; };

	/*
	 * Specifies which hosts are allowed to make recursive queries
	 * through this server.  If not specified, the default is to allow
	 * recursive queries from all hosts.  Note that disallowing recursive
	 * queries for a host does not prevent the host from retrieving data
	 * that is already in the server's cache.
	 */
	//allow-recursion { localnets; };

	/*
	 * Sets the maximum time for which the server will cache ordinary
	 * (positive) answers.  The default is one week (7 days).
	 */
	//max-cache-ttl 86400;

	/*
	 * The server will scan the network interface list every
	 * interface-interval minutes.  The default is 60 minutes.
	 * If set to 0, interface scanning will only occur when the
	 * configuration file is loaded.  After the scan, listeners will
	 * be started on any new interfaces (provided they are allowed by
	 * the listen-on configuration).  Listeners on interfaces that
	 * have gone away will be cleaned up.
	 */
	//interface-interval 0;
};

logging {
	// The default_debug channel has the special property that it only
	// produces output when the server’s debug level is non-zero. It
	// normally writes to a file called named.run in the server’s working
	// directory.

	// For security reasons, when the -u command-line option is used, the
	// named.run file is created only after named has changed to the new
	// UID, and any debug output generated while named is starting - and
	// still running as root - is discarded. To capture this output, run
	// the server with the -L option to specify a default logfile, or the
	// -g option to log to standard error which can be redirected to a
	// file.

	// channel default_debug {
	// 	file "/var/log/named/named.run" versions 10 size 20m;
	// 	print-time yes;
	// 	print-category yes;
	// 	print-severity yes;
	// 	severity dynamic;
	// };
};
EOF

systemctl enable --now bind
echo name_servers=127.0.0.1 >> /etc/resolvconf.conf
resolvconf -u
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

cat <<EOF > /etc/bind/local.conf
zone "hq.work" {
        type master;
        file "hq.db";    
};

zone "branch.work" {
        type master;
        file "branch.db";    
};

zone "100.168.192.in-addr.arpa" {
        type master;
        file "100.db";    
};

zone "200.168.192.in-addr.arpa" {
        type master;
        file "200.db";    
};

EOF

cp /etc/bind/zone/{localdomain,hq.db}
cp /etc/bind/zone/{localdomain,branch.db}
cp /etc/bind/zone/{127.in-addr.arpa,100.db}
cp /etc/bind/zone/{127.in-addr.arpa,200.db}
chown root:named /etc/bind/zone/{hq,branch,100,200}.db

rm -rf /etc/bind/zone/hq.db

cat <<EOF > /etc/bind/zone/hq.db
tib	1D
@	IN	SOA	hq.work root.hq.work. (
				2024021400	; serial
				12H		; refresh
				1H		; retry
				1W		; expire
				1H		; ncache
			)
	IN	NS	hq.work.
	IN	A	127.0.0.0
hq-r	IN	A	192.168.100.62
hq-srv	IN	A	192.168.100.5
 

EOF

rm -rf /etc/bind/zone/branch.db


cat <<EOF > /etc/bind/zone/branch.db

tib	1D
@	IN	SOA	branch.work root.branch.work. (
				2024021400	; serial
				12H		; refresh
				1H		; retry
				1W		; expire
				1H		; ncache
			)
	IN	NS	branch.work.
	IN	A	127.0.0.0
br-r	IN	A	192.168.200.14
br-srv	IN	A	192.168.200.1
EOF

rm -rf /etc/bind/zone/100.db

cat <<EOF > /etc/bind/zone/100.db

tib	1D
@	IN	SOA	hq.work root.hq.work. (
				2024021400	; serial
				12H		; refresh
				1H		; retry
				1W		; expire
				1H		; ncache
			)
	IN	NS	hq.work.
62	IN	PTR	hq-r.hq.work.
5	IN	PTR	hq-srv.hq.work.
EOF

rm -rf /etc/bind/zone/200.db

cat <<EOF > /etc/bind/zone/200.db

tib	1D
@	IN	SOA	branch.work. root.branch.work. (
				2024021400	; serial
				12H		; refresh
				1H		; retry
				1W		; expire
				1H		; ncache
			)
	IN	NS	branch.work.
14	IN	PTR	br-r.branch.work.
 
EOF


sed -i 's/tib/$TTL/g' /etc/bind/zone/hq.db
sed -i 's/tib/$TTL/g' /etc/bind/zone/branch.db
sed -i 's/tib/$TTL/g' /etc/bind/zone/100.db
sed -i 's/tib/$TTL/g' /etc/bind/zone/200.db

named-checkconf -z

systemctl restart bind

timedatectl set-timezone Europe/Moscow

cat <<EOF > /etc/chrony.conf
# Use piblic servers from the pool.ntp.org project.
# Please consider joining the pool (https://www.pool.ntp.org/join.html).
# pool pool.ntp.org iburst

server 192.168.100.62 iburst prefer
server 2000:100::3f iburst
EOF

systemctl enable --now chronyd

apt-get install -y task-samba-dc

control bind-chroot disabled

grep -q 'bind-dns' /etc/bind/named.conf || echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf

sed -i '8a\	tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";' /etc/bind/options.conf
sed -i '9a\	minimal-responses yes;' /etc/bind/options.conf
sed -i '91a\	category lame-servers {null;};' /etc/bind/options.conf
systemctl stop bind

sed -i 's/HOSTNAME=ISP/HOSTNAME=hq-srv.demo.first/g' /etc/sysconfig/network

hostnamectl set-hostname hq-srv.demo.first
domainname demo.first

rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol

samba-tool domain provision --realm=demo.first --domain=demo --adminpass='P@ssw0rd' --dns-backend=BIND9_DLZ --server-role=dc --use-rfc2307

systemctl enable --now samba
systemctl enable --now bind
rm -rf /etc/krb5.conf
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

samba-tool domain info 127.0.0.1
else 
echo "This is not HQ-SRV"
fi
if [ "$HOSTNAME" = BR-R ]; then
rm -rf /etc/net/ifaces/ens18
 
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
mkdir /etc/net/ifaces/ens18
cat <<EOF > /etc/net/ifaces/ens18/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
IPV6_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/ens18
mkdir /etc/net/ifaces/ens19
 
cp /etc/net/ifaces/ens18/options /etc/net/ifaces/ens19/options
 
echo 22.22.22.22/24 > /etc/net/ifaces/ens18/ipv4address
echo 192.168.200.14/28 > /etc/net/ifaces/ens19/ipv4address
echo 2001:22::22/64 > /etc/net/ifaces/ens18/ipv6address
echo 2000:200::f/122 > /etc/net/ifaces/ens19/ipv6address
echo default via 22.22.22.1 > /etc/net/ifaces/ens18/ipv4route
echo default via 2001:22::1 > /etc/net/ifaces/ens18/ipv6route  
 
sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
systemctl restart network
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update && apt-get install -y firewalld
apt-get update && apt-get install -y frr

systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --add-interface=ens18
firewall-cmd --permanent --zone=trusted --add-interface=ens19
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload
systemctl restart firewalld
 
mkdir /etc/net/ifaces/tun1
cat <<EOF > /etc/net/ifaces/tun1/options
TYPE=iptun
TUNTYPE=gre
TUNLOCAL=22.22.22.22
TUNREMOTE=11.11.11.11
TUNOPTIONS='ttl 64'
HOST=ens18
EOF
 
echo 172.16.100.2/24 > /etc/net/ifaces/tun1/ipv4address
echo 2001:100::2/64 > /etc/net/ifaces/tun1/ipv6address
 
systemctl restart network
modprobe gre

firewall-cmd --permanent --zone=trusted --add-interface=tun1
firewall-cmd --reload
systemctl restart firewalld


resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf

 
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
sed -i 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons
systemctl enable --now frr
 
cat <<EOF >> /etc/frr/frr.conf
!
interface tun1
 ipv6 ospf6 area 0
 no ip ospf passive
exit
!
interface ens19
 ipv6 ospf6 area 0
exit
!
router ospf
 passive-interface default
 network 172.16.100.0/24 area 0
 network 192.168.200.0/28 area 0
exit
!
router ospf6
 ospf6 router-id 22.22.22.22
exit
!
EOF
systemctl restart frr

firewall-cmd --permanent --zone=public --add-interface=tun1
firewall-cmd --reload

resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
 
useradd branch-admin -m -c "Branch admin" -U
echo -e "P@ssw0rd\nP@ssw0rd" | passwd branch-admin

useradd network-admin -m -c "Network admin" -U
echo -e "P@ssw0rd\nP@ssw0rd" | passwd network-admin

chmod +x /root/momo/backup.sh
sh /root/momo/backup.sh

timedatectl set-timezone Europe/Moscow
apt-get install -y chrony
cat <<EOF > /etc/chrony.conf
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (https://www.pool.ntp.org/join.html).
# pool pool.ntp.org iburst

server 192.168.100.62 iburst prefer
server 2000:100::3f iburst

systemctl enable --now chronyd
else
echo "This is not BR-R"
fi
if [ "$HOSTNAME" = BR-SRV ]; then
rm -rf /etc/net/ifaces/ens18
 
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
mkdir /etc/net/ifaces/ens18
cat <<EOF > /etc/net/ifaces/ens18/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
IPV6_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/ens18
 

echo 192.168.200.1/28 > /etc/net/ifaces/ens18/ipv4address
echo 2000:200::1/124 > /etc/net/ifaces/ens18/ipv6address
echo default via 192.168.200.14 > /etc/net/ifaces/ens18/ipv4route
echo default via 2000:200::f > /etc/net/ifaces/ens18/ipv6route  
 
sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
systemctl restart network
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update

useradd branch-admin -m -c "Branch admin" -U
echo -e "P@ssw0rd\nP@ssw0rd" | passwd branch-admin

useradd network-admin -m -c "Network admin" -U
echo -e "P@ssw0rd\nP@ssw0rd" | passwd network-admin
else
echo "This is not BR-SRV"
fi
if [ "$HOSTNAME" = CLI ]; then
rm -rf /etc/net/ifaces/ens19
 
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
mkdir /etc/net/ifaces/ens19
cat <<EOF > /etc/net/ifaces/ens19/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
IPV6_CONFIG=yes
EOF
 
sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' /etc/net/ifaces/default/options
mkdir /etc/net/ifaces/ens19
mkdir /etc/net/ifaces/ens20
cp /etc/net/ifaces/ens19/options /etc/net/ifaces/ens20/options

echo 33.33.33.33/24 > /etc/net/ifaces/ens19/ipv4address
echo 44.44.44.1/24 > /etc/net/ifaces/ens20/ipv4address
echo 2001:33::33/64 > /etc/net/ifaces/ens19/ipv6address
echo 2001:44::1/64 > /etc/net/ifaces/ens20/ipv6address
echo default via 33.33.33.1 > /etc/net/ifaces/ens19/ipv4route
echo default via 2001:33::1 > /etc/net/ifaces/ens19/ipv6route  
echo default via 44.44.44.1 > /etc/net/ifaces/ens20/ipv4route
echo default via 2001:44::1 > /etc/net/ifaces/ens20/ipv6route

sed -i '10a\net.ipv6.conf.all.forwarding = 1' /etc/net/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf
 
systemctl restart network
 
resolvconf -u
echo "nameserver 77.88.8.8" >> /etc/resolv.conf
apt-get update

useradd admin -m -c "Admin" -U
echo -e "P@ssw0rd\nP@ssw0rd" | passwd admin
else 
echo "This in not CLI"
fi

#!/bin/bash
 
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

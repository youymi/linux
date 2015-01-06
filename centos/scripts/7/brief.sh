#!/bin/bash

cdir=`dirname $0`
echo $cdir

username=`whoami`
if [ "$username" != "root" ];then
  echo "You must run this script as root user !"
  exit 1
fi

#set the file limit
echo "ulimit -SHn 102400" >> /etc/rc.local
cat > /etc/security/limits.conf << EOF
*           soft   nproc        65535
*	        hard   nproc        65535
*           soft   nofile       65535
*           hard   nofile       65535
EOF
cat > /etc/security/limits.d/90-nproc.conf << EOF
*          soft    nproc     65535
root       soft    nproc     unlimited
EOF

echo "session    required  /lib64/security/pam_limits.so" >> /etc/pam.d/login

#disable selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

##修改下面这行
#echo 0 > /selinux/enforce
setenforce 0

#set sshd
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
service sshd restart

#disbale iptables
#service iptables stop
#chkconfig iptables off
#service ip6tables stop
#chkconfig ip6tables off
service firewall stop
chkconfig firewall off
echo "NETWORKING_IPV6=off" >> /etc/sysconfig/network

#turn off other stuff
#service cups stop
#chkconfig cups off

#tune kernel parametres
cat >> /etc/sysctl.conf << EOF

net.ipv4.tcp_fin_timeout = 3
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 1024    65000

net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
EOF
/sbin/sysctl -p

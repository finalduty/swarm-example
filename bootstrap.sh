#!/bin/bash
set -e

## Start that pesky interface that won't do it on it's own.
ifup eth1

## Set SELinux to permissive to allow nginx to proxy
if [ -f /etc/selinux/config ]; then
    sed -i 's/^SELINUX=.*$/SELINUX=permissive/' /etc/selinux/config
    setenforce permissive
fi

## Inject dns records
cat << EOF >> /etc/hosts

10.0.0.11 proxy1
10.0.0.21 node1
10.0.0.22 node2
10.0.0.23 node3
EOF

## Update and do initial setup of base OS
yum install -y centos-release epel-release yum-cron
cd /etc/yum.repos.d && curl -LO https://raw.github.com/finalduty/centos-base/master/CentOS-Base.repo; cd
cd /etc/yum.repos.d && curl -LO https://raw.github.com/finalduty/centos-base/master/epel.repo; cd
mkdir -p /etc/pki/rpm-gpg/

yum update -y
yum install -y vim-enhanced psmisc net-tools bind-utils tcpflow git jq screen

## Add custom rc files
cd /root && for i in .bashrc .vimrc .toprc; do 
    curl -LO https://raw.github.com/finalduty/configs/master/$i
done

## Add automatic sudo rule to vagrant user
echo "sudo -i" >> /home/vagrant/.bashrc


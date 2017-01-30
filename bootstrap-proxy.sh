#!/bin/bash
set -e

bash /vagrant/bootstrap.sh

## Set up required repos
cp /vagrant/nginx.repo /etc/yum.repos.d/

## Install Nginx
yum install -y nginx nfs-utils

## Set up NFS
cat << EOF > /etc/exports
/srv/            10.0.0.0/27(rw,fsid=0,no_root_squash,no_subtree_check)
EOF
systemctl enable nfs-server --now

## Set up password so teamcity-agent can scp files to the NFS server
## DO NOT EVER DO THIS IN PRODUCTION ##
echo "$1$boTA3jXY$MJ5DiuTT0.XKL5Rrk3C/o." | passwd --stdin root

## Set up Consul-Template
#cd /tmp/ && curl -L https://releases.hashicorp.com/consul-template/0.18.0/consul-template_0.18.0_linux_amd64.tgz -O
#tar xzvf /tmp/consul-template*
#mv -v /tmp/consul-template /usr/local/sbin/
#mkdir /etc/consul-template

## Copy nginx site config and start
rm /etc/nginx/conf.d/default.conf
cp /vagrant/sites/* /etc/nginx/conf.d/
cd /etc/nginx/conf.d && ln -sr example-blue.option /etc/nginx/conf.d/example-active.conf; cd
cd /etc/nginx/conf.d && ln -sr portainer.option /etc/nginx/conf.d/portainer-active.conf; cd
cd /etc/nginx/conf.d && ln -sr teamcity.option /etc/nginx/conf.d/teamcity-active.conf; cd
cd /etc/nginx/conf.d && ln -sr consul.option /etc/nginx/conf.d/consul-active.conf; cd
cd /var/log/nginx && mkdir -pv blue.example.local green.example.local test.example.local example.local portainer.local teamcity.local consul.local; cd 

systemctl enable nginx --now


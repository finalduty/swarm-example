#!/bin/bash
set -e

bash /vagrant/bootstrap.sh

## VARIABLES
FULLSETUP=False

## Mount NFS
cat << EOF >> /etc/fstab

10.0.0.11:/   /nfs/  nfs4     defaults     0 0
EOF
mkdir -p /nfs/
mount -av

## Set up required repos
cp /vagrant/docker.repo /etc/yum.repos.d/

## Install docker
yum install -y docker-engine

## Start Docker
mkdir -p /{nfs,srv}/docker/
cp /vagrant/docker.service /etc/systemd/system/
systemctl enable docker
systemctl start docker

if [ False == True ]; then
    docker pull gliderlabs/registrator
    docker pull portainer/portainer; \
    docker pull instavote/vote; \
    docker pull instavote/vote:movies; \
    docker pull sjoerdmulder/teamcity; \
    docker pull alpine
fi

## Set up Consul
mkdir /etc/consul /var/lib/consul
cp /vagrant/consul /usr/local/sbin
cp /vagrant/consul.service /etc/systemd/system
cp /vagrant/consul.json /etc/consul/
sed -i "s|<IPADDR>|`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-eth1 | sed 's/^.*=//'`|" /etc/consul/consul.json

systemctl daemon-reload
systemctl enable consul
## We don't start consul here, so it's easier to set up the cluster. It's done lower down now ##
#systemctl start consul

## Set up Registrator
## Not using Registrator for service discovery at the moment ##
#cp /vagrant/registrator.service /etc/systemd/system
#systemctl daemon-reload
#systemctl enable registrator
#systemctl start registrator

case `hostname` in
    node1 )
        ## Lets set up the swarm
        docker swarm init --advertise-addr=10.0.0.21
    
        mkdir -p /nfs/docker/portainer/data
        docker network create --driver overlay portainer
        docker service create --name portainer --replicas 1 \
            --mount type=bind,src=/nfs/docker/portainer/data/,dst=/data/ \
            --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
            --network portainer \
            -p 9000:9000 \
            portainer/portainer     -H unix:///var/run/docker.sock

        mkdir -p /nfs/docker/teamcity-server/{data,logs}
        docker network create --driver overlay teamcity
        docker service create --name teamcity-server --replicas 1 -p 8111:8111 \
            --mount type=bind,src=/nfs/docker/teamcity-server/data/,dst=/data/teamcity_server/datadir \
            --mount type=bind,src=/nfs/docker/teamcity-server/logs/,dst=/opt/teamcity/logs \
            jetbrains/teamcity-server

        mkdir -p /srv/docker/teamcity-agent/conf
        docker service create --name teamcity-agent --mode global \
            -e SERVER_URL="10.0.0.11"  \
            --mount type=bind,src=/srv/docker/teamcity-agent/conf/,dst=/data/teamcity_agent/conf \
            --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock  \
            jetbrains/teamcity-agent

        docker network create --driver overlay vote-blue
        docker service create --name vote-blue   -p 8080:80  --network vote-blue  --replicas 3 instavote/vote
            
        docker network create --driver overlay vote-green
        docker service create --name vote-green  -p 8081:80  --network vote-green  --replicas 3 instavote/vote:movies
    
        ## Also lets set up Consul
        consul agent -bootstrap-expect=1 -config-dir=/etc/consul
        ;;
    
    node2 )

elif [ `hostname` == 'node2' -o `hostname` == 'node3' ]; then
    systemctl start consul
    consul join 10.0.0.21
    
fi

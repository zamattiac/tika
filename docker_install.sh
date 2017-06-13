#!/bin/bash
# Installs Docker CE 17.03.1 for CentOS
sudo yum remove docker \
                  docker-common \
                  container-selinux \
                  docker-selinux \
                  docker-engine
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum -y install docker-ce-17.03.1.ce-1.el7.centos
# Start the daemon
sudo service docker start
echo -e "\033[0;31mRan 'service docker start' for you to start Docker daemon \033[0m"
# Enable non-sudo Docker usage
sudo groupadd docker
sudo gpasswd -a $USER docker
newgrp docker
# Test that Docker is working
docker run hello-world

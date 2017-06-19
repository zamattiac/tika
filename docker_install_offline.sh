#!/bin/bash
# Options: install Docker, configure registry server, Jenkins plugin, registry server
# Run this on each node

if [ $# == '0' ]; then
    echo "
USAGE:
- The Docker rpm folder must be in this directory.
- If this is the registry server, the registry tar must be in this directory.
- If this is the Jenkins master, Jenkins must be set up already.
- If this is the Jenkins master, the Plugins folder must be populated by the original plugins.

To be run on each computer in the network. There should be a designated Jenkins master and registry server.
A normal node's setup should consist of -a and -d (install docker and point to the registry server). Master and server should include the -j or -r options, respectively, to install the Docker plugin or start the registry server.

	-a [host:port]
		IF STARTING A REGISTRY (this or another node)(recommended)
	   	- Address of the registry server

	-d 
		IF INSTALLING DOCKER (recommended)

	-j [path to Jenkins home]
		IF THIS IS MASTER NODE
		- Installs Jenkins plugin/dependencies from Plugins folder

	-r [registry tarfile]
		IF THIS IS REGISTRY HOST
		- Loads and runs registry image
		- Runs on port given in -a. If -a not set, default is 5000	
";	
	exit 0
fi 

install_docker=false
jh_path=''
reg_addr=''
tar_path=''


while getopts ':a:dj:r:' flag; do
  case "${flag}" in
	a) reg_addr=${OPTARG} ;;
	d) install_docker=true ;;
	j) jh_path=${OPTARG} ;;
    r) tar_path=${OPTARG} ;;
    *) echo "Unexpected option ${flag}" ; exit 1 ;;
  esac
done

# e - exit if a pipe breaks
# u - throw error for unset variables
# x - trace of simple commands, for, case, etc.
set -exu

# Install Docker
if [ "$install_docker" = true ]; then
	original_path=`pwd`
	echo "Installing Docker..."
	cd Docker
	yum -y --nogpgcheck localinstall `ls` || echo "Docker install failed."
	echo "Starting Docker..."
	service docker start || echo "Docker could not be restarted. Please restart manually."
	cd $original_path
fi

# Install Jenkins plugin
if [ $jh_path ]; then
	if [ -d $jh_path ]; then
		echo "Installing Jenkins plugin and dependencies"
		cp Plugins/* $jh_path/plugins
		service jenkins restart || echo "Jenkins restart failed. Please restart manually."
	else
		echo "Jenkins home does not exist. Please start Jenkins and retry"
	fi 
fi

# Add configuration for the registry server if applicable
if [ $reg_addr ]; then
	if [ -e /etc/docker/daemon.json ]; then
		sed -i '$s/}/,\n"insecure-registries\":["'$reg_addr'"]}/' /etc/docker/daemon.json
	else
		echo '{"insecure-registries":["'$reg_addr'"]}' > /etc/docker/daemon.json
	fi
fi

# Run this guy as the registry server
if [ $tar_path ]; then
	echo "Starting registry."
	docker load -i $tar_path
	if [ -z $reg_addr ]; then echo "Using port 5000"; reg_addr='localhost:5000'; fi
	IFS=: read -r host port <<< $reg_addr
	docker run -d -p 5000:$port --restart=always --name registry registry:2
	echo "Registry 'registry' started on " $host:$port
fi

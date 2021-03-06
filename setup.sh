#!/bin/bash

env | sort
set -x

[ -e /etc/sysconfig/pacemaker ] &&. /etc/sysconfig/pacemaker
[ -e /etc/sysconfig/sbd ] && . /etc/sysconfig/sbd
[ -e /etc/sysconfig/pcsd ] && . /etc/sysconfig/pcsd

: ${CLUSTER_NAME="redhat"}
: ${REMOTE_NODE=0}


if [ ! -d /etc/secret-volume/ ]; then
    exit 1
fi

CLUSTER_PASS=$(cat /etc/secret-volume/password)
echo ${CLUSTER_PASS} | passwd --stdin hacluster

export GEM_HOME=/usr/lib/pcsd/vendor/bundle/ruby
/usr/lib/pcsd/pcsd &
/usr/sbin/pcsd &

sleep 5

NODE_ID=$(echo ${HOSTNAME} | sed s/\\..*//)
NODE_IP=$(grep ${HOSTNAME} /etc/hosts | grep -v : | cut -f1 | head -n 1)

if [ x$NODE_IP = x ]; then
    # Hope it's resolvable
    NODE_IP=$HOSTNAME
fi

if [ $REMOTE_NODE = 0 ]; then

    mkdir -p /etc/corosync/uidgid.d/ /var/lib/pacemaker/cib/ /var/lib/pacemaker/cib/pengine/
    
    target=/etc/corosync/authkey
    cp /etc/secret-volume/authkey $target
    chown root:root $target
    chmod 400 $target

    target=/etc/pacemaker/authkey
    cp /etc/secret-volume/authkey $target
    chown hacluster:haclient $target
    chmod 640 $target

    target=/etc/pacemaker/xvmkey
    cp /etc/secret-volume/fencekey $target
    chown root:root $target
    chmod 640 $target

    target=/var/lib/pacemaker/
    chown -R hacluster:haclient $target
    chmod -R 750 $target
    
    if [ -e /etc/corosync/corosync.conf ]; then
	: Nothing to do

    elif [ x${BOOTSTRAP_NODE} = x ]; then
	pcs host auth ${NODE_ID} addr=${NODE_IP} -u hacluster -p ${CLUSTER_PASS}
	#pcs --debug cluster setup ${CLUSTER_NAME} ${NODE_ID} --corosync_conf /etc/corosync/corosync.conf
	envsubst < /root/corosync.conf.in > /etc/corosync/corosync.conf
    
    else
	pcs host auth ${NODE_ID} addr=${NODE_IP} -u hacluster -p ${CLUSTER_PASS}
	pcs host auth ${BOOTSTRAP_NODE} -u hacluster -p ${CLUSTER_PASS}
	# pcs cluster auth  -u hacluster -p ${CLUSTER_PASS}
	if [ "x$(pcs cluster corosync ${BOOTSTRAP_NODE} | grep $NODE_IP)" = x ]; then
	    pcs --debug --force cluster node add ${NODE_IP} --bootstrap-from ${BOOTSTRAP_NODE}
	else
	    : Rejoining an existing or pre-configured cluster
	    pcs cluster corosync ${BOOTSTRAP_NODE} > /etc/corosync/corosync.conf
	fi
	cat /etc/corosync/corosync.conf
    fi
fi
exit 0

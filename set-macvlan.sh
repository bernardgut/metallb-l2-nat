#!/bin/bash
# set-mcvln.sh <host-inet> <svc-name> <svc-ip> <cidr-subnet>
#
# Configure routing with single MAC address/service for Metallb in L2 Mode
# Goal : be able to use NAT with Metallb in a LAN.
#
# Run this first then run kubectl expose deploy <your-deployment> --port=XXX --target-port=XXX
#
# this is a stub. Check it before running it.
set -x
set -e

HWLINK=$1
NAME=$2
MACVLN=k8s.$2
IP=$3
SUBNET=$4
NETWORK=$(ip -4 route list exact default | head -n1 | cut -d' ' -f3)
GATEWAY=$(ip -o route | grep default | grep "$HWLINK" | awk '{print $3}')

#create interface
sudo ip link add link "$HWLINK" "$MACVLN" type macvlan mode bridge
sudo ip address add "$IP/$SUBNET" dev "$MACVLN"
sudo ip link set dev "$MACVLN" up
#routing table
sudo ip route add "$NETWORK" dev "$MACVLN" metric 0 || echo "already exists"
sudo ip route add default via "$GATEWAY" || echo "already exists" # assuming network was already configured for $HWLINK, this will not do anything
# configure metallb
echo "
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
 name: $NAME
 namespace: metallb-system
spec:
 addresses:
 - $IP/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
 name: $NAME-bc
 namespace: metallb-system
spec:
 interfaces:
 - $MACVLN
 ipAddressPools:
 - $NAME
" | kubectl apply -f -
# finally create your MetallB Loadbalancer svc
# kubectl expose deploy $NAME --port=22 --target-port=8822

#!/bin/bash


set -x
#set -e

NAME=$1
MACVLN=k8s.$1

sudo ip link delete "$MACVLN"
kubectl -n metallb-system delete ipaddresspools.metallb.io "$NAME"
kubectl -n metallb-system delete l2advertisements.metallb.io "$NAME"-bc

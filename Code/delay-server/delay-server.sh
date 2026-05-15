#!/bin/bash

tc qdisc add dev eth0 root netem delay 5000ms
tc qdisc add dev eth1 root netem delay 5000ms

#iptables -t nat -A POSTROUTING -s 172.22.0.0/16 -d 172.21.0.0/16 -o eth0 -j MASQUERADE
#iptables -t nat -A POSTROUTING -s 172.21.0.0/16 -d 172.22.0.0/16 -o eth1 -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1

exec sleep infinity

#!/bin/sh
# Alpine 没有 bash，只有 sh

# 兜底流量
ip route append 172.22.0.0/24 via $DELAY_1 metric 100
ip route append 172.21.0.0/24 via $DELAY_2 metric 100

# 转发到 mail-1
socat TCP-LISTEN:10025,fork,reuseaddr TCP:$MAIL_1:25 &
socat TCP-LISTEN:10143,fork,reuseaddr TCP:$MAIL_1:143 &

# 转发到 mail-2
socat TCP-LISTEN:20025,fork,reuseaddr TCP:$MAIL_2:25 &
socat TCP-LISTEN:20143,fork,reuseaddr TCP:$MAIL_2:143 &

echo "Proxy Ready."
# 只要任何一个 socat 挂了，wait -n 就会捕获并退出
wait -n
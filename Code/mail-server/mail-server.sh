#!/bin/bash
set -e
# Set hostname and domain
FQDN="$HOSTNAME.$DOMAIN"
# 1. 配置网络GATEWAY
ip route del default
ip route add default via $GATEWAY dev eth0
# 2. 配置 /etc/hosts
echo "172.21.0.3 mail-1.a.com" >> /etc/hosts
echo "172.22.0.3 mail-2.a.com" >> /etc/hosts

# Create user
useradd -m -s /bin/bash user || echo "User already exists"
echo "user:123456" | chpasswd

# Configure Postfix
# 添加代理程序管道
# 仅将“对方服务器的”域写入 transport，避免本机回环
MASTER_CF="/etc/postfix/master.cf"
POSTFIX_TRANSPORT_FILE="/etc/postfix/transport"
if [[ "$HOSTNAME" == "mail-1" ]]; then
    echo "bp        unix  -       n       n       -       -       pipe" >> "$MASTER_CF"
    echo "      flags=ODR user=user argv=/usr/local/bin/bpmailsend -t 1 21 \${nexthop}" >> "$MASTER_CF"
    echo "mail-2.a.com   bp:ipn:3.129" >> "${POSTFIX_TRANSPORT_FILE}"
    postmap "${POSTFIX_TRANSPORT_FILE}"
elif [[ "$HOSTNAME" == "mail-2" ]]; then
    echo "bp        unix  -       n       n       -       -       pipe" >> "$MASTER_CF"
    echo "      flags=ODR user=user argv=/usr/local/bin/bpmailsend -t 2 21 \${nexthop}" >> "$MASTER_CF"
    echo "mail-1.a.com   bp:ipn:2.129" >> "${POSTFIX_TRANSPORT_FILE}"
    postmap "${POSTFIX_TRANSPORT_FILE}"
fi


postconf -e "transport_maps = hash:${POSTFIX_TRANSPORT_FILE}"

postconf -e "smtp_host_lookup = native"
postconf -e "myhostname = $FQDN"
postconf -e "myorigin = $DOMAIN"
postconf -e "mynetworks = 172.0.0.0/8 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
postconf -e "mailbox_transport = lmtp:unix:private/dovecot-lmtp"

# Configure Dovecot
sed -i '/service lmtp {/,/^}/{
  s|unix_listener lmtp {|unix_listener /var/spool/postfix/private/dovecot-lmtp {|;
  s|#\?mode =.*|mode = 0600|;
  /unix_listener \/var\/spool\/postfix\/private\/dovecot-lmtp {/a\    user = postfix\n    group = postfix
}' /etc/dovecot/conf.d/10-master.conf
sed -i 's|^mail_location =.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/^#\s*auth_username_format.*/auth_username_format = %n/' /etc/dovecot/conf.d/10-auth.conf
# sed -i 's/^#listen = .*/listen = */g' /etc/dovecot/dovecot.conf
# sed -i 's/^#disable_plaintext_auth = .*/disable_plaintext_auth = no/g' /etc/dovecot/conf.d/10-auth.conf
# sed -i 's/^auth_mechanisms = .*/auth_mechanisms = plain login/g' /etc/dovecot/conf.d/10-auth.conf
# sed -i 's/^#mail_location = .*/mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/g' /etc/dovecot/conf.d/10-mail.conf
# sed -i 's/^mail_location = .*/mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/g' /etc/dovecot/conf.d/10-mail.conf

# Create mail directory
mkdir -p /home/user/Maildir/{cur,new,tmp}
chown -R user:user /home/user/Maildir

# 定义退出函数
cleanup() {
    echo "[INFO] 收到退出信号，正在关闭服务..."
    # 杀掉后台运行的 bpmail 脚本
    pkill -f bpmail2postfix || true
    
    # 手动停止邮件服务，防止产生残留的 .pid 和 .lock 文件
    service postfix stop
    service dovecot stop
    
    echo "[INFO] 所有服务已安全关闭，容器退出。"
    exit 0
}
# 捕获 SIGTERM (docker stop) 和 SIGINT (Ctrl+C) 信号，并路由给 cleanup 函数
trap cleanup SIGTERM SIGINT

service postfix start
service dovecot start

# 启动对应的 ION-DTN
if [[ "$HOSTNAME" == "mail-1" ]]; then
    cd /usr/local/src/ION-DTN/demos/bench-udp/2.bench.udp
    ./ionstart
    /usr/local/src/bpmail/bpmail2postfix2.sh &
elif [[ "$HOSTNAME" == "mail-2" ]]; then
    cd /usr/local/src/ION-DTN/demos/bench-udp/3.bench.udp
    ./ionstart
    /usr/local/src/bpmail/bpmail2postfix1.sh &
fi

echo "Mail server started with hostname: $FQDN"

# 美化 sed -i 's/.../.../'
sed -i 's/^#\?\s*force_color_prompt=yes/force_color_prompt=yes/' ~/.bashrc

# Keep container running
touch /var/log/mail.log /var/log/mail.err /var/log/syslog
tail -f /var/log/mail.log /var/log/mail.err /var/log/syslog &
# 当收到 SIGTERM 信号时，trap 会打断 wait，立刻执行 cleanup 函数
wait

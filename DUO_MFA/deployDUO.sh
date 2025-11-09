#!/bin/bash

read -p "ikey: " IKEY
read -p "skey: " SKEY
read -p "host: " HOST

mkdir -p /etc/duo
cat > /etc/duo/pam_duo.conf << EOF
[duo]
ikey=$IKEY
skey=$SKEY
host=$HOST
pushinfo=yes
autopush=yes
EOF
chmod 600 /etc/duo/pam_duo.conf

sed -i '1 a\UsePAM yes\nChallengeResponseAuthentication yes\nPasswordAuthentication yes' /etc/ssh/sshd_config

sed -i '/auth       substack     password-auth/a auth       required     pam_duo.so' /etc/pam.d/sshd

systemctl restart sshd
echo "Done"

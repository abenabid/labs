#!/bin/bash
# Configuring hostname
hostnamectl set-hostname bastion

# Setting private SSH key
echo '${private_key_pem}' > /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa

# Adding IP to au hostname (k3s-server) association in hosts file
echo "${k3s_server} k3s-server" >> /etc/hosts

# Installation de TTYD
wget -O /bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.1/ttyd.x86_64
chmod a+x /bin/ttyd
setcap CAP_NET_BIND_SERVICE=+eip /bin/ttyd

cat <<EOF > /etc/systemd/system/ttyd.service
[Unit]
Description=Terminal over HTTP

[Service]
User=ubuntu
ExecStart=/bin/ttyd -p 80 --credential user:pass -u 1000 -g 1000 /usr/bin/ssh -i /home/ubuntu/.ssh/id_rsa -o StrictHostKeyChecking=accept-new ubuntu@k3s-server
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ttyd.service
systemctl start ttyd.service


# Launch TTYD
#ttyd -p 80 --credential user:pass -u 1000 -g 1000 /usr/bin/ssh -i /home/ubuntu/.ssh/id_rsa -o StrictHostKeyChecking=accept-new ubuntu@k3s-server
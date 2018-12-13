#!/bin/bash
#
# Script to download and install Consul as a service on the node
#
# (C) Copyright 2018 Opsgang.io, Martin Dobrev
#
#
######################################################################
set -xe

sudo apt-get install unzip curl -y -q

curl -O https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip
unzip consul_${consul_version}_linux_amd64.zip
rm -f consul_${consul_version}_linux_amd64.zip
mv consul /usr/local/bin

mkdir -p /etc/consul.d

cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul agent script
Requires=network-online.target
After=network-online.target

[Service]
EnvironmentFile=-/etc/default/consul
Environment=GOMAXPROCS=2
Restart=on-failure
ExecStart=/usr/local/bin/consul agent \$OPTIONS -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/default/consul
OPTIONS="-server -data-dir=/tmp/consul -bind=$(hostname -i) -client=0.0.0.0 -datacenter=${aws_region} -bootstrap-expect=${consul_server_nodes} -ui -retry-join='provider=aws region=${aws_region} addr_type=private_v4 tag_key=io.opsgang.consul:clusters:nodes tag_value=${consul_cluster_name}'"
EOF

systemctl daemon-reload
systemctl enable consul
systemctl start consul

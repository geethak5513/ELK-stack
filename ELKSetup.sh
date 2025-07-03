#!/bin/bash

set -e

echo "=== Installing Elasticsearch ==="
cd /tmp
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.18-x86_64.rpm
sudo rpm -ivh elasticsearch-7.17.18-x86_64.rpm

echo "=== Configuring Elasticsearch ==="
sudo sed -i 's/^-Xms.*/-Xms256m/' /etc/elasticsearch/jvm.options
sudo sed -i 's/^-Xmx.*/-Xmx256m/' /etc/elasticsearch/jvm.options

sudo bash -c 'cat >> /etc/elasticsearch/elasticsearch.yml' <<EOF
network.host: localhost
http.port: 9200
discovery.type: single-node
EOF

echo "=== Creating Swap Space (2GB) ==="
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

echo "=== Starting Elasticsearch ==="
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
sleep 5
curl -s http://localhost:9200 || echo "Elasticsearch not responding yet"

echo "=== Installing Kibana ==="
cd /tmp
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.17.18-x86_64.rpm
sudo rpm -ivh kibana-7.17.18-x86_64.rpm

echo "=== Configuring Kibana ==="
sudo bash -c 'cat >> /etc/kibana/kibana.yml' <<EOF
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
EOF

echo "=== Starting Kibana ==="
sudo systemctl enable kibana
sudo systemctl start kibana

echo "=== Opening Firewall Port for Kibana ==="
sudo firewall-cmd --permanent --add-port=5601/tcp
sudo firewall-cmd --reload || echo "Firewall reload failed or not applicable"

echo "=== Installing Filebeat ==="
cd /tmp
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.18-x86_64.rpm
sudo rpm -ivh filebeat-7.17.18-x86_64.rpm

echo "=== Configuring Filebeat ==="
sudo bash -c 'cat > /etc/filebeat/filebeat.yml' <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /home/opc/app.log

output.elasticsearch:
  hosts: ["http://localhost:9200"]
EOF

echo "=== Starting Filebeat ==="
sudo systemctl enable filebeat
sudo systemctl start filebeat

echo "=== Verifying Filebeat ==="
sudo journalctl -u filebeat -n 10

echo "=== Creating Log Generator Script ==="
cat > /home/opc/log-generator.sh <<'EOF'
#!/bin/bash
while true
do
  echo "$(date) - INFO - This is a test log entry" >> /home/opc/app.log
  sleep 5
done
EOF

chmod +x /home/opc/log-generator.sh

echo "=== Setup Complete! To start log generation, run: ==="
echo "bash /home/opc/log-generator.sh &"

echo "Access Kibana at: http://<your-instance-public-ip>:5601"

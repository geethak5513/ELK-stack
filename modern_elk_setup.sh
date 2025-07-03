#!/bin/bash
set -euo pipefail

echo "=== Installing prerequisites ==="
sudo apt-get update
sudo apt-get install -y wget gnupg

echo "=== Adding Elastic GPG key and repo ==="
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo tee /etc/apt/sources.list.d/elastic-7.x.list > /dev/null <<EOF
deb https://artifacts.elastic.co/packages/7.x/apt stable main
EOF

echo "=== Installing Elasticsearch, Kibana, Filebeat ==="
sudo apt-get update
sudo apt-get install -y elasticsearch=7.17.18 kibana=7.17.18 filebeat=7.17.18

echo "=== Configuring Elasticsearch ==="
sudo sed -i -e 's/^#\(network.host:\).*/\1 localhost/' \
            -e 's/^#\(http.port:\).*/\1 9200/' \
            -e '$a discovery.type: single-node' \
            /etc/elasticsearch/elasticsearch.yml

echo "=== Setting JVM heap size to 256m ==="
sudo sed -i 's/^-Xms.*/-Xms256m/' /etc/elasticsearch/jvm.options
sudo sed -i 's/^-Xmx.*/-Xmx256m/' /etc/elasticsearch/jvm.options

echo "=== Enabling and Starting Elasticsearch ==="
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
sleep 10

echo "=== Verifying Elasticsearch ==="
curl -s http://localhost:9200 | grep cluster_name || (echo "Elasticsearch not responding" && exit 1)

echo "=== Configuring Kibana ==="
sudo sed -i -e 's/^#\(server.host:\).*/\1 "0.0.0.0"/' \
            -e 's|^#\(elasticsearch.hosts:\).*|\1 ["http://localhost:9200"]|' \
            /etc/kibana/kibana.yml

echo "=== Enabling and Starting Kibana ==="
sudo systemctl enable kibana
sudo systemctl start kibana

echo "=== Configuring Filebeat ==="
sudo tee /etc/filebeat/filebeat.yml > /dev/null <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /home/opc/app.log

output.elasticsearch:
  hosts: ["http://localhost:9200"]
EOF

echo "=== Enabling and Starting Filebeat ==="
sudo systemctl enable filebeat
sudo systemctl start filebeat

echo "=== Creating 2GB Swapfile ==="
if ! sudo swapon --show | grep -q '/swapfile'; then
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
else
  echo "Swapfile already exists and active."
fi

echo "=== Creating Log Generator Script ==="
cat > /home/opc/log-generator.sh <<'EOF'
#!/bin/bash
while true; do
  echo "$(date) - INFO - This is a test log entry" >> /home/opc/app.log
  sleep 5
done
EOF
chmod +x /home/opc/log-generator.sh

echo "=== Setup complete! ==="
echo "Start generating logs: bash /home/opc/log-generator.sh &"
echo "Access Kibana at http://<your-instance-public-ip>:5601"

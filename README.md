# ELK-stack
ELK stack manual installation using rpm:
-->This will download the Elasticsearch 7.17.18 RPM file directly.
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.18-x86_64.rpm
sudo rpm -ivh elasticsearch-7.17.18-x86_64.rpm
-->Edit the JVM heap size:
sudo nano /etc/elasticsearch/jvm.options
Change:
-Xms256m
-Xmx256m
sudo nano /etc/elasticsearch/elasticsearch.yml
Add:
network.host: localhost
http.port: 9200
discovery.type: single-node
--->Enable and Start Elasticsearch
network.host: localhost
http.port: 9200
discovery.type: single-node
-->Test it:
curl http://localhost:9200
sudo systemctl start elasticsearch
Test it:
curl http://localhost:9200
-->This helps prevent memory-related crashes:
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
Edit your local SSH config (~/.ssh/config) and add, This sends a keep-alive packet every 60 seconds:
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 3
Kibana:
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.17.18-x86_64.rpm
sudo rpm -ivh kibana-7.17.18-x86_64.rpm
sudo nano /etc/kibana/kibana.yml
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
Start and Enable Kibana
sudo systemctl enable kibana
sudo systemctl start kibana
-->If you're using a firewall:
sudo firewall-cmd --permanent --add-port=5601/tcp
sudo firewall-cmd --reload
-->Also, make sure port 5601 is open in your OCI security list (under your instance’s VCN settings).
-->Access Kibana
Open your browser and go to:
http://<your-instance-public-ip>:5601
-->Filebeat
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.18-x86_64.rpm
sudo rpm -ivh filebeat-7.17.18-x86_64.rpm
sudo nano /etc/filebeat/filebeat.yml
Input Section:
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /home/opc/app.log
🔸 Output Section

output.elasticsearch:
  hosts: ["http://localhost:9200"]
start and Enable Filebeat:
sudo systemctl enable filebeat
sudo systemctl start filebeat
Verify if its working:
sudo journalctl -u filebeat -f
test:
curl -X GET "localhost:9200/filebeat-*/_search?pretty"
App logs:
nano log-generator.sh
#!/bin/bash
while true
do
  echo "$(date) - INFO - This is a test log entry" >> /home/opc/app.log
  sleep 5
done

chmod +x log-generator.sh
./log-generator.sh
















# Remove firewalld
yum remove firewalld -y

# Install net-tools, git, zip, ntp
yum install net-tools git zip ntp -y
ntpdate -s time.nist.gov

# Wazuh dev repository
echo -e '[wazuh_repo_dev]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/yum-dev/\nprotect=1' | tee /etc/yum.repos.d/wazuh_dev.repo

# Install Wazuh manager
yum install wazuh-manager-3.7.0 -y

# Install Node.js
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - 
yum install nodejs -y 

# Install Wazuh API
yum install wazuh-api-3.7.0 -y

# Wazuh cluster dependencies
yum install python-setuptools python-cryptography -y

# Configure Wazuh master node
sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node>NODE_IP</node>:<node>172.16.1.2</node>:g' /var/ossec/etc/ossec.conf
sed -i -e '/<cluster>/,/<\/cluster>/ s|<disabled>[a-z]\+</disabled>|<disabled>no</disabled>|g' /var/ossec/etc/ossec.conf

# Enable Wazuh services
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl enable wazuh-api

# Run Wazuh manager and Wazuh API
systemctl restart wazuh-manager
systemctl restart wazuh-api

# Elastic GPG KEY
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

# Elastic repository
cat > /etc/yum.repos.d/elastic.repo << EOF
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install Filebeat
yum install filebeat-6.4.2 -y

# Enable Filebeat service
systemctl daemon-reload
systemctl enable filebeat

# Filebeat configuration
curl -so /etc/filebeat/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/filebeat/filebeat.yml
sed -i 's:YOUR_ELASTIC_SERVER_IP:172.16.1.4:g' /etc/filebeat/filebeat.yml

# Run Filebeat
systemctl restart filebeat

# Ready for registering agents
echo "Listening authd..."

/var/ossec/bin/ossec-authd 
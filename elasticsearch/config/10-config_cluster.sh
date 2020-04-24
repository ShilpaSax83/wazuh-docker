#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"
original_file="/usr/share/elasticsearch/config/original-elasticsearch.yml"
ELASTIC_HOSTAME=`hostname`

echo "CLUSTER: - Prepare Configuration"
echo "CLUSTER: - Hostname"
echo $ELASTIC_HOSTAME
echo "CLUSTER: - Security main node"
echo $SECURITY_MAIN_NODE
echo "CLUSTER: - Discovery seed"
echo $CLUSTER_DISCOVERY_SEED
echo "CLUSTER: - Elastic cluster flag"
echo $ELASTIC_CLUSTER
echo "CLUSTER: - Node Master"
echo $CLUSTER_NODE_MASTER
echo "CLUSTER: - Node Data"
echo $CLUSTER_NODE_DATA
echo "CLUSTER: - Node Ingest"
echo $CLUSTER_NODE_INGEST

cp $elastic_config_file $original_file 

remove_single_node_conf(){
  if grep -Fq "discovery.type" $1; then
    sed -i '/discovery.type\: /d' $1 
  fi
}

remove_cluster_config(){
  sed -i '/# cluster node/,/# end cluster config/d' $1
}

# If Elasticsearch cluster is enable, then set up the elasticsearch.yml
if [[ $ELASTIC_CLUSTER == "true" && $CLUSTER_NODE_MASTER != "" && $CLUSTER_NODE_DATA != "" && $CLUSTER_NODE_INGEST != "" && $ELASTIC_HOSTAME != "" ]]; then
  # Remove the old configuration
  remove_single_node_conf $elastic_config_file
  remove_cluster_config $elastic_config_file
  echo "CLUSTER: - Remove old configuration"

if [[ $ELASTIC_HOSTAME == $SECURITY_MAIN_NODE ]]; then
# Add the master configuration
# cluster.initial_master_nodes for bootstrap the cluster
echo "CLUSTER: - Add the master configuration"

cat > $elastic_config_file << EOF
# cluster node
cluster.name: $CLUSTER_NAME
bootstrap.memory_lock: $CLUSTER_MEMORY_LOCK
network.host: 0.0.0.0
node.name: $ELASTIC_HOSTAME
node.master: $CLUSTER_NODE_MASTER
node.data: $CLUSTER_NODE_DATA
node.ingest: $CLUSTER_NODE_INGEST
node.max_local_storage_nodes: $CLUSTER_MAX_NODES
cluster.initial_master_nodes: 
  - $ELASTIC_HOSTAME
# end cluster config" 
EOF

elif [[ $CLUSTER_DISCOVERY_SEED != "" ]]; then
# Remove the old configuration
remove_single_node_conf $elastic_config_file
remove_cluster_config $elastic_config_file
echo "CLUSTER: - Add standard cluster configuration."

cat > $elastic_config_file << EOF
# cluster node
cluster.name: $CLUSTER_NAME
bootstrap.memory_lock: $CLUSTER_MEMORY_LOCK
network.host: 0.0.0.0
node.name: $ELASTIC_HOSTAME
node.master: $CLUSTER_NODE_MASTER
node.data: $CLUSTER_NODE_DATA
node.ingest: $CLUSTER_NODE_INGEST
node.max_local_storage_nodes: $CLUSTER_MAX_NODES
discovery.seed_hosts: 
  - $CLUSTER_DISCOVERY_SEED
# end cluster config" 
EOF
fi
# If the cluster is disabled, then set a single-node configuration
else
  # Remove the old configuration
  remove_single_node_conf $elastic_config_file
  remove_cluster_config $elastic_config_file
  echo "discovery.type: single-node" >> $elastic_config_file
  echo "CLUSTER: - Discovery type: single-node"
fi

echo "CLUSTER: - Configured"
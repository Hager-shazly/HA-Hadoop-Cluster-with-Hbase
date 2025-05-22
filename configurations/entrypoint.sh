#!/bin/bash

# COMMON SETUP FOR ALL NODES
sudo service ssh start


# Check if hostname contains "master"
if [[ "$HOSTNAME" == *"master"* ]]; then
    # Assign myid based on hostname
    ID=$(echo $HOSTNAME | tail -c 2) 
    echo $ID > /usr/local/zookeeper/data/myid
            

     hdfs --daemon start journalnode
     zkServer.sh start

    # Check if this is the first-time setup
    #if [ ! -f /usr/local/hadoop/namenode/formatted ]; then
       if [ "$ID" == "1" ]; then
        if [ ! -d /usr/local/hadoop/namenode/current ]; then
            hdfs namenode -format -force
            hdfs zkfc -formatZK -force
            hdfs --daemon start zkfc
        fi
            echo "NameNode already formatted. Skipping format step."
            hdfs --daemon start namenode
  
        else 
            if [ ! -d /usr/local/hadoop/namenode/current ]; then
                echo "Bootstrapping standby NameNode for $HOSTNAME..."
                sleep 240
                hdfs namenode -bootstrapStandby
            fi
            hdfs --daemon start zkfc
            hdfs --daemon start namenode 
        fi
    yarn --daemon start resourcemanager
else
    echo "This is a worker node. Starting DataNode and NodeManager..."
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
fi




# # Start Zookeeper
# echo "Starting Zookeeper..."
# /usr/local/zookeeper/bin/zkServer.sh start

sleep infinity
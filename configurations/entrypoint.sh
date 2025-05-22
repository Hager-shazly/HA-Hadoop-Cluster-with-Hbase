#!/bin/bash

# COMMON SETUP FOR ALL NODES
sudo service ssh start


# Check if hostname contains "master"
if [[ "$HOSTNAME" == "hmaster"* ]]; then
    # Assign myid based on hostname
    ID=$(echo $HOSTNAME | tail -c 2) 
    echo $ID > /usr/local/zookeeper/data/myid
     hdfs --daemon start journalnode
     zkServer.sh start
     sleep 12

    # Check if this is the first-time setup
    if [ "$ID" == "1" ]; then
        # Format the NameNode
        if [ ! -f /usr/local/hadoop/namenode/current/formatted ]; then
            echo "Formatting NameNode for the first time..."
            hdfs namenode -format -force
            touch /usr/local/hadoop/namenode/current/formatted
            echo "NameNode formatted successfully."
        else
            echo "NameNode already formatted. Skipping format step."
        fi
        # Format Zookeeper
        if [ ! -d /usr/local/hadoop/zookeeper/data/formatted ]; then
            echo "Formatting Zookeeper..."
            hdfs zkfc -formatZK -force
            touch /usr/local/hadoop/zookeeper/data/formatted
            echo "Zookeeper formatted successfully."
        else
            echo "Zookeeper already formatted. Skipping format step."
        fi
        # Intialize JournalNode
        if [ ! -d /usr/local/hadoop/journal/formatted ]; then
            echo "Intializing Shared edits..."
            hdfs namenode -initializeSharedEdits -force
            touch /usr/local/hadoop/journal/formatted
            echo "JournalNode formatted successfully."
        else
            echo "Shared edits already initialized. Skipping initialization step."
        fi
        # Start the services in master1
        hdfs --daemon start zkfc
        hdfs --daemon start namenode
        hdfs --daemon start resourcemanager
        echo "All services started successfully on $HOSTNAME."
    else 
        # Wait for the master node to be active
        echo "Waiting for the master node to be active..."
        while ! hdfs haadmin -checkHealth nn1 2> /dev/null; do
            sleep 5
        done
        echo "Master node is active. Starting services on $HOSTNAME..."
        # check if standby namenode is not bootstrapped
        if [ ! -d /usr/local/hadoop/namenode/standby_done ]; then
            echo "Bootstrapping Standby NameNode..."
            hdfs namenode -bootstrapStandby -force
            touch /usr/local/hadoop/namenode/standby_done
            echo "Standby NameNode bootstrapped successfully."
        else
            echo "Standby NameNode already bootstrapped. Skipping bootstrap step."
        fi
        # Start the services in other masters
        hdfs --daemon start zkfc
        hdfs --daemon start namenode 
        yarn --daemon start resourcemanager
        echo "All services started successfully on $HOSTNAME."
        fi

elif [[ "$HOSTNAME" == "hworker"* ]]; then
    echo "Starting DataNode and NodeManager..."
    hdfs --daemon start datanode
    yarn --daemon start nodemanager 
    echo "DataNode and NodeManager started successfully on $HOSTNAME."

elif [[ "$HOSTNAME" == "hbmaster"* ]]; then
    echo "This is Hmaster node. Starting HMaster..."
    hbase master start

elif [[ "$HOSTNAME" == "regionserver"* ]]; then
    echo "This is a regionserver node. Starting RegionServer..."
    hbase regionserver start    
  
fi

sleep infinity
#!/bin/bash

# COMMON SETUP FOR ALL NODES
sudo service ssh start

MASTER1="hmaster1"
MASTER2="hmaster2"
MASTER3="hmaster3"
WORKER1="hworker1"
NAMENODE_PORT= 9870
ZOOKEEPER_PORT= 2180

if [[ "$HOSTNAME" == *"master"* ]]; then
    hdfs --daemon start journalnode
    case "  $HOSTNAME" in
        "$MASTER1")
            echo "1" > /usr/local/zookeeper/data/myid
            zkServer.sh start


            ;;
        "$MASTER2")
            echo "2" > /usr/local/zookeeper/data/myid
            if 

            ;;
        "$MASTER3")
            echo "3" > /usr/local/zookeeper/data/myid


            ;;
        *)
            echo "Unknown master hostname: $HOSTNAME. Exiting..."
            exit 1
            ;;
    esac


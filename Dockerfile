FROM ubuntu:22.04

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV HBASE_HOME=/usr/local/hbase
ENV HBASE_CONF_DIR=$HBASE_HOME/conf
ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:$PATH

ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:${HBASE_HOME}/bin:$PATH          \
    HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop                                                                     \
    HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native                                                        \
    HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"

ENV HADOOP_CLASSPATH=$HADOOP_HOME/lib/*:$ZOOKEEPER_HOME/*.jar

# Install dependencies
RUN apt-get update && apt-get install -y \
    sudo wget vim openssh-server openssh-client openjdk-8-jdk \
    python3 python3-pip && \
    pip3 install faker && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


# Set up Java
RUN mv /usr/lib/jvm/java-1.8.0-openjdk-amd64 /usr/lib/jvm/java

WORKDIR /usr/local

# Create Hadoop user and group
RUN groupadd hadoop && \
    useradd -m -g hadoop hduser && \
    echo "hduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install Hadoop
RUN wget -P /tmp https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzvf /tmp/hadoop-3.3.6.tar.gz -C /usr/local && \
    mv /usr/local/hadoop-3.3.6 /usr/local/hadoop && \
    mkdir -p /usr/local/hadoop/namenode /usr/local/hadoop/datanode /usr/local/hadoop/journal/data && \
    chown -R hduser:hadoop /usr/local/hadoop && \
    chmod -R 777 /usr/local/hadoop


# Install Zookeeper
RUN wget -P /tmp https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz && \
    tar -xzvf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-zookeeper-3.8.4-bin /usr/local/zookeeper && \
    mkdir -p /usr/local/zookeeper/data && \
    chown -R hduser:hadoop /usr/local/zookeeper && \
    chmod -R 777 /usr/local/zookeeper


# Install Hbase 2.4.18
RUN wget -P /tmp https://dlcdn.apache.org/hbase/2.4.18/hbase-2.4.18-bin.tar.gz && \
    tar -xvzf /tmp/hbase-2.4.18-bin.tar.gz -C /usr/local && \
    mv /usr/local/hbase-2.4.18 /usr/local/hbase && \
    chown -R hduser:hadoop /usr/local/hbase && \
    chmod -R 777 /usr/local/hbase && \
    rm -rf /tmp/hbase-2.4.18-bin.tar.gz

# Switch to Hadoop user
USER hduser

# Set up SSH for Hadoop
RUN ssh-keygen -t rsa -N "" -f /home/hduser/.ssh/id_rsa && \
    cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys && \
    chmod 600 /home/hduser/.ssh/authorized_keys


# Copy configuration files
COPY --chown=hduser:hadoop ./configurations/hadoop/* $HADOOP_CONF_DIR/
COPY --chown=hduser:hadoop ./configurations/hbase/* ${HBASE_HOME}/conf/
COPY --chown=hduser:hadoop ./configurations/zoo.cfg $ZOOKEEPER_HOME/conf/zoo.cfg
COPY --chown=hduser:hadoop ./configurations/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=hduser:hadoop ./configurations/hbase/hbase-env.sh $HBASE_CONF_DIR/hbase-env.sh


# Copy entrypoint script
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

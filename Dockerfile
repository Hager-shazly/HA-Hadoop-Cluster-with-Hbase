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
ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:$PATH

ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:${HBASE_HOME}/bin:$PATH          \
    HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop                                                                     \
    HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native                                                        \
    HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"                                                     

ENV HADOOP_CLASSPATH=$HADOOP_HOME/lib/*:$ZOOKEEPER_HOME/*.jar

# Install dependencies
RUN apt-get update && apt-get install -y \
    sudo wget vim openssh-server openssh-client openjdk-8-jdk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up Java
RUN mv /usr/lib/jvm/java-1.8.0-openjdk-amd64 /usr/lib/jvm/java

WORKDIR /usr/local

# Create Hadoop user and group
RUN groupadd hadoop && \
    useradd -m -g hadoop hduser && \
    echo "hduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install Hadoop
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp && \
    tar -xzvf /tmp/hadoop-3.3.6.tar.gz -C /usr/local && \
    mv /usr/local/hadoop-3.3.6 /usr/local/hadoop && \
    mkdir -p /usr/local/hadoop/namenode /usr/local/hadoop/datanode /usr/local/hadooop/journal/data && \
    chown -R hduser:hadoop /usr/local/hadoop && \
    chmod -R 777 /usr/local/hadoop

# Install Zookeeper
RUN https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp && \
    tar -xzvf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local  && \
    mv /usr/local/apache-zookeeper-3.8.4-bin /usr/local/zookeeper   && \
    mkdir -p /usr/local/zookeeper/data                              && \
    chown -R hduser:hadoop /usr/local/zookeeper                     && \
    chmod -R 777 /usr/local/zookeeper

# Install Hbase 2.4.18
RUN wget https://dlcdn.apache.org/hbase/2.4.18/hbase-2.4.18-bin.tar.gz  && \
    tar -xvzf hbase-2.4.18-bin.tar.gz                                   && \
    mv hbase-2.4.18 hbase                                               && \
    chown -R hduser:hadoop hbase                                        && \
    rm -rf hbase-2.4.18-bin.tar.gz

# Switch to Hadoop user
USER hduser

# Set up SSH for Hadoop
RUN ssh-keygen -t rsa -N "" -f /home/hduser/.ssh/id_rsa && \
    cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys && \
    chmod 600 /home/hduser/.ssh/authorized_keys


# Copy configuration files
COPY --chown=hduser:hdoop ./configurations/hadoop/* $HADOOP_CONF_DIR/
COPY --chown=hduser:hadoop ./configurations/hbase/* ${HBASE_HOME}/conf/
COPY --chown=hduser:hadoop ./configurations/zoo.cfg $ZOOKEEPER_HOME/conf/zoo.cfg
COPY --chown=hduser:hadoop ./configurations/entrypoint.sh /usr/local/bin/entrypoint.sh


# Copy entrypoint script
RUN sudo chmod +x /home/hduser/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

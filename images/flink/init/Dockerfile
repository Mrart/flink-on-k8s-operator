ARG FLINK_VERSION
ARG SCALA_VERSION
FROM hub.c.163.com/flink/flink:1.9.1-without-hdfs
ARG HADOOP_CONF_DIR
ENV HADOOP_CONF_DIR=${HADOOP_CONF_DIR}

#RUN test -n "$FLINK_VERSION"
#RUN test -n "$FLINK_HADOOP_VERSION"
#RUN test -n "$GCS_CONNECTOR_VERSION"

ENV HDFS_CLIENT_URL=nbot-common.nos-jd.163yun.com/hdfs-client.tar.gz
ENV HADOOP_HOME_DIR=/opt/hdfs_client
ENV JAVA_HOME=/usr/local/openjdk-8
ENV PATH=$FLINK_HOME/bin:$JAVA_HOME/bin:$HADOOP_HOME_DIR/bin:$HADOOP_HOME_DIR/sbin:$PATH

RUN set -ex; \
    wget -nv -O hdfs-client.tar.gz "$HDFS_CLIENT_URL"; \
    tar -xvf hdfs-client.tar.gz -C /opt/; \
    rm -rf hdfs-client.tar.gz;

COPY ${HADOOP_CONF_DIR}  /opt/flink/hdfs/
ENV HADOOP_CONF_DIR=/opt/flink/hdfs/

# Entry point.
COPY entrypoint.sh /
RUN chmod 775 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

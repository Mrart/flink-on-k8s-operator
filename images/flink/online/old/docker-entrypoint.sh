#!/bin/bash

###############################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

# If unspecified, the hostname of the container is taken as the JobManager address
JOB_MANAGER_RPC_ADDRESS=${JOB_MANAGER_RPC_ADDRESS:-$(hostname -f)}
CONF_FILE="${FLINK_HOME}/conf/flink-conf.yaml"


drop_privs_cmd() {
    if [ $(id -u) != 0 ]; then
        # Don't need to drop privs if EUID != 0
        return
    elif [ -x /sbin/su-exec ]; then
        # Alpine
        echo su-exec da_music
    else
        # Others
        echo gosu da_music
    fi
}

# fixed log name
sed -i 's/FLINK_LOG_PREFIX\=.*/FLINK_LOG_PREFIX=\"${FLINK_LOG_DIR}\/${UUID}\/${HOSTNAME}\"/g' $FLINK_HOME/bin/flink-daemon.sh

mkdir -p /opt/flink/log/${UUID}
chmod 777 -R /opt/flink/log/${UUID}
chown da_music:da_music -R /opt/flink/log/${UUID}
mkdir -p ${FLINK_HOME}/job
chmod 777 ${FLINK_HOME}/job -R
chmod 777 ${FLINK_HOME}/lib -R
chown da_music:da_music -R /opt/flink/job

DOCKER_ENV_HADOOP_CONF = $HADOOP_CONF_DIR

# Download remote classpath file.
jarFilesFromHdfs="" ## 拼接字符串
if [[ -n "${FLINK_JOB_FILES_URI}" ]]; then
  files=(${FLINK_JOB_FILES_URI//,/ })
  echo "Downloading job JAR ${FLINK_JOB_FILES_URI} to ${FLINK_HOME}/lib"
  for file in ${files[@]}
  do
  if [[ "${file}" == hdfs://* ]]; then
    jarFilesFromHdfs=$jarFilesFromHdfs" "$file
  elif [[ "${file}" == http://* || "${file}" == https://* ]]; then
    wget -nv -P "${FLINK_HOME}/lib/" "${file}"
  else
    echo "Unsupported protocol for ${file}"
    exit 1

  fi
  done
fi

# Download remote job JAR file.
if [[ -n "${FLINK_JOB_JAR_URI}" ]]; then
  echo "Downloading job JAR ${FLINK_JOB_JAR_URI} to ${FLINK_HOME}/lib/"
  if [[ "${FLINK_JOB_JAR_URI}" == hdfs://* ]]; then
     jarFilesFromHdfs=$jarFilesFromHdfs" "$FLINK_JOB_JAR_URI
  elif [[ "${FLINK_JOB_JAR_URI}" == http://* || "${FLINK_JOB_JAR_URI}" == https://* ]]; then
    wget -nv -P "${FLINK_HOME}/lib/" "${FLINK_JOB_JAR_URI}"
  else
    echo "Unsupported protocol for ${FLINK_JOB_JAR_URI}"
    exit 1
  fi
fi

DOCKER_ENV_HADOOP_CONF=$HADOOP_CONF_DIR
if [[ -n "${jarFilesFromHdfs}" ]]; then
    if [ -d "/opt/hdfs_client/etc/hadoop/" ];
    then
      export HADOOP_CONF_DIR=/opt/hdfs_client/etc/hadoop/
    else
      echo "No need change the hdfs config"
    fi
     su - sloth -c "export JAVA_HOME=/usr/local/openjdk-8 && /opt/hdfs_client/bin/hadoop dfs -copyToLocal $jarFilesFromHdfs ${FLINK_HOME}/job/"
     export HADOOP_CONF_DIR=$DOCKER_ENV_HADOOP_CONF
    fi
cp ${FLINK_HOME}/job/ ${FLINK_HOME}/lib -R
chown da_music:da_music -R /opt/flink/job
chown da_music:da_music -R /opt/flink/lib
if [ "$1" = "help" ]; then
    echo "Usage: $(basename "$0") (jobmanager|taskmanager|help)"
    exit 0
elif [ "$1" = "jobmanager" ]; then
    shift 1
    echo "Starting Job Manager"

    if grep -E "^jobmanager\.rpc\.address:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/jobmanager\.rpc\.address:.*/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" "${CONF_FILE}"
    else
        echo "jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}" >> "${CONF_FILE}"
    fi

    if grep -E "^blob\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/blob\.server\.port:.*/blob.server.port: 6124/g" "${CONF_FILE}"
    else
        echo "blob.server.port: 6124" >> "${CONF_FILE}"
    fi

    if grep -E "^query\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/query\.server\.port:.*/query.server.port: 6125/g" "${CONF_FILE}"
    else
        echo "query.server.port: 6125" >> "${CONF_FILE}"
    fi

    if [ -n "${FLINK_PROPERTIES}" ]; then
        echo "${FLINK_PROPERTIES}" >> "${CONF_FILE}"
    fi

    echo "config file: " && grep '^[^\n#]' "${CONF_FILE}"
    $(drop_privs_cmd) "$FLINK_HOME/bin/jobmanager.sh" start;

    while true;
     do
        if [[ -f $(find log -name '*jobmanager*.log' -print -quit) ]]; then
           tail -f -n +1 /opt/flink/log/*/*jobmanager*.log;
        fi;
    done
elif [ "$1" = "taskmanager" ]; then
    shift 1
    echo "Starting Task Manager"

    TASK_MANAGER_NUMBER_OF_TASK_SLOTS=${TASK_MANAGER_NUMBER_OF_TASK_SLOTS:-$(grep -c ^processor /proc/cpuinfo)}

    if grep -E "^jobmanager\.rpc\.address:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/jobmanager\.rpc\.address:.*/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" "${CONF_FILE}"
    else
        echo "jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}" >> "${CONF_FILE}"
    fi

    if grep -E "^taskmanager\.numberOfTaskSlots:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/taskmanager\.numberOfTaskSlots:.*/taskmanager.numberOfTaskSlots: ${TASK_MANAGER_NUMBER_OF_TASK_SLOTS}/g" "${CONF_FILE}"
    else
        echo "taskmanager.numberOfTaskSlots: ${TASK_MANAGER_NUMBER_OF_TASK_SLOTS}" >> "${CONF_FILE}"
    fi

    if grep -E "^blob\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/blob\.server\.port:.*/blob.server.port: 6124/g" "${CONF_FILE}"
    else
        echo "blob.server.port: 6124" >> "${CONF_FILE}"
    fi

    if grep -E "^query\.server\.port:.*" "${CONF_FILE}" > /dev/null; then
        sed -i -e "s/query\.server\.port:.*/query.server.port: 6125/g" "${CONF_FILE}"
    else
        echo "query.server.port: 6125" >> "${CONF_FILE}"
    fi

    if [ -n "${FLINK_PROPERTIES}" ]; then
        echo "${FLINK_PROPERTIES}" >> "${CONF_FILE}"
    fi

    echo "config file: " && grep '^[^\n#]' "${CONF_FILE}"
    $(drop_privs_cmd) "$FLINK_HOME/bin/taskmanager.sh" start
    while true;
     do
        if [[ -f $(find log -name '*taskmanager*.log' -print -quit) ]]; then
           tail -f -n +1 /opt/flink/log/*/*taskmanager*.log;
        fi;
    done
fi

exec "$@"
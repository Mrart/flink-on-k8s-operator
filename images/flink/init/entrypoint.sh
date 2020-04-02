#!/usr/bin/env bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A wrapper around the Flink base image's entrypoint with additional setups.

set -x

echo "Flink entrypoint..."

FLINK_CONF_FILE="${FLINK_HOME}/conf/flink-conf.yaml"

# Derive the default jobmanager/taskmanager heap size based on the container's
# memory limit. They could be overriden by FLINK_PROPERTIES.
if [[ -n "${JOB_MANAGER_MEMORY_LIMIT}" ]]; then
  echo "JobManager memory limit: ${JOB_MANAGER_MEMORY_LIMIT}Mi"
  echo "# Derived from JOB_MANAGER_MEMORY_LIMIT" >>${FLINK_CONF_FILE}
  echo "jobmanager.heap.size: ${JOB_MANAGER_MEMORY_LIMIT}m" >>${FLINK_CONF_FILE}
fi
if [[ -n "${TASK_MANAGER_MEMORY_LIMIT}" ]]; then
  echo "TaskManager memory limit: ${TASK_MANAGER_MEMORY_LIMIT}Mi"
  echo "# Derived from TASK_MANAGER_MEMORY_LIMIT" >>${FLINK_CONF_FILE}
  echo "taskmanager.heap.size: ${TASK_MANAGER_MEMORY_LIMIT}m" >>${FLINK_CONF_FILE}
fi

# Add user-provided properties to Flink config.
# FLINK_PROPERTIES is a multi-line string of "<key>: <value>".
if [[ -n "${FLINK_PROPERTIES}" ]]; then
  echo "Appending Flink properties to ${FLINK_CONF_FILE}: ${FLINK_PROPERTIES}"
  echo "" >>${FLINK_CONF_FILE}
  echo "# Extra properties." >>${FLINK_CONF_FILE}
  echo "${FLINK_PROPERTIES}" >>${FLINK_CONF_FILE}
fi

mkdir -p ${FLINK_HOME}/job
chmod 777 ${FLINK_HOME}/job -R
chown sloth:sloth -R /opt/flink/job

# Download remote classpath file.
if [[ -n "${FLINK_JOB_FILES_URI}" ]]; then
  files=(${FLINK_JOB_FILES_URI//,/ })
  for file in ${files[@]}
  do
  echo "Downloading job JAR ${file} to ${FLINK_HOME}/job/"
  if [[ "${file}" == hdfs://* ]]; then
    su - sloth -c "export JAVA_HOME=/usr/local/openjdk-8 && /opt/hdfs_client/bin/hadoop dfs -copyToLocal $file ${FLINK_HOME}/job/"
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
  mkdir -p ${FLINK_HOME}/job
  echo "Downloading job JAR ${FLINK_JOB_JAR_URI} to ${FLINK_HOME}/job/"
  if [[ "${FLINK_JOB_JAR_URI}" == hdfs://* ]]; then
     su - sloth -c "export JAVA_HOME=/usr/local/openjdk-8 && /opt/hdfs_client/bin/hadoop dfs -copyToLocal $FLINK_JOB_JAR_URI ${FLINK_HOME}/job/"
  elif [[ "${FLINK_JOB_JAR_URI}" == http://* || "${FLINK_JOB_JAR_URI}" == https://* ]]; then
    wget -nv -P "${FLINK_HOME}/job/" "${FLINK_JOB_JAR_URI}"
  else
    echo "Unsupported protocol for ${FLINK_JOB_JAR_URI}"
    exit 1
  fi
fi

exit 0

# Handover to Flink base image's entrypoint.
exec "/docker-entrypoint.sh" "$@"
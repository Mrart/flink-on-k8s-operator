/*
Copyright 2019 Google LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	"testing"

	"gotest.tools/assert"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Tests default values are set as expected.
func TestSetDefault(t *testing.T) {
	var cluster = FlinkCluster{
		Spec: FlinkClusterSpec{
			Job: &JobSpec{},
			JobManager: JobManagerSpec{
				Ingress: &JobManagerIngressSpec{},
			},
		},
	}
	_SetDefault(&cluster)

	var defaultJmReplicas = int32(1)
	var defaultJmRPCPort = int32(6123)
	var defaultJmBlobPort = int32(6124)
	var defaultJmQueryPort = int32(6125)
	var defaultJmUIPort = int32(8081)
	var defaultTmDataPort = int32(6121)
	var defaultTmRPCPort = int32(6122)
	var defaultTmQueryPort = int32(6125)
	var defaultJobAllowNonRestoredState = false
	var defaultJobParallelism = int32(1)
	var defaultJobNoLoggingToStdout = false
	var defaultJobRestartPolicy = corev1.RestartPolicy("OnFailure")
	var defatulJobManagerIngressTLSUse = false
	var expectedCluster = FlinkCluster{
		TypeMeta:   metav1.TypeMeta{},
		ObjectMeta: metav1.ObjectMeta{},
		Spec: FlinkClusterSpec{
			Image: ImageSpec{
				Name:        "",
				PullPolicy:  "Always",
				PullSecrets: nil,
			},
			JobManager: JobManagerSpec{
				Replicas:    &defaultJmReplicas,
				AccessScope: "Cluster",
				Ingress: &JobManagerIngressSpec{
					UseTLS: &defatulJobManagerIngressTLSUse,
				},
				Ports: JobManagerPorts{
					RPC:   &defaultJmRPCPort,
					Blob:  &defaultJmBlobPort,
					Query: &defaultJmQueryPort,
					UI:    &defaultJmUIPort,
				},
				Resources: corev1.ResourceRequirements{},
				Volumes:   nil,
				Mounts:    nil,
			},
			TaskManager: TaskManagerSpec{
				Replicas: 0,
				Ports: TaskManagerPorts{
					Data:  &defaultTmDataPort,
					RPC:   &defaultTmRPCPort,
					Query: &defaultTmQueryPort,
				},
				Resources: corev1.ResourceRequirements{},
				Volumes:   nil,
			},
			Job: &JobSpec{
				AllowNonRestoredState: &defaultJobAllowNonRestoredState,
				Parallelism:           &defaultJobParallelism,
				NoLoggingToStdout:     &defaultJobNoLoggingToStdout,
				RestartPolicy:         &defaultJobRestartPolicy,
				CleanupPolicy: &CleanupPolicy{
					AfterJobSucceeds: "DeleteCluster", AfterJobFails: "KeepCluster",
				},
			},
			FlinkProperties: nil,
			EnvVars:         nil,
		},
		Status: FlinkClusterStatus{},
	}

	assert.DeepEqual(t, cluster, expectedCluster)
}

// Tests non-default values are not overwritten unexpectedly.
func TestSetNonDefault(t *testing.T) {
	var jmReplicas = int32(2)
	var jmRPCPort = int32(8123)
	var jmBlobPort = int32(8124)
	var jmQueryPort = int32(8125)
	var jmUIPort = int32(9081)
	var tmDataPort = int32(8121)
	var tmRPCPort = int32(8122)
	var tmQueryPort = int32(8125)
	var jobAllowNonRestoredState = true
	var jobParallelism = int32(2)
	var jobNoLoggingToStdout = true
	var jobRestartPolicy = corev1.RestartPolicy("Never")
	var jobManagerIngressTLSUse = true
	var cluster = FlinkCluster{
		TypeMeta:   metav1.TypeMeta{},
		ObjectMeta: metav1.ObjectMeta{},
		Spec: FlinkClusterSpec{
			Image: ImageSpec{
				Name:        "",
				PullPolicy:  "Always",
				PullSecrets: nil,
			},
			JobManager: JobManagerSpec{
				Replicas:    &jmReplicas,
				AccessScope: "Cluster",
				Ingress: &JobManagerIngressSpec{
					UseTLS: &jobManagerIngressTLSUse,
				},
				Ports: JobManagerPorts{
					RPC:   &jmRPCPort,
					Blob:  &jmBlobPort,
					Query: &jmQueryPort,
					UI:    &jmUIPort,
				},
				Resources: corev1.ResourceRequirements{},
				Volumes:   nil,
				Mounts:    nil,
			},
			TaskManager: TaskManagerSpec{
				Replicas: 0,
				Ports: TaskManagerPorts{
					Data:  &tmDataPort,
					RPC:   &tmRPCPort,
					Query: &tmQueryPort,
				},
				Resources: corev1.ResourceRequirements{},
				Volumes:   nil,
			},
			Job: &JobSpec{
				AllowNonRestoredState: &jobAllowNonRestoredState,
				Parallelism:           &jobParallelism,
				NoLoggingToStdout:     &jobNoLoggingToStdout,
				RestartPolicy:         &jobRestartPolicy,
				CleanupPolicy: &CleanupPolicy{
					AfterJobSucceeds: "DeleteTaskManagers",
					AfterJobFails:    "DeleteCluster",
				},
			},
			FlinkProperties: nil,
			EnvVars:         nil,
		},
		Status: FlinkClusterStatus{},
	}

	_SetDefault(&cluster)

	var expectedCluster = FlinkCluster{
		TypeMeta:   metav1.TypeMeta{},
		ObjectMeta: metav1.ObjectMeta{},
		Spec: FlinkClusterSpec{
			Image: ImageSpec{
				Name:        "",
				PullPolicy:  "Always",
				PullSecrets: nil,
			},
			JobManager: JobManagerSpec{
				Replicas:    &jmReplicas,
				AccessScope: "Cluster",
				Ingress: &JobManagerIngressSpec{
					UseTLS: &jobManagerIngressTLSUse,
				},
				Ports: JobManagerPorts{
					RPC:   &jmRPCPort,
					Blob:  &jmBlobPort,
					Query: &jmQueryPort,
					UI:    &jmUIPort,
				},
				Resources: corev1.ResourceRequirements{},
				Volumes:   nil,
				Mounts:    nil,
			},
			TaskManager: TaskManagerSpec{
				Replicas: 0,
				Ports: TaskManagerPorts{
					Data:  &tmDataPort,
					RPC:   &tmRPCPort,
					Query: &tmQueryPort,
				},
				Resources: corev1.ResourceRequirements{},
				Volumes:   nil,
			},
			Job: &JobSpec{
				AllowNonRestoredState: &jobAllowNonRestoredState,
				Parallelism:           &jobParallelism,
				NoLoggingToStdout:     &jobNoLoggingToStdout,
				RestartPolicy:         &jobRestartPolicy,
				CleanupPolicy: &CleanupPolicy{
					AfterJobSucceeds: "DeleteTaskManagers",
					AfterJobFails:    "DeleteCluster",
				},
			},
			FlinkProperties: nil,
			EnvVars:         nil,
		},
		Status: FlinkClusterStatus{},
	}

	assert.DeepEqual(t, cluster, expectedCluster)
}

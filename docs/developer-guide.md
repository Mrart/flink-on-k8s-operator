# Developer Guide

## Project overview

[Kubernetes](https://kubernetes.io/) Operator for [Apache Flink](https://flink.apache.org)
is built on top of the Kubernetes [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
library. The project structure and boilerplate files are generated with
[Kubebuilder](https://github.com/kubernetes-sigs/kubebuilder). Knowledge of
controller-runtime and Kubebuilder is required to understand this project.

The Flink custom resource is defined in Go struct [FlinkCluster](../api/v1alpha1/flinkcluster_types.go),
then Kubebuild generates related Go files and YAML files, e.g.
[flinkclusters.yaml](../config/crd/bases/flinkoperator.k8s.io_flinkclusters.yaml).
The custom logic for reconciling a Flink custom resource is inside of the
[controllers](../controllers) directory, e.g., [flinkcluster_controller.go](../controllers/flinkcluster_controller.go).

[Dockerfile](../Dockerfile) defines the steps of building the Flink Operator
image.

[Makefile](../Makefile) includes various actions you can take to generate
code, build the Flink Operator binary, run unit tests, build and push docker
image, deploy the Flink Operator to a Kubernetes cluster.

## Dependencies

The following dependencies are required to build the Flink Operator binary and
run unit tests:

* [Go v1.12+](https://golang.org/)
* [Kubebuilder v2+](https://github.com/kubernetes-sigs/kubebuilder)

But you don't have to install them on your local machine, because this project
includes a [builder Docker image](../Dockerfile.builder) with the dependencies
installed. Build and unit test can happen inside of the builder container. This
is the recommended way for local development.

But to create the Flink Operator Docker image and deploy it to a Kubernetes
cluster, the following dependencies are required on you local machine:

* [Docker](https://www.docker.com/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Kustomize v3.1+](https://github.com/kubernetes-sigs/kustomize)

## Local build and test

To build the Flink Operator binary and run unit tests, run

### In Docker (recommended)

```bash
make test-in-docker
```

### Non-Docker (not recommended)

```bash
make test
```

## Build and push docker image

Build a Docker image for the Flink Operator and then push it to an image
registry with

```bash
make operator-image push-operator-image IMG=<tag>
```

Depending on which image registry you want to use, choose a tag accordingly,
e.g., if you are using [Google Container Registry](https://cloud.google.com/container-registry/docs/)
you want to use a tag like `gcr.io/<project>/flink-operator:latest`.

After building the image, it automatically saves the image tag in
`config/default/manager_image_patch.yaml`, so that when you deploy the Flink
operator later, it knows what image to use.

## Deploy the operator to a running Kubernetes cluster

Assume you have built and pushed the Flink Operator image, then you need to have
a running Kubernetes cluster. Verify the cluster info with

```bash
kubectl cluster-info
```

Deploy the Flink Custom Resource Definitions and the Flink Operator to the
cluster with

```bash
make deploy
```

After that, you can verify CRD `flinkclusters.flinkoperator.k8s.io` has been
created with

```bash
kubectl get crds | grep flinkclusters.flinkoperator.k8s.io
```

You can also view the details of the CRD with

```bash
kubectl describe crds/flinkclusters.flinkoperator.k8s.io
```

The operator runs as a Kubernetes Deployment, you can find out the deployment
with

```bash
kubectl get deployments -n flink-operator-system
```

or verify the operator pod is up and running.

```bash
kubectl get pods -n flink-operator-system
```

You can also check the operator logs with

```bash
kubectl logs -n flink-operator-system -l app=flink-operator --all-containers
```

## Create a sample Flink cluster

After deploying the Flink CRDs and the Flink Operator to a Kubernetes cluster,
the operator serves as a control plane for Flink. In other words, previously the
cluster only understands the language of Kubernetes, now it understands the
language of Flink. You can then create custom resources representing Flink
session clusters or job clusters, the operator will detect the custom resources
automatically, then create the actual clusters optionally run jobs, and update
status in the custom resources.

Create a [sample Flink session cluster](../config/samples/flinkoperator_v1alpha1_flinksessioncluster.yaml)
custom resource with

```bash
kubectl apply -f config/samples/flinkoperator_v1alpha1_flinksessioncluster.yaml
```

and a [sample Flink job cluster](../config/samples/flinkoperator_v1alpha1_flinkjobcluster.yaml)
custom resource with

```bash
kubectl apply -f config/samples/flinkoperator_v1alpha1_flinkjobcluster.yaml
```

## Submit a job

There are several ways to submit jobs to a session cluster.

1) **Flink web UI**

You can submit jobs through the Flink web UI. See instructions in the
Monitoring section on how to setup a proxy to the Flink Web UI.

2) **From within the cluster**

You can submit jobs through a client Pod in the same cluster, for example:

```bash
kubectl run my-job-submitter --image=flink:1.8.1 --generator=run-pod/v1 -- \
    /opt/flink/bin/flink run -m flinksessioncluster-sample-jobmanager:8081 \
    /opt/flink/examples/batch/WordCount.jar --input /opt/flink/README.txt
```

3) **From outside the cluster**

If you have configured the access scope of JobManager as `External` or `VPC`,
you can submit jobs from a machine which is in the scope, for example:

```bash
flink run -m <jobmanager-service-ip>:8081 \
    examples/batch/WordCount.jar --input /opt/flink/README.txt
```

Or if the access scope is `Cluster` which is the default, you can use port
forwarding to establish a tunnel from a machine which has access to the
Kubernetes API service (typically your local machine) to the JobManager service
first, for example:

```bash
kubectl port-forward service/flinksessioncluster-sample-jobmanager 8081:8081
```

then submit jobs through the tunnel, for example:

```bash
flink run -m localhost:8081 \
    examples/batch/WordCount.jar --input ./README.txt
```

## Monitoring

### Operator

You can check the operator logs with

```bash
kubectl logs -n flink-operator-system -l app=flink-operator --all-containers -f --tail=1000
```

### Flink cluster

After deploying a Flink cluster with the operator, you can find the cluster
custom resource with

```bash
kubectl get flinkclusters
```

check the cluster status with

```bash
kubectl describe flinkclusters <CLUSTER-NAME>
```

### Flink job

In a job cluster, the job is automatically submitted by the operator you can
check the Flink job status and logs with

```bash
kubectl describe jobs <CLUSTER-NAME>-job
kubectl logs jobs/<CLUSTER-NAME>-job -f --tail=1000
```

In a session cluster, depending on how you submit the job, you can check the
job status and logs accordingly.

### Flink web UI

You can also access the Flink web UI via a proxy, run the following command in a
terminal

```bash
kubectl proxy
```

then navigate to

```
http://localhost:8001/api/v1/namespaces/default/services/<CLUSTER-NAME>-jobmanager:ui/proxy
```

in your browser.

## Undeploy the operator

Undeploy the operator and CRDs from the Kubernetes cluster with

```
make undeploy
```

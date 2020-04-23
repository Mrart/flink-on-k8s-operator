include properties

all: build

# Build the docker image
build:
	docker build . \
		-t ${IMAGE_TAG} \
		--build-arg FLINK_VERSION=${FLINK_VERSION} \
		--build-arg SCALA_VERSION=${SCALA_VERSION} \
		--build-arg HADOOP_CONF_DIR=${HADOOP_CONF_DIR}

# Push the docker image
push:
	docker push ${IMAGE_TAG}
include properties

all: build

# Build the docker image
build:
	docker build . \
		-t ${IMAGE_TAG} \
		--build-arg HADOOP_CONF_DIR=${HADOOP_CONF_DIR}

# Push the docker image
push:
	docker push ${IMAGE_TAG}

PYTHON_VERSION=3.10
PYTHON=$(shell type -p python${PYTHON_VERSION})
GIT_VERSION=$(shell git rev-parse HEAD | cut -c1-12)
GCLOUD=$(shell which gcloud)
PWD=$(shell pwd)
APP_NAME='name-here'
APP_MODULES=$(shell find gae_bundle -mindepth 1 -maxdepth 1 -type d)
IMAGE_NAME=test
DEV_IMAGE_NAME=$(IMAGE_NAME)_$(GIT_VERSION)
CONTAINER_NAME=$(IMAGE_NAME)_DEV
MAJOR_LEVEL=0
MINOR_LEVEL=0
PATCH_LEVEL=1
REPO_PATH=ghcr.io/outs-me

init:
	#First time Devs run this.
	@echo checking for ${GCLOUD}
	@if [ ! -x "${GCLOUD}" ]; then curl https://sdk.cloud.google.com | sudo bash ; \
	gcloud components update ; \
	gcloud init ; \
	fi

release: setproject
	#Dumps application code direct to prod, side stepping CI
	#bash circle.sh - eventually will hold same code as circleCI

	# This target pushes the project into production. Confirmation or warning is preferred, should be “yesable”
	# gcloud components update -q
	#appcfg.py --version=${GIT_VERSION} -A $(APP) update $(APP_MODULES) gae_bundle/dispatch.yaml
	gcloud app deploy default/app.yaml --project $(APP_NAME) --version $(GIT_VERSION) --verbosity info
	gcloud app deploy default/cron.yaml --project $(APP_NAME) --version $(GIT_VERSION) --verbosity info
	
	# remove unused indexes
	gcloud datastore indexes cleanup index.yaml --project $(APP_NAME) --quiet --verbosity info
	# updates indexes
	gcloud datastore indexes create index.yaml --project $(APP_NAME) --quiet --verbosity info


setproject:
	# If you have multiple auth accounts, you may also need to run gcloud auth login email@domain.com
	gcloud config set project $(APP_NAME)

.PHONY: clean
clean:
	docker stop ${CONTAINER_NAME} || true
	docker rm ${CONTAINER_NAME} || true

clean-image:
	docker rmi ${DEV_IMAGE_NAME} || true

.PHONY: dev
dev: build-image
	@echo "created image ${IMAGE_NAME}"
	# https://cloud.google.com/run/docs/testing/local#gcloud-cli
	gcloud beta code dev

# https://cloud.google.com/run/docs/testing/local#gcloud-cli
.PHONY: dev-cloudrun
dev-cloudrun:
	gcloud beta code dev

.PHONY: build-image
build-image: clean clean-image
	docker build -t ${DEV_IMAGE_NAME} .


.PHONY: push-image
push-image: build-image
	docker tag ${DEV_IMAGE_NAME} ${IMAGE_NAME}
	docker tag ${DEV_IMAGE_NAME} ${REPO_PATH}/${IMAGE_NAME}
	docker tag ${DEV_IMAGE_NAME} ${REPO_PATH}/${IMAGE_NAME}:${MAJOR_LEVEL}
	docker tag ${DEV_IMAGE_NAME} ${REPO_PATH}/${IMAGE_NAME}:${MAJOR_LEVEL}.${MINOR_LEVEL}
	docker tag ${DEV_IMAGE_NAME} ${REPO_PATH}/${IMAGE_NAME}:${MAJOR_LEVEL}.${MINOR_LEVEL}.${PATCH_LEVEL}
	docker push ${REPO_PATH}/${IMAGE_NAME}
	docker push ${REPO_PATH}/${IMAGE_NAME}:${MAJOR_LEVEL}
	docker push ${REPO_PATH}/${IMAGE_NAME}:${MAJOR_LEVEL}.${MINOR_LEVEL}
	docker push ${REPO_PATH}/${IMAGE_NAME}:${MAJOR_LEVEL}.${MINOR_LEVEL}.${PATCH_LEVEL}


.PHONY: run-container
run-container: clean
	docker run --name ${CONTAINER_NAME} --privileged -it ${DEV_IMAGE_NAME} /bin/bash

.PHONY: create
create:
	docker create ${DEV_IMAGE_NAME}

.PHONY: test
test:
	@echo "test should happen"

.PHONY: fmt
fmt:
	black .

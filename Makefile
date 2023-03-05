APP_NAME='name-here'
PYTHON_VERSION=3.10
PYTHON=$(shell type -p python${PYTHON_VERSION})
BUILD_VERSION=$(shell git rev-parse HEAD | cut -c1-12)
GCLOUD_INSTALLED=$(shell which gcloud)
BREW_INSTALLED := $(shell brew --version 2>/dev/null)
PRECOMMIT_INSTALLED := $(shell pre-commit --version 2>/dev/null)
PWD=$(shell pwd)
IMAGE_NAME=$(APP_NAME)
DEV_IMAGE_NAME=$(IMAGE_NAME)_$(BUILD_VERSION)
DEV_CONTAINER_NAME=$(IMAGE_NAME)_DEV
MAJOR_LEVEL=0
MINOR_LEVEL=0
PATCH_LEVEL=1
REPO_PATH=ghcr.io/outs-me

ifdef BREW_INSTALLED
install_brew:
	@echo "brew is already installed, doing nothing." $(DEVNULL)
else
install_brew:
	@echo "brew is NOT installed. Installing..." $(DEVNULL)
	$(Q)/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" $(DEVNULL)
	@brew --version $(DEVNULL) || { echo "Failed to install brew! Aborting."; exit 1; }
endif

ifdef PRECOMMIT_INSTALLED
install_precommit:
	@echo "pre-commit is already installed." $(DEVNULL)
	$(Q)pre-commit install $(DEVNULL)
else
install_precommit: install_brew
	@echo "pre-commit is NOT installed. Installing..." $(DEVNULL)
	$(Q)brew install pre-commit $(DEVNULL)
	@pre-commit --version $(DEVNULL) || { echo "Failed to install pre-commit! Aborting."; exit 1; }
	$(Q)pre-commit install $(DEVNULL)
endif

ifdef GCLOUD_INSTALLED
install_gcloud:
	@echo "gcloud is already installed." $(DEVNULL)
else
install_gcloud:
	@echo "gcloud is NOT installed. Installing..." $(DEVNULL)
	@if [ ! -x "${GCLOUD_INSTALLED}" ]; then curl https://sdk.cloud.google.com | sudo bash ; \
	gcloud components update ; \
	gcloud init ; \
	fi
endif

ifdef SHELLCHECK_INSTALLED
install_shellcheck:
	@echo "shellcheck is already installed." $(DEVNULL)
else
install_shellcheck:
	@echo "shellcheck is NOT installed. Installing..." $(DEVNULL)
	brew install shellcheck
endif

init: install_brew install_precommit install_gcloud install_shellcheck
	@echo "${APP_NAME} init complete"


release: setproject
	gcloud run deploy


setproject:
	# If you have multiple auth accounts, you may also need to run gcloud auth login email@domain.com
	gcloud config set project $(APP_NAME)

.PHONY: clean
clean:
	docker stop ${DEV_CONTAINER_NAME} || true
	docker rm ${DEV_CONTAINER_NAME} || true

clean-image:
	docker rmi ${DEV_IMAGE_NAME} || true

.PHONY: dev
dev: build-image run-container
	@echo "created image ${IMAGE_NAME}"

# https://cloud.google.com/run/docs/testing/local#docker-with-google-cloud-access
.PHONY: dev-cloudrun
dev-cloudrun:
	# https://cloud.google.com/sdk/gcloud/reference/beta/code/dev
	gcloud beta code dev --application-default-credential


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
	docker run --name ${DEV_CONTAINER_NAME} --privileged -it ${DEV_IMAGE_NAME} /bin/bash

.PHONY: create
create:
	docker create ${DEV_IMAGE_NAME}

.PHONY: test
test:
	@echo "test should happen"

.PHONY: fmt
fmt:
	black .

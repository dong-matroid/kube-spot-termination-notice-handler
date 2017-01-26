KUBE_VERSION ?= 1.4.0
VERSION ?= 0.9.0
REPOSITORY ?= matroid/kube-spot-termination-notice-handler
TAG ?= $(KUBE_VERSION)-$(VERSION)
IMAGE ?= $(REPOSITORY):$(TAG)
ALIAS ?= 840259429537.dkr.ecr.us-west-2.amazonaws.com/matroid:kube-spot-termination-notice-handler-v$(KUBE_VERSION)
BUILD_ROOT ?= build/$(TAG)
DOCKERFILE ?= $(BUILD_ROOT)/Dockerfile
ENTRYPOINT ?= $(BUILD_ROOT)/entrypoint.sh
DOCKER_CACHE ?= docker-cache

cross-build:
	for v in 1.2.{5..6} 1.3.{0..3}; do\
	  KUBE_VERSION=$$v sh -c 'echo Building am image targeting k8s $$KUBECTL_VERSION';\
	  KUBE_VERSION=$$v make build ;\
	done

cross-push:
	for v in 1.2.{5..6} 1.3.{0..3}; do\
	  KUBE_VERSION=$$v sh -c 'echo Pushing an image targeting k8s $$KUBECTL_VERSION';\
	  KUBE_VERSION=$$v make publish ;\
	done

clean-all:
	for v in 1.2.{5..6} 1.3.{0..3}; do\
	  KUBE_VERSION=$$v sh -c 'echo Cleaning assets targeting k8s $$KUBECTL_VERSION';\
	  KUBE_VERSION=$$v make clean ;\
	done

.PHONY: build
build: $(DOCKERFILE) $(ENTRYPOINT)
	cd $(BUILD_ROOT) && docker build -t $(IMAGE) . && docker tag $(IMAGE) $(ALIAS)

publish:
	docker push $(ALIAS)

clean:
	rm -Rf $(BUILD_ROOT)

$(DOCKERFILE): $(BUILD_ROOT)
	sed 's/%%KUBE_VERSION%%/'"$(KUBE_VERSION)"'/g;' Dockerfile.template > $(DOCKERFILE)

$(ENTRYPOINT): $(BUILD_ROOT)
	cp entrypoint.sh $(ENTRYPOINT)

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

travis-env:
	travis env set DOCKER_EMAIL $(DOCKER_EMAIL)
	travis env set DOCKER_USERNAME $(DOCKER_USERNAME)
	travis env set DOCKER_PASSWORD $(DOCKER_PASSWORD)

test:
	@echo There are no tests available for now. Skipping

save-docker-cache: $(DOCKER_CACHE)
	docker save $(IMAGE) $(shell docker history -q $(IMAGE) | tail -n +2 | grep -v \<missing\> | tr '\n' ' ') > $(DOCKER_CACHE)/image-$(KUBE_VERSION).tar
	ls -lah $(DOCKER_CACHE)

load-docker-cache: $(DOCKER_CACHE)
	if [ -e $(DOCKER_CACHE)/image-$(KUBE_VERSION).tar ]; then docker load < $(DOCKER_CACHE)/image-$(KUBE_VERSION).tar; fi

$(DOCKER_CACHE):
	mkdir -p $(DOCKER_CACHE)

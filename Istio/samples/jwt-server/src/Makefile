HUB ?= docker.io/istio/jwt-server
TAG ?= 0.5

build: main.go Dockerfile
	docker build . -t $(HUB):$(TAG)

push: build
	docker push $(HUB):$(TAG)

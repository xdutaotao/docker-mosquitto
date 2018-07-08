DOCKER=docker
REPOSITORY?=jsdoitao/mosquitto
TAG?=v1.4.11-opt

all:
	@echo "Mosquitto version: ${TAG}"
	@echo ""
	@echo "Commands:"
	@echo "  make image : build the mosquitto image"

image:
	@echo "Building mosquitto image"
	${DOCKER} build --no-cache -t ${REPOSITORY}:${TAG} .


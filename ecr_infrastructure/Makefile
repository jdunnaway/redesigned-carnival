SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SHELLFLAGS = -uec
.PHONY: deploy

default:
	echo "No make target"

plan:
	terraform plan

login-ecr:
	aws ecr get-login-password --region us-east-1 \
   | docker login --username AWS --password-stdin \
   ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com

push-image:
	pushd ../app
	docker build -t container-demo .
	docker tag container-demo:latest ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/lambda-container-demo-repo:latest
	docker push ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/lambda-container-demo-repo:latest
	popd

deploy-infrastructure:
	terraform apply -auto-approve
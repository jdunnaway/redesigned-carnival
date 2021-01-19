SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SHELLFLAGS = -uec
.PHONY: deploy

default:
	echo "No make target"

login-ecr:
	aws ecr get-login-password --region us-east-1 \
   | docker login --username AWS --password-stdin \
   ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com

deploy:
	terraform apply -auto-approve
.ONESHELL:
SHELL = /bin/bash

lint:


hugo-server:
	hugo server -s website

hugo-build:
	hugo --minify -s website

terraform-lint:
	@cd terraform
	terraform fmt
	tflint

terraform-init:
	@cd terraform
	@[[ -d .terraform ]] || terraform init

terraform-plan: terraform-init
	@cd terraform
	export TF_LOG=debug
	terraform plan

AUTO = false
terraform-apply: terraform-init
	@cd terraform
	terraform apply -auto-approve=$(AUTO)

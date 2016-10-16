ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
STACK_NAME:=aws-ci-demo
LOCAL_TEMPLATE_URL:=file://$(ROOT_DIR)/cfn/ci_demo.template

deploy:
	test -n "$(GITHUB_OAUTH_TOKEN)" # you must set $$GITHUB_OAUTH_TOKEN before running this script
	aws cloudformation create-stack --stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_IAM \
		--template-body $(LOCAL_TEMPLATE_URL) \
		--parameters ParameterKey=GitHubToken,ParameterValue=$(GITHUB_OAUTH_TOKEN)

validate-cfn:
	aws cloudformation validate-template --template-body $(LOCAL_TEMPLATE_URL)

clean-aws:
	test -n "$(AWS_CI_DEMO_DELETE_OK)" # you must set $$AWS_CI_DEMO_DELETE_OK to confirm that you want to delete all AWS resources
	aws cloudformation delete-stack --stack-name $(STACK_NAME)

.PHONY: deploy validate-cfn clean-aws

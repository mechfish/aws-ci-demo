ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
LOCAL_TEMPLATE_URL:=file://$(ROOT_DIR)/cfn/ci_demo.template

# Any of these can be overridden by environment variables.
STACK_NAME?=aws-ci-demo
APP_NAME?=a4tp
GITHUB_USERNAME?=mechfish
GITHUB_REPO_NAME?=aws-ci-demo
GITHUB_BRANCH_NAME?=master

provision:
	test -n "$(GITHUB_OAUTH_TOKEN)" # you must set $$GITHUB_OAUTH_TOKEN before running this script
	test -n "$(AWS_EC2_KEYNAME)" # you must set $$AWS_EC2_KEYNAME before running this script
	@echo "Creating CloudFormation stack $(STACK_NAME)"
	@aws cloudformation create-stack --stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_IAM \
		--template-body $(LOCAL_TEMPLATE_URL) \
		--parameters ParameterKey=AppName,ParameterValue=$(APP_NAME) \
			ParameterKey=GitHubToken,ParameterValue=$(GITHUB_OAUTH_TOKEN) \
			ParameterKey=GitHubUser,ParameterValue=$(GITHUB_USERNAME) \
			ParameterKey=GitHubRepoName,ParameterValue=$(GITHUB_REPO_NAME) \
			ParameterKey=GitHubBranchName,ParameterValue=$(GITHUB_BRANCH_NAME) \
			ParameterKey=KeyName,ParameterValue=$(AWS_EC2_KEYNAME)
	@echo "Waiting for stack $(STACK_NAME) to reach CREATE_COMPLETE status"
	@echo "Visit https://console.aws.amazon.com/cloudformation/home to monitor the stack event stream."
	@aws cloudformation wait stack-create-complete --stack-name $(STACK_NAME)

update-ci:
	test -n "$(GITHUB_OAUTH_TOKEN)" # you must set $$GITHUB_OAUTH_TOKEN before running this script
	test -n "$(AWS_EC2_KEYNAME)" # you must set $$AWS_EC2_KEYNAME before running this script
	@echo "Updating CloudFormation stack $(STACK_NAME)"
	@aws cloudformation update-stack --stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_IAM \
		--template-body $(LOCAL_TEMPLATE_URL) \
		--parameters ParameterKey=AppName,ParameterValue=$(APP_NAME) \
			ParameterKey=GitHubToken,ParameterValue=$(GITHUB_OAUTH_TOKEN) \
			ParameterKey=GitHubUser,ParameterValue=$(GITHUB_USERNAME) \
			ParameterKey=GitHubRepoName,ParameterValue=$(GITHUB_REPO_NAME) \
			ParameterKey=GitHubBranchName,ParameterValue=$(GITHUB_BRANCH_NAME) \
			ParameterKey=KeyName,ParameterValue=$(AWS_EC2_KEYNAME)
	@echo "Waiting for stack $(STACK_NAME) to reach UPDATE_COMPLETE status"
	@echo "Visit https://console.aws.amazon.com/cloudformation/home to monitor the stack event stream."
	@aws cloudformation wait stack-update-complete --stack-name $(STACK_NAME)

validate-cfn:
	aws cloudformation validate-template --template-body $(LOCAL_TEMPLATE_URL)

teardown:
	@test -n "$(AWS_CI_DEMO_TEARDOWN_OK)" # you must set $$AWS_CI_DEMO_TEARDOWN_OK to confirm that you want to delete all AWS resources
	aws cloudformation delete-stack --stack-name $(STACK_NAME)

.PHONY: provision validate-cfn teardown

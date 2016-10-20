# Terminate the app and all its infrastructure except the S3 bucket
#
# The user will be interactively prompted to make very sure they want to do
# this.
#
# TODO: This file contains a bunch of copypasta from provision.py; it
# could use some refactoring into a library.
from __future__ import print_function

import os
import sys

import boto3
import botocore

def aws_region():
    return botocore.session.Session().get_config_variable('region')

def aws_account_id():
    try:
        return boto3.client('iam').get_user()['User']['Arn'].split(':')[4]
    except:
        print("Unable to retrieve AWS account ID")
        sys.exit(1)

def stack_exists(cf, stack):
    try:
        cf.describe_stacks(StackName=stack)
        return True
    except botocore.exceptions.ClientError as e:
        if "does not exist" in e.response['Error']['Message']:
            return False
        else:
            raise e

def get_stack_outputs(cf, stack):
    desc = cf.describe_stacks(StackName=stack)
    try:
        return { o['OutputKey']: o['OutputValue'] for o in desc['Stacks'][0]['Outputs'] }
    except KeyError:
        return {}

def terminate_stack(cf, stack):
    cf.delete_stack(StackName=stack)
    waiter = cf.get_waiter('stack_delete_complete')
    waiter.wait(StackName=stack)

def user_wants_terminate():
    print("Are you sure you want to terminate the app and all its AWS resources?")
    ok = raw_input("Enter 'yes' to terminate:")
    return (ok == 'yes')

if __name__ == "__main__":
    if not user_wants_terminate():
        sys.exit(0)

    cf = boto3.client('cloudformation')

    app_name = os.getenv('APP_NAME', 'a4tp')
    ci_stack_name = os.getenv('CI_STACK_NAME', app_name + "-ci")
    if stack_exists(cf, ci_stack_name):
        ci_outputs = get_stack_outputs(cf, ci_stack_name)
        try:
            web_stack = ci_outputs['WebStackName']
        except KeyError:
            print("Web stack not found")
            web_stack = None
        if web_stack is not None and stack_exists(cf, web_stack):
            print("Terminating stack " + web_stack)
            terminate_stack(cf, web_stack)
        print("Terminating stack " + ci_stack_name)
        terminate_stack(cf, ci_stack_name)
    else:
        print("CI stack not found")

# aws-ci-demo

An experiment in 100%-AWS-powered continuous integration using
CloudFormation, AutoScaling, CodePipeline, and Lambda.

## Important Safety Warning

**Don't run this in production** before scoping down the permissions.
  The `CodePipelineLambdaPolicy` is too broad -- it's an experiment,
  and I haven't had the time to tighten it down yet. Run this in a
  test account that does not contain mission-critical assets, then
  tear it down within a couple of hours.

  (See *Is This Ready For Production*, below, for more details and
  other caveats.)

## Design Principles

- "Immutable" infrastructure: Deploy new code by replacing whole
  instances.

- Use CloudFormation and AutoScaling groups to orchestrate the
  deployment.

- Use CodePipeline to manage CI. Try to get away
  without Jenkins by writing Lambda functions instead.

- Do real "builds". (In preparation for *fancier* static web pages
  with SASS, or something!)

- Build tests into health checks at instance launch time.

- Configure instances with "serverless" Ansible for easier development
  and container compatibility, and to lay the groundwork for Packer.

- Provide a Docker container for local development and/or unit tests.

## Prerequisites

- To launch the infrastructure you'll need Python 2.7 (preinstalled on
the Mac and many Linuxes, hooray!).

- You'll need the Boto3 AWS library for Python. To install this you
  need the Python package manager, `pip`. (If `pip -h` doesn't return
  anything, you can install `pip` using
  [its install docs](https://pip.pypa.io/en/stable/installing/).) Then
  run this in your shell:

  ```
  pip install boto3
  ```

  You may need to give yourself admin permissions (e.g. using `su` or
  `sudo`) to make this work on your laptop. (I do, because I'm one of
  those paranoid people.)

- You need to
  [configure your machine with AWS credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
  for a AWS user with administrator permissions. These credentials
  will be used to bootstrap the AWS infrastructure, but will not leave
  your local machine.

  You must also configure the AWS region to either `us-east-1` or
  `us-west-2` regions -- the others are not supported at this time.

  To configure my credentials, I just set the `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` environment
  variables, and that's how this project has been tested. But you
  should be able to install the AWS CLI and run `aws configure` to set
  these up, instead -- Boto3 should be able to work with that out of
  the box.

- You must
  [create an AWS keypair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)
  in your chosen region, in case you need to log in and debug your
  instances. Set the `AWS_EC2_KEYNAME` environment variable to the
  name of this keypair.

- You'll be deploying code from Github to AWS. To get a read/write
  copy of the code to deploy, fork this repository to your own Github
  account. Make a note of your account username and the name of the
  forked respository.

- AWS CodePipeline needs access to your Github account to deploy this
  project from Github. Generate a Github access token on the
  [https://github.com/settings/tokens](https://github.com/settings/tokens)
  page, giving it the `repo` and `admin:repo_hook` permissions. Copy
  the token into a safe place, like a password manager.

- The CI provisioning scripts get their configuration from environment
  variables. You can set these on the command line each time, or
  pre-configure the project by setting them in (for example)
  `~/.profile` or `~/.bashrc`, something like this:

```
export AWS_ACCESS_KEY_ID=your-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
export AWS_EC2_KEYNAME=your_ec2_keypair_name
export GITHUB_OAUTH_TOKEN=your_github_token
export GITHUB_USERNAME=your_github_username

# optionally, if you changed the repo name or branch name, uncomment
#and edit these defaults:
#export GITHUB_REPO_NAME=aws-cli-demo
#export GITHUB_BRANCH_NAME=master
```

## Installation

Clone this Git repository, `cd` into the working directory, and type:

```
python ci/bin/provision.py
```

If you haven't already configured environment variables, you may
need to prefix this command with their settings, e.g.:

```
GITHUB_OAUTH_TOKEN=abcd1234 GITHUB_USERNAME=mememe AWS_EC2_KEYNAME=my-keypair python ci/bin/provision.py
```

Two CloudFormation stacks will be created. The "CI" stack is built
first. It includes a CodePipeline setup which builds a second "web"
stack, and deploys a build of the site source to the web stack. The
`provision.py` script will wait for the web stack to appear. While
you're waiting, you can follow the stack event streams on the AWS
console.

When the launch succeeds, `provision.py` should exit by printing the
DNS name which you can use to access your web page!

**FIXME: cite typical timing **

## Teardown

When you get tired of this demo you can delete all of its CloudFormation
stacks with:

```
python ci/bin/terminate.py
```

You will be prompted to enter `yes` to make it harder to destroy your
running cloud application by accident.

## Lessons Learned

- So far I've found managing Lambda functions with CloudFormation to
  be somewhat annoying; edits to the function don't automatically
  trigger an update to the `AWS::Lambda::Function` resource. Maybe
  there's a trick?

## Is This Ready For Production?

- I would tighten the security before deploying this in
  production. Giving a Lambda function permission to manage (e.g.) IAM
  roles is too risky -- the Lambda runs code from Github, so anyone
  with Github commit permissions can take over your AWS account.

  I'd consider separating the CloudFormation stack into a
  networking-and-IAM stack and a web-infrastruture stack, point the
  continuous-release process only at the latter, and build a separate
  release procedure for (more rarely-changing) IAM and firewalls which
  required different, more tightly controlled creds.


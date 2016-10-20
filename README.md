# aws-ci-demo

An experiment in pure-AWS continuous integration using
CloudFormation, AutoScaling, CodePipeline, and Lambda.

We just deploy a simple static web page. (For now.)

## Warning

**Don't run this in production** before scoping down the permissions:
  The `CodePipelineLambdaPolicy` is too broad -- it's an experiment,
  and I just haven't had the time to tighten it yet. You can run this
  in a test account with unimportant assets, then tear it down within
  a couple of hours. But I wouldn't necessarily trust it for long-term
  security.

  (See *Is This Ready For Production*, below, for details and other
  caveats.)

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

- You'll need GNU Make (already installed on the Mac and Linux).

- You need `zip` installed to bundle up Lambda functions (also
  preinstalled on the Mac).

- [Install the AWS CLI tool](https://aws.amazon.com/cli/). Amazon's
  instructions are fine; on the Mac I prefer to install
  [Homebrew](http://brew.sh) and then use: `brew install awscli`.

- You need to
  [configure the AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
  with API keys for a AWS user with administrator permissions. These
  credentials will be used to bootstrap the AWS infrastructure, but
  will not leave your local machine.

  Choose either the `us-east-1` or `us-west-2` regions -- other
  regions are not supported at this time.

- You must
  [create an AWS keypair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)
  in your chosen region, in case you need to log in and debug your
  instances.

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
  pre-configure the project by setting environment variables in (for
  example) `~/.profile` or `~/.bashrc`:

```
export AWS_EC2_KEYNAME=your_ec2_keypair_name
export GITHUB_OAUTH_TOKEN=your_github_token
export GITHUB_USERNAME=your_github_username
export GITHUB_REPO_NAME=aws-ci-demo  # or whatever you named your fork
export GITHUB_BRANCH_NAME=master
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

The CloudFormation stack will be created and the script will pause to
wait until it is complete. You can follow the stack event stream on
the AWS console.

When the stack succeeds, the provision command will exit by printing
the DNS name which you can use to access your web page!

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


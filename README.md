# aws-ci-demo
Demonstration of infrastructure automation with AWS

## Prerequisites

- You'll need GNU Make (already installed on the Mac and Linux).

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
  [create an AWS keypair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair),
  in case you need to log in and debug your instances.

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
make provision
```

If you haven't already configured shell environment variables, you may
need to prefix this command with their settings, e.g.:

```
GITHUB_OAUTH_TOKEN=abcd1234 GITHUB_USERNAME=mememe AWS_EC2_KEYNAME=my-keypair make provision
```





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

  Choose either the `us-east-1` or `us-west-1` regions -- other
  regions are not supported at this time.

- The code for this project will be deployed to AWS directly from
  Github using AWS CodePipeline, which will need a Github access
  token. Generate one of these on the
  [https://github.com/settings/tokens](https://github.com/settings/tokens) page,
  giving it the `repo` and `admin:repo_hook` permissions. Copy the token into
  a safe place, like a password manager.

## Installation

Clone this Git repository, `cd` into the working directory, and type:

```
GITHUB_OAUTH_TOKEN=insert_your_token_here make deploy
```

... substituting your own Github OAuth token.




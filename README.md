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

## Prerequisites

- You'll want to run these provisioning scripts on a MacOS or Linux
  box.

- You'll need Python 2.7 (which is preinstalled on the Mac and most
  Linuxes).

- You'll need Python's Boto3 AWS library. Install this using `pip`, the
  Python package manager:

  ```
  pip install boto3
  ```

  You may need to give yourself admin permissions (e.g. using `su` or
  `sudo`) to make this work on your laptop. (I need to do this,
  because I run a relatively paranoid laptop.)

  (If `pip` is missing from your machine, you can
  [install it](https://pip.pypa.io/en/stable/installing/).)

- You need to
  [configure your machine with AWS credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html). These
  credentials need sufficient administrator permissions to create IAM
  Roles and policies. They will be used to bootstrap the AWS
  infrastructure, but these specific keys will not leave your local
  machine.

  You must also set the AWS region to either `us-east-1` or
  `us-west-2` regions -- the others are not supported at this time.

  To set your AWS credentials, you can install the AWS CLI and run
  `aws configure`. Or you can set the `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` environment
  variables.

- You must
  [create an AWS keypair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)
  in your chosen region -- the CI pipeline doesn't use it, but it
  might be useful when debugging. Set the `AWS_EC2_KEYNAME`
  environment variable to the name of your keypair.

- AWS CodePipeline will deploy directly from Github. To get a
  read/write copy of the code to deploy, you can fork this repository
  to your own Github account. Set the `GITHUB_USERNAME` environment
  variable to your account username. If you ever change the name of
  the fork, set `GITHUB_REPO_NAME` to the new name.

  Then, generate a Github access token on the
  [https://github.com/settings/tokens](https://github.com/settings/tokens)
  page, giving it the `repo` and `admin:repo_hook` permissions. Set
  the `GITHUB_OAUTH_TOKEN` environment variable to the value of this
  token.

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

The `provision.py` script will wait for the website to appear. I've
seen it happen in 6-7 minutes. While you're waiting, you can follow
the stack event streams on the AWS console. Meanwhile your shell
output will look something like this:

```
Ensuring that build bucket exists: builds-a4tp-us-east-1-131250507245
Creating bucket builds-a4tp-us-east-1-131250507245 to hold builds
Zipping and uploading lambda functions to s3://builds-a4tp-us-east-1-131250507245/Lambdas.zip
Creating stack a4tp-ci
CI stack successfully created
Deploying code from https://github.com/mockfish/aws-ci-redemo/tree/master
Visit https://console.aws.amazon.com/codepipeline/home?region=us-east-1#/view/a4tp-Pipeline to view pipeline state
Waiting for stack a4tp-web to appear...
web stack successfully deployd
The deployed build is https://builds-a4tp-us-east-1-131250507245.s3.amazonaws.com/a4tp-Pipeline/a4tp-Build/PX7v4kl
Visit your website at http://a4tp-web-WebServer-14QHOR1A6NVEF-1702662346.us-east-1.elb.amazonaws.com
```

You can visit that URL at the end to see your site.

### Testing

You can run `python ci/bin/status.py` to confirm that your website is
running and returning the phrase `Automation for the People`. It will
print `OK` and return a zero status code on success.

There are also instance-level and ELB-level health checks: see below.

### Development

- Commit edits to the code and push them to your Github repository to
  have them automatically deployed.

- The site source is in the `src` subdirectory. Anything in that
  directory gets copied into the web server docroot at deployment
  time. Edit what you want, but if the homepage doesn't contain the
  phrase "Automation for the People" it will fail health checks and be
  rolled back.

- The `ci` directory defines the CI infrastructure:
   - The instances and load balancer are defined in
     `ci/cfn/webs.template`. Changes to this file will be
     automatically deployed by CodePipeline.

   - Edits to other parts of the CI configuration may require a rerun
     of `python ci/bin/provision.py`. One should be able to run this
     script over and over without causing a problem.

### Teardown

When you get tired of this demo you can delete all of its CloudFormation
stacks with:

```
python ci/bin/terminate.py
```

You will be prompted to enter `yes` to make it harder to destroy your
running cloud application by accident.

(The one thing that doesn't clean itself up yet is the S3
bucket. Sorry about that.)


## The CI Design

### Design Principles

- "Immutable" infrastructure: Deploy new code by replacing whole
  instances.

- See how far we can get using only AWS services (plus
  Github).

- Experiment with the newer CodePipeline and Lambda features and see
  how much we miss Jenkins. Lambda-based builds have the usual
  "serverless" features: Fewer OS packages to maintain, fewer
  processes to monitor, pay-per-use fee structure, etc.

- Take full advantage of CloudFormation's built-in release
  orchestration by building smoke tests directly into instance and
  load balancer health checks.

- Though it is overkill for a static site, experiment with using
  Lambda to do "real builds", creating and archiving separate S3
  tarballs for every code release.  CodePipeline is designed for this,
  which helps.

### Architecture and Release Workflow

Two CloudFormation stacks are being created: The CI stack is launched,
and it launches the "web" stack itself using CodePipeline.

First, an S3 bucket is created and Lambda functions uploaded to it.

Then the "CI" stack is built. It takes about 75 seconds for
CloudFormation to create the VPC and its trimmings (subnet, gateway,
etc.) together with a CodePipeline workflow. That workflow has three
stages, which are triggered once when they are first created, and on
every subsequent push to the Github `master` branch:

- The Source stage pulls the latest `master` code from Github.

- The Build stage runs a Lambda function to perform a "build" of that
  code. We're building static pages at the moment, so the "build" is
  just a zip file containing the `/src` directory from Github. But it
  could eventually have fancier build steps -- anything we can do in
  Lambda.

- The Deploy stage reads the `ci/cfn/webs.template` CloudFormation
  template from the latest commit and uses it to update the "Web
  stack". This has an Elastic Load Balancer (Classic version) plus two
  `t2.micro` instances running nginx in an AutoScaling
  group. CloudFormation configures the instances to download and
  install the latest build on their own, via a `cfn-init` script.

The web stack deploy process happens in "blue-green" style. When new
code is pushed:

- CloudFormation launches an entirely new AutoScaling group to replace
  the old. Both the old and the new group are temporarily connected to
  the load balancer -- though the new instances won't get traffic
  until they start passing ELB health checks.

- If the instances fail ELB health checks, or their local health
  checks, they will be terminated as the CloudFormation update fails
  and rolls back, and the old instances will remain in production the
  entire time.

- The instance-local health checks are implemented in a
  `/usr/local/bin/healthcheck` script, which gets installed and run at
  boot time by CloudFormation's `cloud-init` and `cfn-init`
  systems. This health check looks for a running `nginx`, and uses
  `curl` to confirm that `localhost` seems to be behaving
  correctly. If this check fails, the instance signals a `FAILURE` to
  CloudFormation and, once again, the update is rolled back.

- If the new AutoScaling group comes up successfully, CloudFormation
  terminates the old AutoScaling group.

### Troubleshooting

It's kind of fun to watch all this happening in the AWS consoles!

- Use the CloudFormation console to watch the event logs.

- Watch the CodePipeline control panel as a push to Github makes its
  way through the system.

- Watch the EC2 Instances screen as instances appear, the AutoScaling
  group status as it launches them, and the ELB status to see when
  they start receiving traffic.

When things blow up:

- Errors in the CodePipeline Lambda-based steps can be debugged by
  clicking through to the Lambda logs.

- The instances configure themselves quickly, so they also tend to
  fail quickly, then get terminated before you can debug them. If you
  need more time to log in, edit the `UserData` block in
  `ci/cfn/webs.template` and uncomment the `sleep 600` statement. When
  debugging an instance launch, look in `/var/log/cfn-init.log` and
  `/var/log/cloud-init-output.log`, as well as the nginx docroot at
  `/usr/share/nginx/html`.

## Is This Ready For Production?

- As mentioned up-top, I'd tighten the security before deploying this
  in production. Giving a Lambda function permission to manage IAM
  roles is too risky -- the Lambda runs code from Github, so anyone
  with Github commit permissions can take over your AWS account.

- One design compromise in this system is that it doesn't use
  AMIs. Instances are immutable, but they aren't all alike: To prevent
  security incidents, Amazon Linux is running `yum update --security`
  on every instance boot, so two successive releases won't necessarily
  be running the same software. If an incompatible update ends up in
  the upstream repositories, we will have a terrible time trying to
  revert. The only working copies of our old system will be the ones
  that are already running.

  For a static website this is probably fine. Linux distro maintainers
  would have to screw up pretty badly to break nginx to the point that
  it can't serve HTTP. But what about fancier projects?

  One sensible strategy is to bake AMI images using a tool like
  Packer. Trying to trigger Packer from a Lambda function is probably
  doable, but is outside the scope of this demo.

- Another potential annoyance is the lack of a local development
  environment. Again, for static pages this is no big deal. But for
  anything fancier I might want a local Docker environment. That in
  turn argues against the use of Amazon Linux, and against the use of
  `cfn-init` as the only way of configuring instances. I'm tempted to
  have the instances copy down an Ansible configuration from S3 and
  run local Ansible to configure themselves; the same Ansible could be
  run inside a development container or in a Packer-based AMI build
  script. But...

- The testing/health checking scheme has design flaws that could be
  fixed. For example, the ELB health check pings port 80, but doesn't
  ping a special application-aware health-check endpoint. I created an
  incident where four instances were running,

## Conclusions

- YAML-based CloudFormation templates are the greatest thing ever.

- Similarly, I now understand why everyone raves about AWS Lambda.

- CodePipeline plus Lambda is very powerful, though it is a bit hard
  to figure out what is going on from the various separate AWS
  consoles. A central message bus, or some Slack-channel integration,
  might help to make the workflow clearer.


# Kops Dockerized

## Description

This Dockerfile builds an image that may be used to run Kops commands for creating Kubernetes clusters on AWS.

The purpose of 'Kops Dockerized' is to not have to install kubectl and Kops on your local system, but instead, to simply run a Docker container with all the necessary packages and dependencies.

Since the `ENTRYPOINT` of the Dockerfile is `kops`, you can simply enter any kops command directly after the complete `docker run...` command. See the below section 'Tips for ease of use' to create a convenient alias.

The Docker file is based on Docker image `debian:11.1-slim`, and installs kubectl, kops, and aws-cli v2, together with some aws-cli dependencies (unzip, libc6, groff, and less).

Additionally, Vim is installed in order to be able to view and edit configuration files from within the container. For instance, after having created a cluster, the command `kops edit cluster ${NAME}` will open the Vim editor and let you edit the cluster.

## Security and secret credentials

All user-specific and secret variables (such as AWS credentials) are inserted into the container at runtime, so there are no apparent security issues if running the container as described below.

## Prerequisites

The below commands assume that you have configured your AWS account with a `kops` user account that has all the necessary policies, and that `kops` user is specified in your `.aws/credentials` file.

For information about how to prepare your AWS user account and S3 storage, please see:

[https://kops.sigs.k8s.io/getting_started/aws/](https://kops.sigs.k8s.io/getting_started/aws/)

One tip to further 'dockerize' your world is to run aws-cli via Amazon's own official docker container:

[https://hub.docker.com/r/amazon/aws-cli](https://hub.docker.com/r/amazon/aws-cli)

With that image, you do not even have to install aws-cli on your local computer, but everything related to Kops and AWS may be run as Docker containers.

The below command also bind mounts `-v ~/.kube-container:/root/.kube`, which means that you will have access to the kubectl config file locally at `~/.kube-container/config`

## Building and Running the Docker container

The image may be build with the command:
`docker build -t kops .`

The built image may be run with the command:

```
alias kops='docker run --rm -it \
        -v ~/.aws:/root/.aws \
        -v ~/.kube-container:/root/.kube \
        -e AWS_ACCESS_KEY_ID=$(aws configure --profile kops get aws_access_key_id) \
        -e AWS_SECRET_ACCESS_KEY=$(aws configure --profile kops get aws_secret_access_key) \
        -e NAME=mykopscluster.k8s.local \
        -e KOPS_STATE_STORE=s3://prefix-example-com-state-store \
        kops'
```

The above command includes the creation of all necessary environment variables that Kops needs. Please note that you need to adjust the environment variables' values to match the name of your own cluster and chosen S3 state store.

### kubectl config file

The kubectl configuration file `~/.kube/config` is being bind mounted to the local directory `~/.kube-container`. That is so that if you are running a kubectl configuration with another cluster already in the default location `~/.kube/config`, you could continue to do so. If you want to use the kubectl configuration generated inside the docker container, you may simply copy the generated config file from `~/.kube-container` to its default location `~/.kube` and then use kubectl as normally.

Do note that you may have to change the user and file priviledges of the config file to make it accessible to your current user.

### Potential problem: line endings

Please note that on some systems there might be a problem where the `aws configure --profile kops get aws_access_key_id` (and the corresponding command to get the secret) includes `\r` at the end of the string. In that case, please remove that ending from the environment variable, or kops will fail to connect to your AWS account.

One way of solving the line ending problem may be to first create temporary environment variables from your kops credentials in your local bash environment, with the help of `sed`:

```
export AWS_ACCESS_KEY_ID=$(echo $(aws configure --profile kops get aws_access_key_id) | sed 's/\r$//')
export AWS_SECRET_ACCESS_KEY=$(echo $(aws configure --profile kops get aws_secret_access_key) | sed 's/\r$//')
```

Then, do docker run loading the env vars from that local environment.

```
docker run --rm -it \
    -v ~/.aws:/root/.aws \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e NAME=mykopscluster.k8s.local \
    -e KOPS_STATE_STORE=s3://prefix-example-com-state-store \
    kops
```

### Running kops, kubectl, or aws-cli from inside the container

In case you want to use bash inside the container, you may run the command:

```
docker run -rm -it --entrypoint=bash \
    -v ~/.aws:/root/.aws \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e NAME \
    -e KOPS_STATE_STORE \
    kops
```

In that example, please note that you must have already created the necessary environment variables in your environment.

## Tips for ease of use

One easy way to use the container is to create an alias named `kops` for the docker run command you want to use. For instance:

```
alias kops='docker run --rm -it \
    -v ~/.aws:/root/.aws \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e NAME \
    -e KOPS_STATE_STORE \
    kops'
```

The above example assumes you have created all the necessary environment variables in your local environment.

With such an alias, you may simply run any `kops` command as if you had it natively installed, for instance:

```
kops version
```

To make the alias permanent, you may store it in the `.bashrc` or `.bash_aliases` file, in case you are using Bash.

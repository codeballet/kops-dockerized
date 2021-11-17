# Kops Dockerized
## Description
This Dockerfile builds an image that may be used to run Kops commands for creating Kubernetes clusters on AWS.

The Docker file is based on Docker image `debian:11.1-slim`, and installs kubectl, kops, and aws cli v2, together with some AWS CLI dependencies (unzip, libc6, groff, and less).

Additionally, Vim is installed in order to be able to view and edit configuration files from within the container. For instance, after having created a cluster, the command `kops edit cluster ${NAME}` will open the Vim editor and let you edit the cluster.

## Security and secret credentials
All user-specific and secret variables (such as AWS credentials) are inserted into the container at runtime, so there are no apparent security issues if running the container as described below.

## Prerequisites
The below commands assumes that you have configured your AWS account with a `kops` user account that has all the necessary policies, and that `kops` user is specified in your `.aws/credentials` file.

For information about how to prepare your AWS user account and S3 storage, please see:
[https://kops.sigs.k8s.io/getting_started/aws/](https://kops.sigs.k8s.io/getting_started/aws/)


## Building and Running the Docker container
The image may be build with the command:
`docker build -t kops .`

The built image may be run with the command:

```
docker run --rm -it \
    -v ~/.aws:/root/.aws \
    -e AWS_ACCESS_KEY_ID=$(aws configure --profile kops get aws_access_key_id) \
    -e AWS_SECRET_ACCESS_KEY$(aws configure --profile kops get aws_secret_access_key) \
    -e NAME=mykopscluster.k8s.local \
    -e KOPS_STATE_STORE=s3://prefix-example-com-state-store \
    kops
```

The above command includes the creation of all necessary environment variables that Kops needs. Please note that you need to adjust the environment variables' values to match the name of your own cluster and chosen S3 state store.


### Potential problem: line endings
Please note that on some systems there might be a problem where the `aws configure --profile kops get aws_access_key_id` (and the corresponding command to get the secret) includes `\r` at the end of the string. In that case, please remove that ending from the environment variable, or kops will fail to connect to your AWS account.

### Running inside the container
In case you want to use bash inside the container, you may run the command:

```
docker run -rm -it --name=kops --entrypoint=bash \
    -v ~/.aws:/root/.aws \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e NAME -e KOPS_STATE_STORE \
    kops
```

In that example, please note that you must have already created the necessary environment variables.

## Tips for ease of use
One easy way to use the container is to create an alias named `kops` for the docker run command you want to use. For instance:

```
alias kops='docker run --rm -it -v ~/.aws:/root/.aws -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e NAME -e KOPS_STATE_STORE kops'
```

The above example assumes you have created the necessary environment variables.

To make the alias permanent, you may store it in a `.bashrc` file, in case you are using Bash.
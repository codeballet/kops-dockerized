# use the image by running it with necessary environment variables (example):
# docker run --rm -it -v ~/.aws:/root/.aws -e AWS_ACCESS_KEY_ID=$(aws configure --profile kops get aws_access_key_id) -e AWS_SECRET_ACCESS_KEY=$(aws configure --profile kops get aws_secret_access_key) -e NAME=mykopscluster.k8s.local -e KOPS_STATE_STORE=s3://prefix-example-com-state-store kops

# run container and enter into bash:
# docker run -rm -it --name=kops --entrypoint=bash -v ~/.aws:/root/.aws -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e NAME -e KOPS_STATE_STORE kops

FROM debian:11.1-slim

# Create /root/.aws/ directory
RUN mkdir /root/.aws

# Install vim
RUN apt-get update && apt-get install -y vim

# Install kubectl
RUN apt-get install -y apt-transport-https ca-certificates curl && \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

RUN apt-get update && \
    apt-get install -y kubectl

# Install Kops
RUN curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 && \
    chmod +x kops && \
    mv kops /usr/local/bin/kops

# Install AWS CLI dependencies
RUN apt-get install -y unzip libc6 groff less

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

ENTRYPOINT [ "kops" ]

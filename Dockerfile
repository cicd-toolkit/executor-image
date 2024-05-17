
FROM python:3.12.0a6-slim-bullseye as base

# Versions
ARG PYTHON_VERSION=3.12.0a6
ARG PYTHON_PIP_VERSION=23.0.1
ARG PYTHON_PYBUMP_VERSION=1.11.2
ARG AWSCLI_VERSION=2.7.10
ARG KUBECTL_VERSION=1.25.14
ARG OC_VERSION=4.14.25
ARG HELM_VERSION=3.11.2
ARG TERRAFORM_VERSION=1.4.0
ARG TFSEC_VERSION=1.19.1
ARG GO_VERSION=1.18.1
ARG YAMLLINT_VERSION=1.8.2
ARG YQ_VERSION=4.25.3
ARG TERRAGRUNT_VERSION=0.43.2
ARG GITHUB_CLI_VERSION=2.28.0
ARG GCLOUD_CLI_VERSION=459.0.0

# Update base image to get latest security patches and install required tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    unzip \
    dirmngr \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    gnupg \
    jq \
    git \
    gawk \
    patch \
    tree \
    gettext-base

# Install AWS CLI
ARG AWSCLI_URL=https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip
RUN curl -o /tmp/awscli.zip ${AWSCLI_URL} \
    && unzip -qq -d /tmp /tmp/awscli.zip \
    && /tmp/aws/install \
    && rm -rf /tmp/aws*

# Install Kubernetes CLI (kubectl)
ARG KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN curl -o /tmp/kubectl ${KUBECTL_URL} \
    && mv /tmp/kubectl /usr/local/bin/kubectl \
    && chmod 0755 /usr/local/bin/kubectl \
    && rm -rf /tmp/kubectl*

# Install Helm
ARG HELM_URL=https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN mkdir /tmp/helmcli \
    && curl -o /tmp/helm.tar.gz ${HELM_URL} \
    && tar -xzf /tmp/helm.tar.gz -C /tmp/helmcli --strip-components=1 \
    && mv /tmp/helmcli/helm /usr/local/bin \
    && chmod 0755 /usr/local/bin/helm \
    && rm -rf /tmp/helmcli*

# Install Openshift CLI (oc)
ARG OC_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz
RUN mkdir /tmp/occli \
    && curl -o /tmp/oc.tar.gz ${OC_URL} \
    && tar -xzf /tmp/oc.tar.gz -C /tmp/occli \
    && mv /tmp/occli/oc /usr/local/oc \
    && rm -rf /tmp/occli*

# Install Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y azure-cli

# Install Terraform
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
ARG TERRAFORM_SHA_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
ARG TERRAFORM_SIGNATURE_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig
RUN curl -o /tmp/terraform.zip ${TERRAFORM_URL} \
    && unzip -d /usr/local/bin /tmp/terraform.zip \
    && chmod 0755 /usr/local/bin/terraform \
    && rm -rf /tmp/terraform*

# Install tfsec
ARG TFSEC_URL=https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64
RUN curl -o /tmp/tfsec -L ${TFSEC_URL} \
    && mv /tmp/tfsec /usr/local/bin/tfsec \
    && chmod 0755 /usr/local/bin/tfsec \
    && rm -rf /tmp/tfsec*

# Install GO
ARG GO_URL=https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
RUN curl ${GO_URL} | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin:$PATH
ENV GOROOT /usr/local/go

# Install yamllint
RUN pip install yamllint==${YAMLLINT_VERSION} --no-input
RUN pip show yamllint
RUN which yamllint


# Install yq
ARG YQ_URL=https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64.tar.gz
RUN curl -Lo /tmp/yq.tar.gz ${YQ_URL} \
    && tar -xzf /tmp/yq.tar.gz --exclude LICENSE -C /tmp/ \
    && mv /tmp/yq_linux_amd64 /usr/local/bin/yq \
    && chmod 0755 /usr/local/bin/yq \
    && rm -rf /tmp/yq*

# Install Terragrunt
ARG TERRAGRUNT_URL=https://github.com/gruntwork-io/terragrunt/releases/download/v{$TERRAGRUNT_VERSION}/terragrunt_linux_amd64
ARG TERRAGRUNT_SHA_URL=https://github.com/gruntwork-io/terragrunt/releases/download/v{$TERRAGRUNT_VERSION}/SHA256SUMS
RUN curl -L -o /tmp/terragrunt ${TERRAGRUNT_URL} \
    && curl -L -o /tmp/terragrunt.sha256 ${TERRAGRUNT_SHA_URL} \
    && echo "$(awk '/terragrunt_linux_amd64/ {print $1}' /tmp/terragrunt.sha256) /tmp/terragrunt" | sha256sum --check \
    && mv /tmp/terragrunt /usr/local/bin/ \
    && chmod 0755 /usr/local/bin/terragrunt \
    && rm -rf /tmp/terragrunt*

# Install Github CLI
ARG GITHUB_CLI_URL=https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
ARG GITHUB_CLI_SHA_URL=https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_checksums.txt
RUN mkdir /tmp/gh \
    && curl -L -o /tmp/gh.tar.gz ${GITHUB_CLI_URL} \
    && curl -L -o /tmp/gh.sha256 ${GITHUB_CLI_SHA_URL} \
    && echo "$(awk '/gh_'${GITHUB_CLI_VERSION}'_linux_amd64.tar.gz/ {print $1}' /tmp/gh.sha256) /tmp/gh.tar.gz" | sha256sum --check \
    && tar -xzf /tmp/gh.tar.gz -C /tmp/gh --strip-components=1 \
    && mv /tmp/gh/bin/gh /usr/local/bin/ \
    && chmod 0755 /usr/local/bin/gh \
    && rm -rf /tmp/gh*

# Install Google Cloud CLI
ARG GCLOUD_FILE=google-cloud-cli-${GCLOUD_CLI_VERSION}-linux-x86_64.tar.gz
ARG GCLOUD_CLI_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_FILE}
RUN curl -O ${GCLOUD_CLI_URL} \
    && tar -xf ${GCLOUD_FILE} \
    && mv /google-cloud-sdk /opt
ENV PATH=$PATH:/opt/google-cloud-sdk/bin

# Cleanup the image
RUN apt-get clean \
    && rm -r /var/lib/apt/lists/*

# Overwrite entrypoint of the base image
ENTRYPOINT [ "/bin/bash" ]

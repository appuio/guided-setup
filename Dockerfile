ARG TARGETPLATFORM
ARG TARGETARCH

FROM projectsyn/commodore:v1.32.0 AS base

ENV TARGETARCH=${TARGETARCH:-amd64}

USER 0:0

ENV PATH=${PATH}:${HOME}/.local/bin:/usr/local/go/bin

RUN \
  apt-get -y update && \
  apt-get install -y --no-install-recommends \
    apt-transport-https \
    awscli \
    bash \
    ca-certificates \
    coreutils \
    cpio \
    curl \
    dnsutils \
    git \
    gnupg \
    gzip \
    jq \
    libguestfs-tools \
    libnss-wrapper \
    openssh-client \
    patch \
    restic \
    socat \
    unzip \
    wget

# renovate: datasource=golang-version depName=golang
ARG GO_VERSION=1.26.0
RUN \
  cd /tmp && \
  wget https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz && \
  tar -C /usr/local -xzf go${GO_VERSION}.linux-${TARGETARCH}.tar.gz && \
  rm -f /tmp/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz


RUN echo "    ControlMaster auto\n    ControlPath /tmp/%r@%h:%p" >> /etc/ssh/ssh_config

# Docker
RUN \
    install -m 0775 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc &&\
    echo "Types: deb\nURIs: https://download.docker.com/linux/debian\nSuites: $(. /etc/os-release && echo "$VERSION_CODENAME")\nComponents: stable\nSigned-By: /etc/apt/keyrings/docker.asc" > /etc/apt/sources.list.d/docker.sources && \
    cat /etc/apt/sources.list.d/docker.sources && \
    apt-get -y update && \
    apt-get install -y --no-install-recommends \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

# Kubectl
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.35.1
RUN \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION%.*}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION%.*}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list && \
    chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
    apt-get -y update && \
    apt-get install -y --no-install-recommends \
      kubectl

# mikefarah/yq
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.52.4
RUN go install github.com/mikefarah/yq/${YQ_VERSION%%.*}@${YQ_VERSION} && cp ${HOME}/go/bin/yq /usr/local/bin/
# mikefarah/yq
COPY --from=docker.io/mikefarah/yq:v4.52.4 /usr/bin/yq /usr/local/bin/yq
# glab
# renovate: datasource=gitlab-releases depName=gitlab-org/cli registryUrl=https://gitlab.com
ARG GLAB_VERSION=v1.85.2
RUN \
  cd /tmp && \
  wget https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_VERSION}/downloads/glab_${GLAB_VERSION##v}_linux_${TARGETARCH}.deb && \
  dpkg -i /tmp/glab_${GLAB_VERSION##v}_linux_${TARGETARCH}.deb && \
  rm -f /tmp/glab_${GLAB_VERSION##v}_linux_${TARGETARCH}.deb

# MinIO CLI
# renovate: datasource=custom.minio depName=mcli
COPY --from=docker.io/minio/mc:RELEASE.2025-08-13T08-35-41Z \
    /usr/bin/mc /usr/local/bin/mc
  

# Vault CLI
# renovate: datasource=github-releases depName=hashicorp/vault
ARG VAULT_VERSION=v1.21.2
RUN \
    cd /tmp && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION##v}/vault_${VAULT_VERSION##v}_linux_${TARGETARCH}.zip && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION##v}/vault_${VAULT_VERSION##v}_SHA256SUMS && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION##v}/vault_${VAULT_VERSION##v}_SHA256SUMS.sig && \
    wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify vault_${VAULT_VERSION##v}_SHA256SUMS.sig vault_${VAULT_VERSION##v}_SHA256SUMS && \
    grep vault_${VAULT_VERSION##v}_linux_${TARGETARCH}.zip vault_${VAULT_VERSION##v}_SHA256SUMS | sha256sum -c && \
    unzip /tmp/vault_${VAULT_VERSION##v}_linux_${TARGETARCH}.zip -d /tmp && \
    mv /tmp/vault /usr/local/bin/vault && \
    rm -f /tmp/vault_${VAULT_VERSION##v}_linux_${TARGETARCH}.zip vault_${VAULT_VERSION##v}_SHA256SUMS ${VAULT_VERSION##v}/vault_${VAULT_VERSION##v}_SHA256SUMS.sig

# OC
# renovate: datasource=custom.oc depName=openshift-client
ARG OC_VERSION=4.20.1
RUN cd /tmp && \
    wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz && \
    tar -xf /tmp/openshift-client-linux-${OC_VERSION}.tar.gz oc && \
    mv /tmp/oc /usr/local/bin/oc && \
    rm -f /tmp/openshift-client-linux-${OC_VERSION}.tar.gz


# Emergency-credentials-receive
COPY --from=ghcr.io/vshn/emergency-credentials-receive:v1.2.2 \
    /usr/bin/emergency-credentials-receive \
    /usr/local/bin/emergency-credentials-receive

# Exo CLI
# renovate: datasource=github-releases depName=exoscale/cli
ARG EXO_VERSION=v1.93.0
RUN cd /tmp && \
    wget https://github.com/exoscale/cli/releases/download/${EXO_VERSION}/exoscale-cli_${EXO_VERSION##v}_linux_${TARGETARCH}.deb && \
    wget https://github.com/exoscale/cli/releases/download/${EXO_VERSION}/exoscale-cli_${EXO_VERSION##v}_linux_${TARGETARCH}.deb.sig && \
    wget https://github.com/exoscale/cli/releases/download/${EXO_VERSION}/exoscale-cli_${EXO_VERSION##v}_checksums.txt && \
    wget https://github.com/exoscale/cli/releases/download/${EXO_VERSION}/exoscale-cli_${EXO_VERSION##v}_checksums.txt.sig && \
    gpg --keyserver hkps://keys.openpgp.org:443 --recv-keys "7100E8BFD6199CE0374CB7F003686F8CDE378D41" && \
    gpg --verify exoscale-cli_${EXO_VERSION##v}_checksums.txt.sig exoscale-cli_${EXO_VERSION##v}_checksums.txt && \
    gpg --verify exoscale-cli_${EXO_VERSION##v}_linux_${TARGETARCH}.deb.sig exoscale-cli_${EXO_VERSION##v}_linux_${TARGETARCH}.deb && \
    grep  exoscale-cli_${EXO_VERSION##v}_linux_${TARGETARCH}.deb exoscale-cli_${EXO_VERSION##v}_checksums.txt | sha256sum -c && \
    dpkg -i /tmp/exoscale-cli_${EXO_VERSION##v}_linux_${TARGETARCH}.deb && \
    rm -f /tmp/exoscale-cli_${EXO_VERSION##v}_*

COPY ./docker/browser.sh /usr/local/bin/xdg-open
RUN chmod a+x /usr/local/bin/xdg-open
ENV BROWSER=xdg-open

# Gandalf
COPY --from=ghcr.io/appuio/gandalf:v0.0.4
    /usr/bin/gandalf /usr/local/bin/gandalf

# OIDC token callback for Commodore
EXPOSE 18000
# OIDC token callback for Vault
EXPOSE 8250


COPY ./workflows /workflows

ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "gandalf"]

USER 65536:0

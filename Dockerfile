FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
# Install dependencies.
RUN apt update \
    && apt install -y --no-install-recommends \
       iputils-ping \
       vim \
       software-properties-common \
       wget \
       iproute2 \
       apt-utils \
    && apt clean \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man
# add hashicorp repo
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor |  tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |  tee /etc/apt/sources.list.d/hashicorp.list && chmod 644 /etc/apt/sources.list.d/hashicorp.list && apt update && apt install vault && setcap -r /usr/bin/vault
# add vault config
RUN mkdir -p /etc/vault.d && mkdir -p /var/run/vault-agent
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

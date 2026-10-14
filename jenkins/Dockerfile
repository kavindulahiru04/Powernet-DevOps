FROM docker:cli AS dockercli

FROM jenkins/jenkins:lts-jdk21

COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      nodejs npm ansible python3-venv python3-pip curl git openssh-client ca-certificates \
 && python3 -m venv /opt/docker-sdk-venv \
 && /opt/docker-sdk-venv/bin/pip install --no-cache-dir 'docker>=7.1.0' \
 && ansible-galaxy collection install community.docker -p /usr/share/ansible/collections \
 && chown -R jenkins:jenkins /usr/share/ansible/collections /opt/docker-sdk-venv \
 && rm -rf /var/lib/apt/lists/*

USER jenkins

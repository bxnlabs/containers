FROM debian:12-slim@sha256:ad86386827b083b3d71139050b47ffb32bbd9559ea9b1345a739b14fec2d9ecf AS base

ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV DEBIAN_FRONTEND noninteractive
ENV BXN_HOME /bxn
ENV PATH ${BXN_HOME}/bin:${PATH}

# Copy configuration
COPY etc /etc

# Install core packages
RUN apt-get update && apt-get install ca-certificates tini

# Create nonroot account
RUN groupadd --gid 65532 nonroot \
    && useradd --no-log-init --create-home \
        --uid 65532 \
        --gid 65532 \
        --shell /sbin/nologin \
        nonroot

# Create directories
RUN mkdir -p ${BXN_HOME}/bin ${BXN_HOME}/lib ${BXN_HOME}/share

# Set entrypoint
ENTRYPOINT [ "/usr/bin/tini", "-g", "--" ]


FROM python:3.12-slim-bookworm@sha256:af4e85f1cac90dd3771e47292ea7c8a9830abfabbe4faa5c53f158854c2e819d AS py-base

ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV DEBIAN_FRONTEND noninteractive
ENV BXN_HOME /bxn
ENV VIRTUAL_ENV ${BXN_HOME}/lib/venv
ENV SOURCE_DIR ${BXN_HOME}/src
ENV PYTHONPATH ${SOURCE_DIR}
ENV PATH ${VIRTUAL_ENV}/bin:${BXN_HOME}/bin:${PATH}

# Copy configuration
COPY etc /etc

# Install core packages
RUN apt-get update && apt-get install ca-certificates tini

# Create nonroot account
RUN groupadd --gid 65532 nonroot \
    && useradd --no-log-init --create-home \
        --uid 65532 \
        --gid 65532 \
        --shell /sbin/nologin \
        nonroot

# Create directories
RUN mkdir -p ${BXN_HOME}/bin ${BXN_HOME}/lib ${BXN_HOME}/share

# Set up virtual environment
RUN python -m venv ${VIRTUAL_ENV}

# Set working directory
WORKDIR ${SOURCE_DIR}

# Set entrypoint
ENTRYPOINT [ "/usr/bin/tini", "-g", "--" ]


FROM py-base AS py-devtools

# renovate: datasource=github-releases packageName=astral-sh/uv versioning=semver
ARG UV_VERSION=0.4.20

ENV UV_INSTALL_DIR ${BXN_HOME}/bin

# Install development tools
RUN apt-get update && apt-get install build-essential curl git make ncat tmux vim
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh


FROM py-devtools AS py-devenv

ONBUILD ARG UID
ONBUILD ARG GID

# Create dev user account
ONBUILD RUN test -n "${UID-}" && test -n "${GID-}"
ONBUILD RUN getent group ${GID} || groupadd --gid ${GID} dev
ONBUILD RUN useradd --non-unique --no-log-init --create-home --uid ${UID} --gid ${GID} dev \
    && chown -R ${UID}:${GID} ${VIRTUAL_ENV}

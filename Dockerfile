FROM debian:bookworm-20240904-slim@sha256:a629e796d77a7b2ff82186ed15d01a493801c020eed5ce6adaa2704356f15a1c AS base

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


FROM python:3.12.6-slim-bookworm@sha256:15bad989b293be1dd5eb26a87ecacadaee1559f98e29f02bf6d00c8d86129f39 AS py-base

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

# renovate: datasource=pypi packageName=poetry versioning=pypi
ARG POETRY_VERSION=1.8.3

ENV POETRY_HOME ${BXN_HOME}/lib/poetry
ENV POETRY_VERSION ${POETRY_VERSION}
ENV POETRY_VIRTUALENVS_CREATE false
ENV PATH ${POETRY_HOME}/bin:${PATH}


# Install development tools
RUN apt-get update && apt-get install build-essential curl git make ncat tmux vim
RUN curl -sSL https://install.python-poetry.org | /usr/local/bin/python -


FROM py-devtools AS py-devenv

ONBUILD ARG UID
ONBUILD ARG GID

# Create dev user account
ONBUILD RUN test -n "${UID-}" && test -n "${GID-}"
ONBUILD RUN getent group ${GID} || groupadd --gid ${GID} dev
ONBUILD RUN useradd --non-unique --no-log-init --create-home --uid ${UID} --gid ${GID} dev \
    && chown -R ${UID}:${GID} ${VIRTUAL_ENV}

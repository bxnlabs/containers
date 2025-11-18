FROM debian:13-slim@sha256:a347fd7510ee31a84387619a492ad6c8eb0af2f2682b916ff3e643eb076f925a AS base

ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV DEBIAN_FRONTEND=noninteractive
ENV BXN_HOME=/bxn
ENV PATH=${BXN_HOME}/bin:${PATH}

# Copy configuration
COPY rootfs/ /

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


FROM base AS py-core

# renovate: datasource=python-version versioning=python
ARG PYTHON_VERSION=3.12.12
ENV PYTHON_VERSION=${PYTHON_VERSION}

# Add virtual environment and update path
ENV VIRTUAL_ENV=${BXN_HOME}/lib/venv
ENV PATH=${VIRTUAL_ENV}/bin:${BXN_HOME}/bin:${PATH}

# Source directory for project files
ENV SOURCE_DIR=${BXN_HOME}/src
ENV PYTHONPATH=${SOURCE_DIR}:${PYTHONPATH}

WORKDIR ${SOURCE_DIR}


FROM py-core AS py-devtools

# renovate: datasource=github-releases packageName=astral-sh/uv versioning=semver
ARG UV_VERSION=0.9.10

ENV UV_INSTALL_DIR=${BXN_HOME}/bin
ENV UV_PROJECT_ENVIRONMENT=${VIRTUAL_ENV}
ENV UV_PYTHON_DOWNLOADS=manual
ENV UV_PYTHON_INSTALL_DIR=${BXN_HOME}/share/python

# Install development tools
RUN apt-get update && apt-get install build-essential curl git make ncat tmux vim
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh

# Install Python
RUN uv python install ${PYTHON_VERSION}

# Set up virtual environment
RUN uv venv --no-project ${VIRTUAL_ENV}


FROM py-devtools AS py-devenv

ONBUILD ARG UID
ONBUILD ARG GID

# Create dev user account
ONBUILD RUN test -n "${UID-}" && test -n "${GID-}"
ONBUILD RUN getent group ${GID} || groupadd --gid ${GID} dev
ONBUILD RUN useradd --non-unique --no-log-init --create-home --uid ${UID} --gid ${GID} dev \
    && chown -R ${UID}:${GID} ${VIRTUAL_ENV}


FROM py-core AS py-base

COPY --from=py-devtools ${BXN_HOME}/share/python ${BXN_HOME}/share/python

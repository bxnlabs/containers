# The runner image for bxnlabs' self-hosted ARC scale sets: upstream's runner,
# plus the tools bxnlabs' workflows use, so jobs don't install them each run.
FROM ghcr.io/actions/actions-runner:2.338.2@sha256:6d0b2d80d80f143f77dcb676e50920100bbb547e39e883454d57f45ab8c31300 AS actions-runner

# renovate: datasource=node-version versioning=node
ARG NODE_VERSION=26.13.1
# renovate: datasource=github-releases packageName=helm/helm
ARG HELM_VERSION=v4.3.2
# renovate: datasource=github-releases packageName=hashicorp/terraform
ARG TERRAFORM_VERSION=v1.17.2
# renovate: datasource=github-releases packageName=terraform-linters/tflint
ARG TFLINT_VERSION=v0.66.0
# renovate: datasource=github-releases packageName=yannh/kubeconform
ARG KUBECONFORM_VERSION=v0.8.0
# renovate: datasource=github-releases packageName=google/go-containerregistry
ARG CRANE_VERSION=v0.22.1
# renovate: datasource=github-releases packageName=mikefarah/yq
ARG YQ_VERSION=v4.54.3
# renovate: datasource=github-releases packageName=rhysd/actionlint
ARG ACTIONLINT_VERSION=v1.7.12
# renovate: datasource=github-releases packageName=koalaman/shellcheck
ARG SHELLCHECK_VERSION=v0.11.0

ARG TARGETARCH

USER root
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends libatomic1 make \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.13.9 /uv /uvx /usr/local/bin/

RUN case "${TARGETARCH}" in \
        amd64) node_arch=x64; crane_arch=x86_64; shellcheck_arch=x86_64 ;; \
        arm64) node_arch=arm64; crane_arch=arm64; shellcheck_arch=aarch64 ;; \
        *) echo "unsupported arch ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && tmp="$(mktemp -d)" \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.gz" \
        | tar -xz -C /usr/local --strip-components=1 --exclude='*.md' --exclude=LICENSE \
    && curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
        | tar -xz --strip-components=1 -C /usr/local/bin "linux-${TARGETARCH}/helm" \
    && curl -fsSLo "${tmp}/terraform.zip" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION#v}/terraform_${TERRAFORM_VERSION#v}_linux_${TARGETARCH}.zip" \
    && unzip -q "${tmp}/terraform.zip" terraform -d /usr/local/bin \
    && curl -fsSLo "${tmp}/tflint.zip" "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_${TARGETARCH}.zip" \
    && unzip -q "${tmp}/tflint.zip" tflint -d /usr/local/bin \
    && curl -fsSL "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-${TARGETARCH}.tar.gz" \
        | tar -xz -C /usr/local/bin kubeconform \
    && curl -fsSL "https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_${crane_arch}.tar.gz" \
        | tar -xz -C /usr/local/bin crane \
    && curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}" \
    && chmod +x /usr/local/bin/yq \
    && curl -fsSL "https://github.com/rhysd/actionlint/releases/download/${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION#v}_linux_${TARGETARCH}.tar.gz" \
        | tar -xz -C /usr/local/bin actionlint \
    && curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.${shellcheck_arch}.tar.gz" \
        | tar -xz --strip-components=1 -C /usr/local/bin "shellcheck-${SHELLCHECK_VERSION}/shellcheck" \
    && rm -rf "${tmp}"

USER runner

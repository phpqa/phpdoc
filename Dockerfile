# Set defaults

ARG BASE_IMAGE="php:7.2"
ARG PACKAGIST_NAME="phpdocumentor/phpdocumentor"
ARG PHPQA_NAME="phpdoc"
ARG VERSION="dev-master"

# Build image

FROM ${BASE_IMAGE}
ARG COMPOSER_IMAGE
ARG PACKAGIST_NAME
ARG VERSION
ARG PHPQA_NAME
ARG VERSION
ARG BUILD_DATE
ARG VCS_REF
ARG IMAGE_NAME

# Install Tini - https://github.com/krallin/tini

ARG TINI_VERSION="v0.18.0"
ARG TINI_GPG_KEY="595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7"

RUN set -x \
    && apt-get update \
    && apt-get install -y gnupg2 \
    && rm -rf /var/lib/apt/lists/* \
    && export TINI_HOME="/sbin" \
    && curl -fsSL "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini" -o "${TINI_HOME}/tini" \
    && curl -fsSL "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc" -o "${TINI_HOME}/tini.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && ( \
        gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "${TINI_GPG_KEY}" \
        || gpg --keyserver hkp://keyserver.pgp.com:80 --recv-keys "${TINI_GPG_KEY}" \
        || gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "${TINI_GPG_KEY}" \
        || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "${TINI_GPG_KEY}" \
    ) \
    && gpg --batch --verify "${TINI_HOME}/tini.asc" "${TINI_HOME}/tini" \
    && (rm -rf "${GNUPGHOME}" "${TINI_HOME}/tini.asc" || true) \
    && chmod +x "${TINI_HOME}/tini" \
    && "${TINI_HOME}/tini" -h

# Install phpDocumentor - https://github.com/phpDocumentor/phpDocumentor2
# - dependency: intl
# - dependency: zip
# - dependency: xsl
# - dependency: graphviz

RUN set -x \
    && apt-get update \
    && apt-get install -yq curl git libicu-dev libicu57 zlib1g-dev libxslt-dev graphviz \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install -j$(nproc) intl zip xsl

COPY --from=composer:1.6.5 /usr/bin/composer /usr/bin/composer
RUN COMPOSER_HOME="/composer" composer global require --prefer-dist --no-progress --dev ${PACKAGIST_NAME}:${VERSION}
ENV PATH /composer/vendor/bin:${PATH}

# Add entrypoint script

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Add image labels

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.vendor="phpqa" \
      org.label-schema.name="${PHPQA_NAME}" \
      org.label-schema.version="${VERSION}" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.url="https://github.com/phpqa/${PHPQA_NAME}" \
      org.label-schema.usage="https://github.com/phpqa/${PHPQA_NAME}/README.md" \
      org.label-schema.vcs-url="https://github.com/phpqa/${PHPQA_NAME}.git" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.docker.cmd="docker run --rm --volume \${PWD}:/app --workdir /app ${IMAGE_NAME}"

# Package container

WORKDIR "/app"
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["phpdoc"]

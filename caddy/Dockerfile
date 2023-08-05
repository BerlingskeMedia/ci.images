ARG BASE_IMAGE_TAG=2.4.5
ARG BASE_IMAGE_REPO=caddy

FROM caddy:builder AS builder
RUN xcaddy build --with github.com/ss098/certmagic-s3

FROM ${BASE_IMAGE_REPO}:${BASE_IMAGE_TAG} as final
LABEL org.opencontainers.image.source="git@github.com:BerlingskeMedia/ci.images.git"

ARG CI_COMMIT_SHA
ARG CI_BUILD_NUMBER
RUN echo "${CI_BUILD_NUMBER} - ${CI_COMMIT_SHA}" > /usr/share/caddy/release-version.txt

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

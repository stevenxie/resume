##################################################
## BUILDER IMAGE
##################################################
FROM node:10-alpine AS builder

## Install build dependencies.
RUN apk add make

## Copy source, install dependencies.
WORKDIR /build/
COPY ./ .
RUN make install

## Build for production.
RUN make release


##################################################
## PRODUCTION IMAGE
##################################################
FROM nginx:1-alpine AS production

ARG BUILD_VERSION="unset"

## Labels:
LABEL maintainer="Steven Xie <hello@stevenxie.me>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name = "stevenxie/resume"
LABEL org.label-schema.url="https://stevenxie.me/resume/"
LABEL org.label-schema.vcs-url="https://github.com/stevenxie/resume"
LABEL org.label-schema.version="$BUILD_VERSION"

## Copy frontend, and config files:
COPY --from=builder /build/dist/ /usr/share/nginx/html/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

## Configure default nginx variables.
ENV NGINX_SERVER_NAME="default_server" NGINX_CONFIG="html"

## Define healthcheck.
COPY ./scripts/healthcheck.sh /usr/bin/healthcheck.sh
ENV HEALTH_ENDPOINT=http://localhost:80
HEALTHCHECK --interval=30s --timeout=30s --start-period=45s --retries=2 \
  CMD [ "healthcheck.sh" ]

## Expose HTTP port.
EXPOSE 80

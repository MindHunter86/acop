# -*- coding: utf-8 -*-
# vim: ft=Dockerfile

# container - builder
FROM golang:1.19.1-alpine AS build
LABEL maintainer="mindhunter86 <mindhunter86@vkom.cc>"

ARG GOAPP_MAIN_VERSION="devel"
ARG GOAPP_MAIN_BUILDTIME="N/A"

ENV MAIN_VERSION=$GOAPP_MAIN_VERSION
ENV MAIN_BUILDTIME=$GOAPP_MAIN_BUILDTIME

# hadolint/hadolint - DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

WORKDIR /usr/sources/acop
COPY . .

ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# skipcq: DOK-DL3018 i'm a badboy, disable this shit
RUN echo "ready" \
  && go build -trimpath -ldflags="-s -w -X 'main.version=$MAIN_VERSION' -X 'main.buildtime=$MAIN_BUILDTIME'" -o acop \
  && apk add --no-cache upx \
  && upx -9 -k acop \
  && echo "nobody:x:65534:65534:nobody:/usr/local/bin:/bin/false" > etc_passwd


# container - runner
FROM scratch
LABEL maintainer="mindhunter86 <mindhunter86@vkom.cc>"

WORKDIR /usr/local/bin/
COPY --from=build /usr/sources/acop/etc_passwd /etc/passwd
COPY --from=build --chmod=0555 /usr/sources/acop/acop acop

USER nobody
ENTRYPOINT ["/usr/local/bin/acop"]
CMD ["--help"]

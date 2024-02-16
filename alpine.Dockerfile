FROM golang:1.22-alpine AS build

ARG TARGETARCH

# Install UPX
ARG UPX_VERSION=4.2.2
RUN wget https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz && \
  tar -xvf upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz && \
  mv upx-${UPX_VERSION}-${TARGETARCH}_linux/upx /usr/local/bin && \
  rm -rf upx*

WORKDIR /src

# Install Go Deps
COPY go.* ./
RUN go mod download

# Build Application
COPY . ./
RUN go build -ldflags="-s -w" -o app cmd/hello-world/main.go

# Compress Application
RUN upx app

FROM alpine

RUN apk add --no-cache ca-certificates
COPY --from=build /src/app /usr/local/bin/app

ENTRYPOINT ["/usr/local/bin/app"]

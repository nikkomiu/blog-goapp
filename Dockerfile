#########################
#   Build Application   #
#########################
FROM mcr.microsoft.com/oss/go/microsoft/golang:1.22.0-1-cbl-mariner2.0 AS build

# Install build dependencies
RUN tdnf install -y git ca-certificates

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

#########################
# Build Root Filesystem #
#########################
FROM mcr.microsoft.com/cbl-mariner/base/core:2.0 AS rootfs

# Install runtime dependencies to /mnt
RUN tdnf install --releasever 2.0 -y ca-certificates --installroot /mnt && \
  cp /etc/*-release /mnt/etc/

# Remove unnecessary files
RUN rm -rf /mnt/var/cache/tdnf /mnt/usr/lib/debug /mnt/usr/share/{man,doc} /mnt/usr/local/share/{man,doc} /usr/share/licenses /usr/share/terminfo

# Copy the built application
COPY --from=build /src/app /mnt/usr/local/bin/app

#########################
#   Build Final Image   #
#########################
FROM scratch

COPY --from=rootfs /mnt /

ENTRYPOINT ["/usr/local/bin/app"]

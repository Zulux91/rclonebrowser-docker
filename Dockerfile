#
# RcloneBrowser Dockerfile
#

FROM jlesage/baseimage-gui:alpine-3.11-glibc

# Define environment variables
ENV ARCH=amd64

# ENV RCLONE_VERSION=current //current not working. New to docker, can't figure out why.
ENV RCLONE_VERSION=v1.49.5
ENV ARCHIVE_URL=https://downloads.rclone.org/

# Define working directory.
WORKDIR /tmp

# Install Rclone Browser dependencies

RUN apk --no-cache add \
      ca-certificates \
      fuse \
      wget \
      qt5-qtbase \
      qt5-qtbase-x11 \
      libstdc++ \
      libgcc \
      dbus \
      xterm && \
    cd /tmp && \
    wget -q ${ARCHIVE_URL}${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-${ARCH}.zip && \
    unzip /tmp/rclone-${RCLONE_VERSION}-linux-${ARCH}.zip && \
    mv /tmp/rclone-*-linux-${ARCH}/rclone /usr/bin && \
    rm -r /tmp/rclone* && \
    apk add --no-cache --virtual=build-dependencies \
        build-base \
        cmake \
        make \
        gcc \
        git \
        qt5-qtbase qt5-qtmultimedia-dev qt5-qttools-dev && \
# Compile RcloneBrowser
    git clone https://github.com/kapitainsky/RcloneBrowser.git /tmp && \
    mkdir /tmp/build && \
    cd /tmp/build && \
    cmake .. && \
    cmake --build . && \
    ls -l /tmp/build && \
    cp /tmp/build/build/rclone-browser /usr/bin  && \
# Cleanup
    apk del --purge build-dependencies && \
    rm -rf /tmp/*
 
# Maximize only the main/initial window.
RUN \
    sed-patch 's/<application type="normal">/<application type="normal" title="Rclone Browser">/' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/kapitainsky/RcloneBrowser/wiki/images/rclone_256.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY VERSION /

# Set environment variables.
ENV APP_NAME="RcloneBrowser" \
    S6_KILL_GRACETIME=8000

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/media"]

# Metadata.
LABEL \
      org.label-schema.name="rclonebrowser" \
      org.label-schema.description="Docker container for RcloneBrowser" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/Zulux91/rclonebrowser-docker" \
      org.label-schema.schema-version="1.0"

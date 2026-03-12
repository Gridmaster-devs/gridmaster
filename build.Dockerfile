FROM debian:latest

WORKDIR /project

COPY templates.tar.gz common.sh /tmp

# Install dependencies and delete the temporary package cache after.
RUN apt-get update && \
	apt-get install -y \
		bash \
		git \
		make \
		patch \
		binutils \
		bash \
		python3 \
		curl \
		unzip \
		libfontconfig && \
	rm -rf /var/lib/apt/lists/*

# Set bash as the default shell (needed for bash-builtins).
SHELL ["/bin/bash", "-c"]

# Download, unzip and place godot into /usr/bin/
RUN curl -L "https://downloads.godotengine.org/?version=4.5.1&flavor=stable&slug=linux.x86_64.zip&platform=linux.64" -o /tmp/godot.zip && \
	unzip -p /tmp/godot.zip > /usr/bin/godot && \
	chmod +x /usr/bin/godot

# Create the directory for the export templates and unzip the export templates.
RUN (cd /tmp && source ./common.sh && mkdir -p "${EXPORT_TEMPLATES_DIR}" && tar -xf templates.tar.gz -C "$EXPORT_TEMPLATES_DIR" --strip-components=1)

# Finally delete the temporary files to make the image size smaller.
RUN rm /tmp/templates.tar.gz /tmp/common.sh

ENTRYPOINT ["./build.sh", "debug"]

#!/usr/bin/env bash
set -euo pipefail

# Tools required by this script:
# godot
# curl

BUILD_DIR="${PWD}/build"
# The resulting version string should be of following format: "4.5.1.stable"
GODOT_VERSION="$(godot --version | sed 's/\.[af09].*$//')"

# Verify that export_presets.cfg exists.
if [ ! -f "${PWD}/export_presets.cfg" ]; then
	echo "Missing export_presets.cfg. Please create this file manually from Project->Export."
	exit 1
fi

# Get the mirrorlist
MIRROR_LIST_URL="https://godotengine.org/mirrorlist/${GODOT_VERSION}.json"
MIRROR_LIST_PATH="/tmp/mirrorlist.json"
curl "$MIRROR_LIST_URL" -o "$MIRROR_LIST_PATH"

# TODO: Download the export_templates (Only web is needed, otherwise there won't be enough space in the CI/CD container).

# Build the web target
if [ ! -d "$BUILD_DIR" ]; then
	mkdir "$BUILD_DIR"
fi
godot --headless --verbose --export-debug "Web" "${BUILD_DIR}/index.html"
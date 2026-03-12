#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="/build"
source ./common.sh
WORK_DIR="${PWD}/grid-master-app"
TARGET_EDITOR="editor-web"
TARGET_CLIENT="client-web"

if [ ! -d "$WORK_DIR" ]; then
	echo "[ FAIL ] Working directory not found."
	exit 1
fi
cd "$WORK_DIR"

function usage {
	local USAGE="$0 <export-type> [release|debug]"
	echo "$USAGE"
	exit 1
}

function msg_build_success {
	printf "[ SUCCESS ] The target '%s' was built successfully." "$1"
}

function msg_build_fail {
	printf "[ FAIL ] The target '%s' build failed. Please check the above build output." "$1"
}

if [ "$#" -ne 1 ]; then
	usage
elif [ "$1" == "debug" ]; then
	EXPORT_FLAG="--export-debug"
elif [ "$1" == "release" ]; then
	EXPORT_FLAG="--export-release"
fi

## Sanity checks
# Verify that export_presets.cfg exists.
#if [ ! -f "./${WORK_DIR}/export_presets.cfg" ]; then
if [ ! -f "./export_presets.cfg" ]; then
	echo "[ FAIL ] Missing export_presets.cfg. Please create this file manually from Project->Export."
	exit 1
fi

## Build the editor
if ! godot --headless --verbose "$EXPORT_FLAG" "$TARGET_EDITOR" "${BUILD_DIR}/${TARGET_EDITOR}/index.html"; then
	msg_build_fail "$TARGET_EDITOR"
	exit 1
else
	msg_build_success "$TARGET_EDITOR"
fi

## Build the client
if ! godot --headless --verbose "$EXPORT_FLAG" "$TARGET_CLIENT" "${BUILD_DIR}/${TARGET_CLIENT}/index.html"; then
	msg_build_fail "$TARGET_CLIENT"
	exit 1
else
	msg_build_success "$TARGET_CLIENT"
fi


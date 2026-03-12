#!/usr/bin/bash
set -euo pipefail

GODOT_VERSION="4.5.1.stable"
EXPORT_TEMPLATES_DIR="/root/.local/share/godot/export_templates/${GODOT_VERSION}"
export GODOT_VERSION
export EXPORT_TEMPLATES_DIR

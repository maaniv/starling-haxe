#!/bin/sh
SCRIPT_DIR=$(dirname "$0")
haxelib run lime display "${SCRIPT_DIR}/project.xml" linux > "${SCRIPT_DIR}/build.hxml"

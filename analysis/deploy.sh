#!/bin/env bash

set -euo pipefail

current_dir=$(dirname "$0")
cd "${current_dir}" || exit 1

CONFIG_PATH="src/main/resources/app.conf"
APP_NAME="$(grep 'app\.name' "${CONFIG_PATH}" | cut -d ' ' -f3)"
ASSETS_DIR="$(grep 'app\.assetsDir' "${CONFIG_PATH}" | cut -d ' ' -f3)"
MAIN_CLASS="gitrate.analysis.Main"
OUT_JAR="${ASSETS_DIR}/out.jar"

rm -rvf "${ASSETS_DIR}"
cp -rv assets "${ASSETS_DIR}"
mkdir -p "${ASSETS_DIR}/data"

sbt assembly
cp -v ./target/scala-*/*-assembly-*.jar "${OUT_JAR}"
cp -v ./conf/spark-defaults.conf "${ASSETS_DIR}/"

cd "${ASSETS_DIR}"

# TODO: versions
npm install eslint eslint-plugin-better eslint-plugin-mocha eslint-plugin-private-props eslint-plugin-promise

spark-submit \
    --deploy-mode cluster \
    --class "${MAIN_CLASS}" \
    --name "${APP_NAME}" \
    --properties-file spark-defaults.conf \
    "${OUT_JAR}"

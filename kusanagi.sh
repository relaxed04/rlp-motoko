#!/bin/bash
set -euo pipefail

SRC_DIR="./srcku"
DEST_DIR="./src"

for KU in `find $SRC_DIR -type f -name "*.ku.mo"`; do
  FILE="${KU#$SRC_DIR}"
  NAME="${FILE%.ku.mo}"

  MO="$DEST_DIR$NAME.mo"

  SUB_DIR=`dirname $MO`
  mkdir -p "$SUB_DIR"

  echo "Transpiling $KU > $MO"
  ./dist/kusanagi < "$KU" > "$MO"
done


SRC_DIR="./testku"
DEST_DIR="./test"

for KU in `find $SRC_DIR -type f -name "*.ku.mo"`; do
  FILE="${KU#$SRC_DIR}"
  NAME="${FILE%.ku.mo}"

  MO="$DEST_DIR$NAME.mo"

  SUB_DIR=`dirname $MO`
  mkdir -p "$SUB_DIR"

  echo "Transpiling $KU > $MO"
  ./dist/kusanagi < "$KU" > "$MO"
done
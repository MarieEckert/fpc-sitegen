#!/usr/bin/env bash

set -e

readonly SOURCE='src/sitegen.pas'
readonly INC_DIRS='sad/src/'
readonly BUILD_ROOT='build/'
readonly DEBUG_DIR="${BUILD_ROOT}debug/"
readonly RELEASE_DIR="${BUILD_ROOT}release/"
readonly OBJ_DIRNAME='obj'

readonly BASE_FLAGS="-l- -v0"
readonly DEBUG_FLAGS='-gl'
readonly RELEASE_FLAGS='-XX -Xs'

echo_exec() {
  echo "  "$1
  eval $1
}

build() {
  if [[ ! -d "$1" ]]; then
    mkdir -p "$1"
  fi

  echo_exec "fpc ${SOURCE} -FE"'"'"$1"'"'" -Fu"'"'"${INC_DIRS}"'"'" ${BASE_FLAGS} $2"

  echo_exec "mv $1/sitegen $1/../fpc-sitegen"
}

if [[ "$1" = 'release' ]]; then
  build "${RELEASE_DIR}${OBJ_DIRNAME}" "${RELEASE_FLAGS}"
else
  build "${DEBUG_DIR}${OBJ_DIRNAME}" "${DEBUG_FLAGS}"
fi

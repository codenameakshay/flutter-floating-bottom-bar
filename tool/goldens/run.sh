#!/usr/bin/env bash
# Checks or regenerates the goldens on the pinned setup: Linux x86_64 with the
# Flutter version from .fvmrc, in the image built from tool/goldens/Dockerfile.
#
#   tool/goldens/run.sh check     # what `make goldens` runs
#   tool/goldens/run.sh update    # what `make goldens-update` runs
#
# GOLDENS_DOCKER=0 runs on this machine instead of in Docker. It refuses unless
# the machine is Linux x86_64 with the pinned Flutter on PATH.
set -euo pipefail

mode=${1:-}
[[ $mode == check || $mode == update ]] || { echo "usage: $0 check|update" >&2; exit 64; }

repo=$(cd "$(dirname "$0")/../.." && pwd)
version=$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' "$repo/.fvmrc")

if [[ ${FFBB_IN_GOLDEN_RUN:-} != 1 && ${GOLDENS_DOCKER:-1} != 0 ]]; then
  # The tag follows the Dockerfile, so an edit to it rebuilds the image.
  image="ffbb-goldens:$(git -C "$repo" hash-object tool/goldens/Dockerfile | cut -c1-12)"
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker build --platform linux/amd64 -t "$image" "$repo/tool/goldens" >&2
  fi
  tty=(); [[ -t 1 ]] && tty=(-t)
  exec docker run --rm ${tty[@]+"${tty[@]}"} --platform linux/amd64 \
    -e FFBB_IN_GOLDEN_RUN=1 -e "HOST_IDS=$(id -u):$(id -g)" \
    -v "$repo:/src" -v ffbb-goldens-pub-cache:/opt/pub-cache \
    "$image" /src/tool/goldens/run.sh "$mode"
fi

src=$repo
actual="$(uname -s) $(uname -m) $(flutter --version --machine | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p')"
if [[ $actual != "Linux x86_64 $version" ]]; then
  echo "Goldens need Linux x86_64 with Flutter $version, found $actual." >&2
  echo "Run them in Docker: make goldens" >&2
  exit 1
fi

# Test a copy, so the host's .dart_tool, build and pubspec.lock stay untouched.
work=$(mktemp -d)
tar -C "$src" --exclude=./.git --exclude=./.dart_tool --exclude=./build \
  --exclude=./example --exclude=./pubspec.lock --exclude=./test/goldens/failures \
  -cf - . | tar -C "$work" -xf -
cd "$work"

# The package does not commit a lockfile, so goldens keep their own: a new
# material_ui release must not change the pixels between two runs.
lock=tool/goldens/pubspec.lock
[[ -f $lock ]] && cp "$lock" pubspec.lock
if [[ $mode == update ]]; then
  flutter pub get
  rm -f test/goldens/*.png
else
  flutter pub get --enforce-lockfile
fi

export FFBB_GOLDENS=pinned
code=0
if [[ $mode == update ]]; then
  flutter test --tags golden --update-goldens test/goldens || code=$?
else
  flutter test --tags golden test/goldens || code=$?
fi

copied=()
[[ $code == 0 ]] && rm -rf "$src/test/goldens/failures"
if [[ $mode == update && $code == 0 ]]; then
  rm -f "$src"/test/goldens/*.png
  cp test/goldens/*.png "$src/test/goldens/"
  cp pubspec.lock "$src/$lock"
  copied=("$src"/test/goldens/*.png "$src/$lock")
  if [[ -f test/goldens/gallery.json ]]; then
    cp test/goldens/gallery.json "$src/test/goldens/"
    copied+=("$src/test/goldens/gallery.json")
  fi
elif [[ -d test/goldens/failures ]]; then
  rm -rf "$src/test/goldens/failures"
  cp -R test/goldens/failures "$src/test/goldens/failures"
  copied=("$src/test/goldens/failures")
  echo "Diffs: test/goldens/failures/" >&2
fi
if [[ -n ${HOST_IDS:-} && ${#copied[@]} -gt 0 ]]; then
  chown -R "$HOST_IDS" "${copied[@]}" 2>/dev/null || true
fi
exit $code

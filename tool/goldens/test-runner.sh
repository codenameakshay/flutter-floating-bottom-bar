#!/usr/bin/env bash
# Exercise the golden runner with a fake Flutter command, without Docker.
set -euo pipefail

source_repo=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
goldens="$repo/test/goldens"
runner="$repo/tool/goldens/run.sh"
lock="$repo/tool/goldens/pubspec.lock"
mkdir -p "$goldens" "$repo/tool/goldens" "$tmp/bin" "$tmp/workdirs"
cp "$source_repo/.fvmrc" "$repo/.fvmrc"
cp "${1:-$source_repo/tool/goldens/run.sh}" "$runner"
printf 'original-lock\n' >"$lock"
printf 'original-png\n' >"$goldens/original.png"
printf 'original-manifest\n' >"$goldens/gallery.json"

export GOLDENS_DOCKER=0 HOST_IDS=123:456
export TMPDIR="$tmp/workdirs" PATH="$tmp/bin:$PATH"
export TEST_VERSION TEST_ARGS="$tmp/test-args" CHOWN_ARGS="$tmp/chown-args"
TEST_VERSION=$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' "$repo/.fvmrc")

cat >"$tmp/bin/uname" <<'EOF'
#!/usr/bin/env bash
case $1 in
  -s) echo Linux ;;
  -m) echo x86_64 ;;
  *) exit 2 ;;
esac
EOF
cat >"$tmp/bin/flutter" <<'EOF'
#!/usr/bin/env bash
case $1 in
  --version) printf '{"frameworkVersion":"%s"}\n' "$TEST_VERSION" ;;
  pub)
    [[ -f pubspec.lock ]] || exit 27
    exit "${PUB_STATUS:-0}"
    ;;
  test)
    printf '%s\n' "$*" >"$TEST_ARGS"
    case $RUN_RESULT in
      fail)
        mkdir -p test/goldens/failures
        printf 'current\n' >test/goldens/failures/current.txt
        exit 19
        ;;
      incomplete|update)
        printf 'updated-png\n' >test/goldens/updated.png
        printf 'updated-lock\n' >pubspec.lock
        if [[ $RUN_RESULT == update ]]; then
          printf 'updated-manifest\n' >test/goldens/gallery.json
        fi
        ;;
    esac
    ;;
  *) exit 2 ;;
esac
EOF
cat >"$tmp/bin/chown" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CHOWN_ARGS"
EOF
chmod +x "$tmp/bin/"*

run_expect() {
  local expected=$1 mode=$2 status=0
  bash "$runner" "$mode" || status=$?
  [[ $status == "$expected" ]] || {
    echo "Expected $mode exit $expected, got $status." >&2
    exit 1
  }
  [[ -z $(find "$TMPDIR" -mindepth 1 -print -quit) ]] || {
    echo 'Runner left a temporary work copy behind.' >&2
    exit 1
  }
}

mark_stale() {
  mkdir -p "$goldens/failures"
  printf 'stale\n' >"$goldens/failures/stale.txt"
}

mark_stale
TEST_VERSION=0.0.0 run_expect 1 check
[[ -f "$goldens/failures/stale.txt" ]]
mv "$lock" "$tmp/original-lock"
run_expect 1 check
[[ -f "$goldens/failures/stale.txt" ]]
mv "$tmp/original-lock" "$lock"

PUB_STATUS=23 run_expect 23 check
[[ ! -e "$goldens/failures" && ! -e "$CHOWN_ARGS" ]]

mark_stale
RUN_RESULT=fail run_expect 19 check
[[ ! -e "$goldens/failures/stale.txt" ]]
[[ $(<"$goldens/failures/current.txt") == current ]]
[[ $(<"$TEST_ARGS") == 'test -j 2 --no-pub --tags golden test/goldens' ]]
[[ $(<"$CHOWN_ARGS") == "-R 123:456 $goldens/failures" ]]

RUN_RESULT=incomplete run_expect 1 update
[[ $(<"$goldens/original.png") == original-png ]]
[[ $(<"$goldens/gallery.json") == original-manifest ]]
[[ $(<"$lock") == original-lock ]]
[[ ! -e "$goldens/updated.png" ]]

RUN_RESULT=update run_expect 0 update
[[ ! -e "$goldens/original.png" ]]
[[ $(<"$goldens/updated.png") == updated-png ]]
[[ $(<"$goldens/gallery.json") == updated-manifest ]]
[[ $(<"$lock") == updated-lock ]]
[[ $(<"$TEST_ARGS") == 'test -j 2 --no-pub --tags golden --update-goldens test/goldens' ]]
echo 'Golden runner guards, cleanup, and copy-back passed.'

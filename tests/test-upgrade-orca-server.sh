#!/usr/bin/env bash
# 업그레이드 스크립트의 .bashrc 백업·제거·복구를 격리 환경에서 검증한다.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo/scripts/upgrade-orca-server
root=$(mktemp -d "${TMPDIR:-/tmp}/orca-upgrade-test.XXXXXXXX")
trap 'rm -rf -- "$root"' EXIT

version=1.4.272
case $(uname -m) in
    aarch64|arm64) arch=arm64 ;;
    x86_64|amd64) arch=x64 ;;
    *) printf 'unsupported architecture\n' >&2; exit 1 ;;
esac
archive=orca-server-linux-$arch.tar.gz
digest=$(printf '%s' "$version-$arch" | sha256sum | cut -d' ' -f1)

fixtures=$root/fixtures
stubs=$root/stubs
mkdir -p "$fixtures" "$stubs"

fail() { printf 'not ok - %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$*"; }
assert_eq() { cmp -s -- "$1" "$2" || fail "$3"; }
assert_has() { grep -qF -- "$2" "$1" || fail "$3"; }
assert_lacks() { ! grep -qF -- "$2" "$1" || fail "$3"; }

# 실제 배포물과 같은 모양의 최소 패키지를 만든다.
pkg=$fixtures/package
mkdir -p "$pkg/bin" "$pkg/orcad/out/cli" "$pkg/runtimes/node-$digest/bin"
cat > "$pkg/bin/orca-ide" <<'EOF'
#!/usr/bin/env bash
set -eu
if [[ ${ORCA_TEST_FAIL_INSTALLED:-0} == 1 && $0 == "$ORCA_TEST_INSTALL_DIR/bin/orca-ide" ]]; then
    printf '0.0.0\n'
else
    printf '%s\n' "$ORCA_TEST_VERSION"
fi
EOF
cat > "$pkg/orcad/.runtime-node" <<EOF
$digest
EOF
cat > "$pkg/runtimes/node-$digest/bin/node" <<'EOF'
#!/usr/bin/env bash
set -eu
if [[ ${1:-} == --version || ( ${1:-} == *index.js && ${*: -1} == --version ) ]]; then
    printf '%s\n' "$ORCA_TEST_VERSION"
    exit 0
fi
if [[ ${1:-} == -e ]]; then
    input=$(cat)
    grep -q '"running":[[:space:]]*false' <<<"$input"
    grep -q '"state":[[:space:]]*"not_running"' <<<"$input"
    exit 0
fi
exit 1
EOF
printf 'console.log("orca cli");\n' > "$pkg/orcad/out/cli/index.js"
chmod 700 "$pkg/bin/orca-ide" "$pkg/runtimes/node-$digest/bin/node"
tar -czf "$fixtures/$archive" -C "$fixtures" package
sha256sum "$fixtures/$archive" | awk -v name="$archive" '{ print $1 "  " name }' \
    > "$fixtures/orca-server-sha256sums.txt"

# 네트워크와 sudo를 대체한다. mv 스텁은 .bashrc 교체 순간의 내용을 기록한다.
cat > "$stubs/curl" <<'EOF'
#!/usr/bin/env bash
set -eu
out= url=
while (( $# )); do
    case $1 in
        --output) out=$2; shift 2 ;;
        *) url=$1; shift ;;
    esac
done
[[ -n $out && -n $url ]] || exit 1
cp -- "$ORCA_TEST_FIXTURE_DIR/${url##*/}" "$out"
EOF
cat > "$stubs/sudo" <<'EOF'
#!/usr/bin/env bash
set -eu
if [[ ${1:-} == -v ]]; then exit 0; fi
cmd=${1:-}
case $cmd in
    test) shift; exec /usr/bin/test "$@" ;;
    mktemp) shift; exec /usr/bin/mktemp "$@" ;;
    mv) shift; exec /usr/bin/mv "$@" ;;
    cp)
        shift
        if [[ ${ORCA_TEST_TERM_AT:-} == sudo-copy ]]; then
            /usr/bin/kill -TERM "$PPID"
            /usr/bin/sleep 1
        fi
        exec /usr/bin/cp "$@" ;;
    *) printf 'unexpected sudo %s\n' "$cmd" >&2; exit 1 ;;
esac
EOF
cat > "$stubs/mv" <<'EOF'
#!/usr/bin/env bash
set -eu
dest=${@: -1}
if [[ ${ORCA_TEST_LOG_DIR:-} && $dest == "$HOME/.bashrc" ]]; then
    /usr/bin/mv "$@"
    n=$(/usr/bin/find "$ORCA_TEST_LOG_DIR" -maxdepth 1 -type f -name 'bashrc-move-*' | /usr/bin/wc -l)
    n=$((n))
    /usr/bin/cp -- "$HOME/.bashrc" "$ORCA_TEST_LOG_DIR/bashrc-move-$n"
    if /usr/bin/grep -qF '# >>> orca-server-autostart' "$HOME/.bashrc"; then
        /usr/bin/printf 'present\n' >> "$ORCA_TEST_LOG_DIR/bashrc-moves.log"
    else
        /usr/bin/printf 'absent\n' >> "$ORCA_TEST_LOG_DIR/bashrc-moves.log"
    fi
else
    exec /usr/bin/mv "$@"
fi
EOF
chmod 700 "$stubs/curl" "$stubs/sudo" "$stubs/mv"

plan=$(env PATH="$stubs:$PATH" "$script" --plan "$version")
assert_has <(printf '%s\n' "$plan") 'backs up ~/.bashrc' 'plan describes the automatic backup'
pass 'plan output describes automatic .bashrc backup and restore'

setup_case() {
    case_dir=$root/$1
    mkdir -p "$case_dir/home" "$case_dir/install" "$case_dir/log" "$case_dir/tmp"
    export HOME=$case_dir/home
    install_dir=$case_dir/install
    mkdir -p "$install_dir/bin" "$install_dir/orcad/out/cli" \
        "$install_dir/runtimes/node-$digest/bin"
    cp "$pkg/bin/orca-ide" "$install_dir/bin/orca-ide"
    cp "$pkg/runtimes/node-$digest/bin/node" "$install_dir/runtimes/node-$digest/bin/node"
    printf 'original install\n' > "$install_dir/marker"

    profile=$HOME/.config/orca
    mkdir -p "$profile/cli/bin" "$profile/logs"
    cat > "$profile/cli/bin/orca" <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == status && ${2:-} == --json ]]; then
    printf '%s\n' '{"ok":true,"result":{"app":{"running":false},"runtime":{"state":"not_running"}}}'
fi
EOF
    chmod 700 "$profile/cli/bin/orca"
    cp "$profile/cli/bin/orca" "$case_dir/original-wrapper"
}

write_bashrc() {
    case $1 in
        block)
            cat > "$HOME/.bashrc" <<'EOF'
# user config
export EDITOR=vi
# >>> orca-server-autostart (UserLAnd) >>>
orca_autostart_placeholder
# <<< orca-server-autostart (UserLAnd) <<<
# tail
EOF
            ;;
        plain)
            printf '# user config\nexport EDITOR=vi\n' > "$HOME/.bashrc"
            ;;
        duplicate-start)
            cat > "$HOME/.bashrc" <<'EOF'
# >>> orca-server-autostart (UserLAnd) >>>
# >>> orca-server-autostart (UserLAnd) >>>
# <<< orca-server-autostart (UserLAnd) <<<
EOF
            ;;
        missing-end)
            printf '# >>> orca-server-autostart (UserLAnd) >>>\n' > "$HOME/.bashrc"
            ;;
        reversed)
            cat > "$HOME/.bashrc" <<'EOF'
# <<< orca-server-autostart (UserLAnd) <<<
# >>> orca-server-autostart (UserLAnd) >>>
EOF
            ;;
        *) fail "unknown bashrc fixture: $1" ;;
    esac
    chmod 644 "$HOME/.bashrc"
}

prepare_work() {
    local out
    out=$(env PATH="$stubs:$PATH" TMPDIR="$case_dir/tmp" \
        ORCA_TEST_FIXTURE_DIR="$fixtures" ORCA_TEST_LOG_DIR="$case_dir/log" \
        ORCA_TEST_VERSION="$version" \
        "$script" --prepare "$version")
    work=$(sed -n 's/.*WORKDIR=//p' <<<"$out")
    [[ -n $work ]] || fail "prepare did not print WORKDIR: $out"
}

apply_work() {
    [[ $install_dir == "$case_dir/"* ]] || fail 'refusing to target an install outside the test case'
    env PATH="$stubs:$PATH" TMPDIR="$case_dir/tmp" \
        ORCA_TEST_FIXTURE_DIR="$fixtures" ORCA_TEST_LOG_DIR="$case_dir/log" \
        ORCA_TEST_VERSION="$version" ORCA_TEST_INSTALL_DIR="$install_dir" \
        ORCA_UPGRADE_INSTALL_DIR="$install_dir" \
        ORCA_TEST_FAIL_INSTALLED="${FAIL_INSTALLED:-0}" \
        ORCA_TEST_TERM_AT="${TERM_AT:-}" \
        "$script" --apply "$version" "$work" > "$case_dir/log/out" 2>&1
}

check_block_cycle() {
    assert_eq "$HOME/.bashrc" "$case_dir/original-bashrc" 'bashrc matches the original after apply'
    assert_has "$case_dir/log/out" 'Bashrc backup:' 'bashrc backup path is printed'
    assert_has "$case_dir/log/out" 'Bashrc restored:' 'bashrc restore is printed'
    [[ $(cat "$case_dir/log/bashrc-moves.log") == $'absent\npresent' ]] \
        || fail 'autostart block was not removed then restored'
    assert_eq "$work"/backup.*/bashrc "$case_dir/original-bashrc" 'backup keeps the original bashrc'
}

# (a) 블록이 있는 상태에서 성공: 제거 후 원본으로 복구된다.
setup_case success
write_bashrc block
cp "$HOME/.bashrc" "$case_dir/original-bashrc"
prepare_work
FAIL_INSTALLED=0 TERM_AT=
apply_work || { cat "$case_dir/log/out"; fail 'apply with an autostart block failed'; }
check_block_cycle
[[ ! -e $install_dir/marker ]] || fail 'new install was not switched'
assert_has "$profile/cli/bin/orca" 'ORCA_USER_DATA_PATH' 'CLI wrapper was switched'
pass 'success: block removed, install switched, bashrc restored'

# (b) 전환 중 실패: 설치·래퍼 롤백과 함께 bashrc도 복구된다.
setup_case failure
write_bashrc block
cp "$HOME/.bashrc" "$case_dir/original-bashrc"
prepare_work
FAIL_INSTALLED=1 TERM_AT=
if apply_work; then fail 'expected apply to fail on version mismatch'; fi
assert_has "$case_dir/log/out" 'Installed launcher version mismatch' 'failure reason is reported'
check_block_cycle
[[ -e $install_dir/marker ]] || fail 'install was not rolled back'
assert_eq "$profile/cli/bin/orca" "$case_dir/original-wrapper" 'wrapper was rolled back'
pass 'failure: install, wrapper, and bashrc rolled back'

# (c) SIGTERM: 시그널 종료 경로에서도 bashrc가 복구된다.
setup_case signal
write_bashrc block
cp "$HOME/.bashrc" "$case_dir/original-bashrc"
prepare_work
FAIL_INSTALLED=0 TERM_AT=sudo-copy
if apply_work; then fail 'expected apply to be interrupted'; fi
assert_has "$case_dir/log/out" 'Bashrc restored:' 'bashrc restore runs on TERM'
check_block_cycle
[[ -e $install_dir/marker ]] || fail 'install was not rolled back after TERM'
assert_eq "$profile/cli/bin/orca" "$case_dir/original-wrapper" 'wrapper was rolled back after TERM'
pass 'SIGTERM: bashrc restored and install rolled back'
TERM_AT=

# (d) 블록이 없는 .bashrc는 그대로 두고 정상 동작한다.
setup_case no-block
write_bashrc plain
cp "$HOME/.bashrc" "$case_dir/original-bashrc"
prepare_work
FAIL_INSTALLED=0 TERM_AT=
apply_work || { cat "$case_dir/log/out"; fail 'apply without an autostart block failed'; }
assert_eq "$HOME/.bashrc" "$case_dir/original-bashrc" 'plain bashrc is unchanged'
assert_lacks "$case_dir/log/out" 'Bashrc backup:' 'no bashrc backup without a block'
assert_lacks "$case_dir/log/out" 'Bashrc restored:' 'no bashrc restore without a block'
[[ ! -e $case_dir/log/bashrc-moves.log ]] || fail 'bashrc was rewritten without a block'
pass 'no block: apply succeeds and leaves bashrc untouched'

# (e) 마커가 불완전하거나 중복이면 파일을 바꾸지 않고 거부한다.
setup_case malformed
prepare_work
for variant in duplicate-start missing-end reversed; do
    write_bashrc "$variant"
    cp "$HOME/.bashrc" "$case_dir/original-bashrc"
    if apply_work; then fail "expected malformed markers ($variant) to be rejected"; fi
    assert_has "$case_dir/log/out" 'Malformed Orca autostart block' "malformed markers ($variant) reported"
    assert_eq "$HOME/.bashrc" "$case_dir/original-bashrc" "malformed markers ($variant) leave bashrc unchanged"
    assert_eq "$profile/cli/bin/orca" "$case_dir/original-wrapper" "malformed markers ($variant) leave wrapper unchanged"
    [[ -e $install_dir/marker ]] || fail "malformed markers ($variant) changed the install"
    [[ -z $(find "$work" -maxdepth 1 -name 'backup.*' -print -quit) ]] \
        || fail "malformed markers ($variant) created a backup"
    [[ -z $(find "$work" -maxdepth 1 -name 'stage.*' -print -quit) ]] \
        || fail "malformed markers ($variant) created a stage"
done
pass 'malformed or duplicate markers rejected before any file change'

printf 'all upgrade-orca-server tests passed\n'

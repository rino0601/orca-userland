# UserLAnd에서 Ubuntu 시작하고 Orca 서버 켜기

UserLAnd의 Ubuntu 세션에 Orca 서버를 설치하고, 새 터미널을 열 때 서버가 저절로 켜지게 만든다. 끝나면 새 대화형 세션에 자동으로 출력되는 링크로 휴대폰의 Orca 앱을 연결한다.

## 1. Ubuntu 세션 만들기

UserLAnd에서 **Ubuntu**를 고르고, 세션 이름을 `ubuntu`, 사용자 이름을 `userland`로 해서 만든다. 세션을 시작한 뒤 **Terminal**을 연다.

```sh
whoami
pwd
```

→ `userland`, `/home/userland`

## 2. 필요한 패키지 설치

UserLAnd 기본 이미지에는 C 링커(`cc`)가 없다. 그대로 두면 pyo3/maturin으로 Rust 확장을 빌드할 때 `error: linker 'cc' not found`로 실패한다. `build-essential`이 `gcc`/`cc`/`ld`/`ar`을 제공하므로 함께 설치한다.

```sh
sudo apt update
sudo apt install -y curl ca-certificates git util-linux build-essential
```

```sh
curl --version | head -1
flock --version
cc --version | head -1
```

→ curl 버전, `flock (util-linux) ...`, `cc (Ubuntu ...) ...` 출력

`apt`는 터미널에서 쓰는 권장 명령이다. `apt-get`은 예전 저수준 명령으로 스크립트에서 여전히 쓰인다.

### 프로세스 모니터: htop (권장, 선택)

필수는 아니지만 UserLAnd에서 프로세스를 볼 때 `htop`을 권장한다.

```sh
sudo apt install htop
```

```sh
htop --version
```

→ `htop 3.4.1 ...` 출력

`btop` 대신 `htop`을 권장하는 이유는 [UserLAnd/PRoot 환경](../explanation/userland-proot.md)에 있다.

## 3. mise 설치

```sh
curl -fsSL https://mise.run | sh
```

설치가 끝나면 설치기가 셸 활성화 방법을 안내한다. 이 기기의 셸은 bash이고 mise는 `~/.local/bin/mise`에 설치되므로 다음 한 줄이 출력된다.

```
mise: run the following to activate mise in your shell:
echo "eval \"\$($HOME/.local/bin/mise activate bash)\"" >> ~/.bashrc

mise: run `mise doctor` to verify this is set up correctly
```

이 줄을 `~/.bashrc`에 넣으면 새 셸을 열거나 프로젝트 디렉터리로 이동할 때 `mise.toml`에 고정한 도구 버전이 자동으로 활성화된다. 넣지 않으면 `mise use`로 지정한 uv 같은 버전이 PATH에 자동으로 잡히지 않는다. 출력된 명령을 실행하고 `source`로 지금 셸에 적용한다(새 터미널을 열어도 된다). 마지막으로 `mise doctor`로 확인한다.

```sh
echo "eval \"\$($HOME/.local/bin/mise activate bash)\"" >> ~/.bashrc
source ~/.bashrc
mise doctor
```

```sh
~/.local/bin/mise --version
```

→ 버전 번호

## 4. 코딩 에이전트 설치하기

원하는 도구를 하나 이상 선택해 설치하세요. `opencode`만, `codex`만, 또는 둘 다 설치할 수 있다. 둘 다 터미널에서 쓰는 코딩 에이전트이고, 어느 쪽을 골라도 뒤 단계는 같다.

### 4.1 opencode

```sh
curl -fsSL https://opencode.ai/install | bash
```

```sh
~/.opencode/bin/opencode --version
```

→ 버전 번호

### 4.2 codex

```sh
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

```sh
~/.local/bin/codex --version
```

→ 버전 번호

## 5. gh 설치

```sh
arch=$(dpkg --print-architecture)
version=2.105.0
curl -fL https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${arch}.tar.gz -o /tmp/gh.tar.gz
tar -xzf /tmp/gh.tar.gz -C /tmp
install -m 755 /tmp/gh_${version}_linux_${arch}/bin/gh $HOME/.local/bin/gh
```

```sh
gh --version
gh auth status
```

→ `gh version 2.105.0 ...`, `You are not logged into any GitHub hosts.`

## 6. Orca 서버 설치

```sh
arch=$(uname -m | sed 's/x86_64/x64/; s/aarch64/arm64/')
base=https://github.com/stablyai/orca/releases/latest/download
curl -fsSLO "$base/orca-server-linux-$arch.tar.gz" -O "$base/orca-server-sha256sums.txt"
sha256sum --check --ignore-missing orca-server-sha256sums.txt
sudo mkdir -p /opt/orca-server
sudo tar -xzf "orca-server-linux-$arch.tar.gz" -C /opt/orca-server --strip-components=1
```

```sh
/opt/orca-server/bin/orca-ide --version
```

→ 버전 번호

## 7. `orca` 명령 만들기

`status`/`pair`용으로 데이터를 `~/.config/orca`에 두는 `orca` 명령을 만든다.

```sh
mkdir -p ~/.config/orca/cli/bin
cat > ~/.config/orca/cli/bin/orca <<'EOF'
#!/usr/bin/env sh
set -eu
export ORCA_USER_DATA_PATH='/home/userland/.config/orca'
unset NODE_OPTIONS NODE_REPL_EXTERNAL_MODULE ELECTRON_RUN_AS_NODE
exec '/opt/orca-server/runtimes/node-c8c5721679d8d1a09e9987e345d5f9a64899bb85f7a384783ba8a93e6e62348a/bin/node' '/opt/orca-server/orcad/out/cli/index.js' "$@"
EOF
chmod 700 ~/.config/orca/cli/bin/orca
echo 'export PATH="$HOME/.config/orca/cli/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.config/orca/cli/bin:$PATH"
```

```sh
orca --version
orca status --json | grep -E '"running"|"pid"'
```

→ 버전 번호, `"running": false`

이 래퍼는 `status`/`pair`에 쓴다. `serve`에는 쓰지 않는다. 두 CLI의 역할 차이는 [serve 런처와 앱 컨텍스트](../explanation/serve-launcher.md)에 있다.

## 8. GitHub 로그인

```sh
gh auth login
```

**GitHub.com → HTTPS → Login with a web browser**를 고르고, 나오는 코드를 브라우저에서 승인한다.

```sh
gh auth status
```

→ `Logged in to github.com account ...`

## 9. 서버 수동으로 실행하기

```sh
/opt/orca-server/bin/orca-ide serve --refuse-public --pairing-address 127.0.0.1
```

첫 번째 터미널에 출력된 **bound endpoint**의 주소와 포트를 메모한다. 이 터미널은 그대로 두고 두 번째 터미널을 연다.

```sh
orca status --json | grep -E '"running"|"pid"'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:6768/
```

→ `"running": true`와 PID 번호, HTTP 응답 코드. 서버 전용 설치에는 웹 페이지가 없으므로 `404`가 나와도 정상이다.

새 대화형 세션에서는 10단계 블록이 서버 시작 직후 `orca://` 링크 한 줄을 출력한다. 지금 링크를 다시 받으려면 다음을 실행한다.

```sh
orca pair --mobile --address 127.0.0.1
```

→ `The client will connect to ws://127.0.0.1:6768.`와 `orca://` 링크 한 줄이 출력된다.

첫 번째 터미널에서 `Ctrl-C`로 서버를 멈춘다.

## 10. 터미널을 열면 자동으로 켜지게 하기

### 10.1 `.bashrc` 백업

```sh
cp ~/.bashrc ~/.bashrc.bak-$(date +%Y%m%d-%H%M%S)-orca-autostart
```

### 10.2 자동 실행 스크립트 만들기

```sh
mkdir -p ~/.config/orca/logs
cat > ~/.config/orca/autostart-orca-serve.sh <<'EOF'
#!/usr/bin/env sh
# Auto-start the local Orca runtime server from an interactive UserLAnd Bash.
#
# Design notes (verified on this device, 2026-11-21):
#   - The CLI wrapper ~/.config/orca/cli/bin/orca is for status/pair only. It
#     unsets ELECTRON_RUN_AS_NODE, so `orca serve` through it fails with
#     "This `orca` command isn't running from an installed Orca app" (LU()).
#   - To start the server we use the release launcher /opt/orca-server/bin/orca-ide,
#     which sets ELECTRON_RUN_AS_NODE=1 so serve passes its app-context check.
#   - The server is started without --bind so Orca may widen it for mobile
#     pairing, and with --refuse-public so public (non-LAN) clients are denied:
#       orca-ide serve --refuse-public --pairing-address 127.0.0.1
#     It advertises 127.0.0.1, reachable from the phone app on this same
#     Android device (PRoot shares the network namespace). --mobile-pairing is
#     omitted; get the link with `orca pair --mobile --address 127.0.0.1`.
#   - fd 9 (the flock lock) is closed in the detached child; otherwise the
#     long-lived server inherits it and locks out every later autostart run.
#   - `orca serve` already refuses to start a second server for this profile
#     (exit 3). We keep that as the final safety net and add our own checks.
#
# This script is idempotent: it never stops, restarts or signals an existing
# Orca server. It only starts one when none is serving this profile.

set -u

ORCA_BIN="${HOME}/.config/orca/cli/bin/orca"
ORCA_SERVE_BIN="/opt/orca-server/bin/orca-ide"
LOG_DIR="${HOME}/.config/orca/logs"
LOG_FILE="${LOG_DIR}/orca-autostart.log"
LOCK_FILE="${LOG_DIR}/orca-autostart.lock.v2"

[ -x "$ORCA_BIN" ] || exit 0
[ -x "$ORCA_SERVE_BIN" ] || exit 0
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

stamp() { date '+%Y-%m-%d %H:%M:%S %z'; }

# Serialise simultaneous terminal openings so they cannot race into serve.
exec 9>"$LOCK_FILE" 2>/dev/null || exit 0
flock -n 9 || exit 0

# Fast, supported check: is this profile already being served?
# `orca status` asks the running runtime; it does not start anything.
status_json="$("$ORCA_BIN" status --json 2>/dev/null || true)"
if printf '%s' "$status_json" | grep -q '"running":[[:space:]]*true'; then
    pid="$(printf '%s' "$status_json" \
        | sed -n 's/.*"pid"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' \
        | head -1)"
    printf '%s autostart: server already serving this profile (pid %s); no action\n' \
        "$(stamp)" "${pid:-unknown}" >>"$LOG_FILE" 2>/dev/null
    printf 'existing %s\n' "${pid:-unknown}"
    exit 0
fi

# Nothing running. Start detached: new session (setsid), ignore SIGHUP (nohup),
# stdin from /dev/null and both output streams appended to the log file. This
# way closing the UserLAnd terminal cannot kill the server or leave it holding
# the terminal's pts/stdout.
printf '%s autostart: no server found, starting: orca-ide serve --refuse-public --pairing-address 127.0.0.1\n' \
    "$(stamp)" >>"$LOG_FILE" 2>/dev/null
printf 'started\n'

nohup setsid --fork "$ORCA_SERVE_BIN" serve --refuse-public --pairing-address 127.0.0.1 \
    </dev/null 9>&- >>"$LOG_FILE" 2>&1 &

exit 0
EOF
chmod 700 ~/.config/orca/autostart-orca-serve.sh
touch ~/.config/orca/logs/orca-autostart.log
chmod 600 ~/.config/orca/logs/orca-autostart.log
```

```sh
ls -l ~/.config/orca/autostart-orca-serve.sh ~/.config/orca/logs/orca-autostart.log
```

→ 스크립트는 `-rwx------`, 로그는 `-rw-------`

### 10.3 `.bashrc`에 블록 추가

```sh
cat >> ~/.bashrc <<'EOF'
# >>> orca-server-autostart (UserLAnd) >>>
# Starts the local Orca runtime server once when an interactive Bash opens,
# reports whether it started a new server or found an existing one, shows the
# server log path, then prints only the orca:// pairing link in this terminal.
# Idempotent: an already-running server is left untouched. Disable by removing
# this whole block.
if [ -x "$HOME/.config/orca/autostart-orca-serve.sh" ]; then
    _orca_autostart="$("$HOME/.config/orca/autostart-orca-serve.sh" 2>/dev/null)"
    case "$_orca_autostart" in
        existing*) printf 'Orca: 기존 서버 사용 (pid %s)\n' "${_orca_autostart#existing }" ;;
        started*)  printf 'Orca: 서버를 새로 시작했습니다\n' ;;
    esac
    printf 'Orca 서버 로그: ~/.config/orca/logs/ (orca-autostart.log, daemon.log, orcad.trace.ndjson)\n'
    unset _orca_autostart
fi
if [ -x "$HOME/.config/orca/cli/bin/orca" ]; then
    for _orca_i in 1 2 3 4 5 6 7 8 9 10; do
        "$HOME/.config/orca/cli/bin/orca" status --json 2>/dev/null |
            grep -q '"running":[[:space:]]*true' && break
        sleep 0.3
    done
    "$HOME/.config/orca/cli/bin/orca" pair --mobile --address 127.0.0.1 --json 2>/dev/null |
        sed -n 's/.*"pairingUrl": "\([^"]*\)".*/\1/p' || true
    unset _orca_i
fi
# <<< orca-server-autostart (UserLAnd) <<<
EOF
```

```sh
tail -n 26 ~/.bashrc
```

→ 방금 넣은 마커 블록이 맨 아래에 있다.

### 10.4 새 터미널에서 자동 실행 확인

새 터미널을 연다.

```sh
orca status --json | grep -E '"running"|"pid"'
tail -n 1 ~/.config/orca/logs/orca-autostart.log
```

→ 터미널에 `Orca: 서버를 새로 시작했습니다`와 `Orca 서버 로그: ~/.config/orca/logs/ ...` 두 줄이 먼저 출력되고, 이어서 `orca://` 링크 한 줄이 나온다. 이미 떠 있는 서버라면 첫 줄 대신 `Orca: 기존 서버 사용 (pid ...)`가 나온다. `"running": true`와 PID 번호, `no server found, starting:` 로그도 보인다.

### 10.5 중복 실행 확인

터미널을 두 번 더 연다.

```sh
tail -n 3 ~/.config/orca/logs/orca-autostart.log
orca status --json | grep -E '"running"|"pid"'
```

→ 매번 `already serving this profile (pid ...); no action`이 쌓이고 PID는 그대로다.

## 11. 전체 검증

새 터미널을 세 번 연다. 매번 다음을 실행한다. curl 주소에는 9단계에서 확인한 포트를 쓴다.

```sh
orca status --json | grep -E '"running"|"pid"'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:6768/
tail -n 1 ~/.config/orca/logs/orca-autostart.log
```

→ PID가 항상 같고 HTTP 응답 코드가 나오며, 로그에는 `already serving ... no action`만 쌓인다.

## 다음 읽을거리

- 설치한 서버의 버전 바꾸기: [Orca 서버 업그레이드](../how-to/upgrade-orca-server.md)

- 링크 다시 발급·강제 갱신: [모바일 페어링 링크 다시 얻기](../how-to/get-mobile-pairing-link.md)
- 자동 실행을 끄거나 되돌리기: [자동 실행 끄기·되돌리기](../how-to/disable-autostart.md)
- 문제가 생겼을 때: [서버가 안 뜰 때 진단하기](../how-to/diagnose-server-not-starting.md)
- 플래그·경로·버전의 정확한 값: [CLI와 serve 플래그](../reference/cli-and-serve.md), [경로와 버전](../reference/paths-and-versions.md)
- 왜 이렇게 구성했는가: [Diátaxis 4분류 개요](../explanation/diataxis.md), [serve 런처와 앱 컨텍스트](../explanation/serve-launcher.md)

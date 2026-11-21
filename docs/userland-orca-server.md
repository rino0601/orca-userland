# UserLAnd에서 Ubuntu 시작하고 Orca 서버 켜기

UserLAnd의 Ubuntu 세션에 Orca 서버를 설치하고, 새 터미널을 열 때 서버가 저절로 켜지게 만든다. 끝나면 새 대화형 세션에 자동으로 출력되는 링크로 휴대폰의 Orca 앱을 연결한다.

## 1. Ubuntu 세션 만들기

UserLAnd에서 **Ubuntu**를 고르고, 세션 이름을 `ubuntu`, 사용자 이름을 `userland`로 해서 만든다. 세션을 시작한 뒤 **Terminal**을 연다.

어떻게 확인하는가

```sh
whoami
pwd
```

→ `userland`, `/home/userland`

## 2. 필요한 패키지 설치

```sh
sudo apt update
sudo apt install -y curl ca-certificates git util-linux
```

어떻게 확인하는가

```sh
curl --version | head -1
flock --version
```

→ curl 버전과 `flock (util-linux) ...` 출력

## 3. mise 설치

```sh
curl -fsSL https://mise.run | sh
```

어떻게 확인하는가

```sh
~/.local/bin/mise --version
```

→ 버전 번호

## 4. opencode 설치

```sh
curl -fsSL https://opencode.ai/install | bash
```

어떻게 확인하는가

```sh
~/.opencode/bin/opencode --version
```

→ 버전 번호

## 5. gh 설치

이 시스템에서는 더 높은 버전을 위해 릴리즈에서 직접 받는다.

```sh
arch=$(dpkg --print-architecture)
version=2.105.0
curl -fL https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${arch}.tar.gz -o /tmp/gh.tar.gz
tar -xzf /tmp/gh.tar.gz -C /tmp
install -m 755 /tmp/gh_${version}_linux_${arch}/bin/gh $HOME/.local/bin/gh
```

어떻게 확인하는가

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

어떻게 확인하는가

```sh
/opt/orca-server/bin/orca-ide --version
```

→ 버전 번호

## 7. `orca` 명령 만들기

서버 전용 설치의 CLI는 `orca-ide`다. 데이터를 `~/.config/orca`에 두는 `orca` 명령을 만든다.

```sh
mkdir -p ~/.config/orca/cli/bin
cat > ~/.config/orca/cli/bin/orca <<'EOF'
#!/usr/bin/env sh
set -eu
export ORCA_USER_DATA_PATH="$HOME/.config/orca"
exec /opt/orca-server/bin/orca-ide "$@"
EOF
chmod 700 ~/.config/orca/cli/bin/orca
echo 'export PATH="$HOME/.config/orca/cli/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.config/orca/cli/bin:$PATH"
```

어떻게 확인하는가

```sh
orca --version
orca status --json | grep -E '"running"|"pid"'
```

→ 버전 번호, `"running": false`

## 8. GitHub 로그인

Orca의 에이전트가 저장소와 PR을 다루려면 이 기기에서 GitHub에 로그인해 있어야 한다.

```sh
gh auth login
```

**GitHub.com → HTTPS → Login with a web browser**를 고르고, 나오는 코드를 브라우저에서 승인한다.

어떻게 확인하는가

```sh
gh auth status
```

→ `Logged in to github.com account ...`

## 9. 서버 수동으로 실행하기

```sh
orca-ide serve --bind 127.0.0.1 --pairing-address 127.0.0.1
```

평범한 UserLAnd 터미널에서는 `orca` 래퍼가 `ELECTRON_RUN_AS_NODE`를 해제하므로 `serve`에 쓸 수 없다. 설치된 앱 런처인 `orca-ide`를 쓴다. Orca 앱 자체 터미널처럼 `ORCA_APP_EXECUTABLE`이 설정된 곳이라면 `orca serve`도 동작한다.

`--pairing-address`는 클라이언트에 알려지는 주소이고, 서버가 실제로 듣는 인터페이스는 `--bind`가 정한다. Orca가 `--mobile-pairing needs --bind 0.0.0.0 (or no --bind); a narrower --bind cannot serve the mobile pairing offer`라고 거부하므로 좁은 bind와 함께 못 쓴다.

첫 번째 터미널에 출력된 **bound endpoint**의 주소와 포트를 메모한다. 이 터미널은 그대로 두고 두 번째 터미널을 연다.

어떻게 확인하는가 (두 번째 터미널)

```sh
orca status --json | grep -E '"running"|"pid"'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:6768/
```

→ `"running": true`와 PID 번호, HTTP 응답 코드. 서버 전용 설치에는 웹 페이지가 없으므로 `404`가 나와도 정상이다.

`--port`를 쓰지 않으면 6768을 사용하지만 6768이 이미 점유되면 다른 포트로 이동한다. 메모한 포트가 6768이 아니면 curl 주소의 포트를 그 값으로 바꿔서 확인한다. 6768로 고정하려면 `orca-ide serve --port 6768 ...`을 쓰고, 이때 6768이 점유되면 서버가 에러로 끝난다.

### 페어링 링크 얻기

10단계의 `.bashrc` 블록을 넣으면 새 대화형 세션을 열 때 서버 자동 실행 직후 `orca://` 링크 한 줄이 그 터미널에 출력된다. 비대화형 셸에서는 출력되지 않는다.

서버를 재시작하지 않고 다시 받으려면 다음을 실행한다.

```sh
orca pair --mobile --address 127.0.0.1
```

강제로 새 offer를 만들려면 `--rotate`를 붙인다.

```sh
orca pair --mobile --address 127.0.0.1 --rotate
```

어떻게 확인하는가

→ `The client will connect to ws://127.0.0.1:6768.`와 `orca://` 링크 한 줄이 출력된다. QR 아스키가 필요하면 `orca pair --mobile`을 직접 실행한다.

첫 번째 터미널에서 `Ctrl-C`로 서버를 멈춘다.

## 10. 터미널을 열면 자동으로 켜지게 하기

### 10.1 `.bashrc` 백업

```sh
cp ~/.bashrc ~/.bashrc.bak-orca-autostart
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
#   - The server is started on the loopback interface only:
#       orca-ide serve --bind 127.0.0.1 --pairing-address 127.0.0.1
#     It listens on 127.0.0.1:6768 (default port) and advertises that address.
#     --mobile-pairing is deliberately omitted: Orca rejects it with any
#     --bind other than 0.0.0.0. Get a mobile link after start with
#     `orca pair --mobile --address 127.0.0.1` instead.
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
LOCK_FILE="${LOG_DIR}/orca-autostart.lock"

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
    exit 0
fi

# Nothing running. Start detached: new session (setsid), ignore SIGHUP (nohup),
# stdin from /dev/null and both output streams appended to the log file. This
# way closing the UserLAnd terminal cannot kill the server or leave it holding
# the terminal's pts/stdout.
printf '%s autostart: no server found, starting: orca-ide serve --bind 127.0.0.1 --pairing-address 127.0.0.1\n' \
    "$(stamp)" >>"$LOG_FILE" 2>/dev/null

nohup setsid --fork "$ORCA_SERVE_BIN" serve --bind 127.0.0.1 --pairing-address 127.0.0.1 \
    </dev/null >>"$LOG_FILE" 2>&1 &

exit 0
EOF
chmod 700 ~/.config/orca/autostart-orca-serve.sh
touch ~/.config/orca/logs/orca-autostart.log
chmod 600 ~/.config/orca/logs/orca-autostart.log
```

`status`/`pair`는 래퍼로 충분하지만 `serve`는 설치된 앱 런처(`orca-ide`)가 필요하다. 래퍼가 `ELECTRON_RUN_AS_NODE`를 해제하면 LU()의 앱 컨텍스트 검사를 통과하지 못하므로, 그대로 두면 재시작 때 서버가 뜨지 않는다.

어떻게 확인하는가

```sh
ls -l ~/.config/orca/autostart-orca-serve.sh ~/.config/orca/logs/orca-autostart.log
```

→ 스크립트는 `-rwx------`, 로그는 `-rw-------`

### 10.3 `.bashrc`에 블록 추가

```sh
cat >> ~/.bashrc <<'EOF'
# >>> orca-server-autostart (UserLAnd) >>>
# Starts the local Orca runtime server once when an interactive Bash opens,
# then prints only the orca:// pairing link in this terminal.
# Idempotent: an already-running server is left untouched. Disable by removing
# this whole block (backup: ~/.bashrc.bak-orca-autostart).
if [ -x "$HOME/.config/orca/autostart-orca-serve.sh" ]; then
    "$HOME/.config/orca/autostart-orca-serve.sh" >/dev/null 2>&1
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

`--json` 출력에는 `qr` 필드도 있으므로, `pairingUrl`만 추출해 링크 한 줄만 출력한다.

어떻게 확인하는가

```sh
tail -n 19 ~/.bashrc
```

→ 방금 넣은 마커 블록이 맨 아래에 있다.

### 10.4 새 터미널에서 자동 실행 확인

새 터미널을 연다.

```sh
orca status --json | grep -E '"running"|"pid"'
tail -n 1 ~/.config/orca/logs/orca-autostart.log
```

→ 터미널에 `orca://` 링크 한 줄이 자동으로 출력되고, `"running": true`와 PID 번호, `no server found, starting:` 로그가 보인다.

### 10.5 중복 실행 확인

터미널을 두 번 더 연다.

```sh
tail -n 3 ~/.config/orca/logs/orca-autostart.log
orca status --json | grep -E '"running"|"pid"'
```

→ 매번 `already serving this profile (pid ...); no action`이 쌓이고 PID는 그대로다.

### 10.6 해제하고 원복하기

```sh
cp ~/.bashrc.bak-orca-autostart ~/.bashrc
```

→ 새 터미널을 열어도 자동 실행 스크립트가 돌지 않는다. 이미 떠 있는 서버는 그대로다.

## 11. 전체 검증

새 터미널을 세 번 연다. 매번 다음을 실행한다. curl 주소에는 9단계에서 확인한 포트를 쓴다.

```sh
orca status --json | grep -E '"running"|"pid"'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:6768/
tail -n 1 ~/.config/orca/logs/orca-autostart.log
```

→ PID가 항상 같고 HTTP 응답 코드가 나오며, 로그에는 `already serving ... no action`만 쌓인다.

비대화형 셸은 로그를 남기지 않는다.

```sh
bash -c '. ~/.bashrc; true'
tail -n 1 ~/.config/orca/logs/orca-autostart.log
```

→ 로그 줄이 늘지 않는다.

## 주의사항

- 페어링 링크는 비밀번호처럼 취급한다. 화면 공유·채팅·이슈에 붙여넣지 않는다.
- `--rotate` 전까지 같은 offer가 재사용되므로 새 터미널을 열어도 같은 링크가 나온다.
- 서버 시작 출력과 페어링 링크는 로그와 셸 기록에 남을 수 있다(예: `~/.config/orca/logs/orca-autostart.log`). 로그 권한(600)을 유지하고 함부로 공유하지 않는다.
- 자동 출력을 끄려면 `.bashrc`의 시작/끝 마커 블록을 지우거나 백업으로 원복한다. 이미 떠 있는 서버는 죽지 않는다.
- 링크는 서버 재시작 시 갱신된다. 문서에 미리 적어 둔 코드는 없다.

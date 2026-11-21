# UserLAnd에서 Ubuntu 시작하고 Orca 서버 켜기

UserLAnd의 Ubuntu 세션에 Orca 서버를 설치하고, 새 터미널을 열 때 서버가 저절로 켜지게 만든다. 끝나면 서버가 시작할 때 출력하는 새 링크로 휴대폰의 Orca 앱을 연결한다.

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

```sh
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh
```

어떻게 확인하는가

```sh
gh --version
```

→ `gh version ...`

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
orca serve --mobile-pairing --pairing-address 127.0.0.1
```

`--pairing-address`는 클라이언트에 알려지는 주소이고, 서버가 실제로 듣는 인터페이스는 `--bind`가 정한다. 여기서는 `--bind`를 쓰지 않으므로 모든 인터페이스에서 듣는다. `--mobile-pairing`은 출력되는 링크를 모바일용 QR/링크로 바꾸는 옵션이다.

첫 번째 터미널에 출력된 **bound endpoint**의 주소와 포트를 메모한다. QR 코드와 페어링 링크도 여기서 출력된다. 이 터미널은 그대로 두고 두 번째 터미널을 연다.

어떻게 확인하는가 (두 번째 터미널)

```sh
orca status --json | grep -E '"running"|"pid"'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:6768/
```

→ `"running": true`와 PID 번호, HTTP 응답 코드. 서버 전용 설치에는 웹 페이지가 없으므로 `404`가 나와도 정상이다.

`--port`를 쓰지 않으면 6768을 사용하지만 6768이 이미 점유되면 다른 포트로 이동한다. 메모한 포트가 6768이 아니면 curl 주소의 포트를 그 값으로 바꿔서 확인한다. 6768로 고정하려면 `orca serve --port 6768 ...`을 쓰고, 이때 6768이 점유되면 서버가 에러로 끝난다.

### 페어링 링크 얻기

serve가 출력하는 링크는 시작할 때마다 새로 만들어진다. 문서에 미리 적어 둔 코드는 없으므로 방금 출력된 QR 또는 링크만 사용한다. 나중에 다시 필요하면 서버를 재시작하지 않고 새 링크를 만든다.

```sh
orca pair --mobile --address 127.0.0.1
```

어떻게 확인하는가

→ 새 QR 코드와 `orca://` 링크가 출력된다.

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
# Design notes:
#   - The installed CLI wrapper is ~/.config/orca/cli/bin/orca and it execs
#     /opt/orca-server/.../orcad/out/cli/index.js with ORCA_USER_DATA_PATH set.
#   - The server that was being run manually is:
#       orca serve --mobile-pairing --pairing-address 127.0.0.1
#     Without --port it uses 6768 and moves to another port when 6768 is taken,
#     so read the bound endpoint printed at startup. It binds 0.0.0.0 internally,
#     which is what makes 127.0.0.1 work from the same Android device (PRoot
#     shares the Android network namespace).
#   - `orca serve` already refuses to start a second server for this profile
#     (exit 3). We keep that as the final safety net and add our own checks.
#
# This script is idempotent: it never stops, restarts or signals an existing
# Orca server. It only starts one when none is serving this profile.

set -u

ORCA_BIN="${HOME}/.config/orca/cli/bin/orca"
LOG_DIR="${HOME}/.config/orca/logs"
LOG_FILE="${LOG_DIR}/orca-autostart.log"
LOCK_FILE="${LOG_DIR}/orca-autostart.lock"

[ -x "$ORCA_BIN" ] || exit 0
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
printf '%s autostart: no server found, starting: orca serve --mobile-pairing --pairing-address 127.0.0.1\n' \
    "$(stamp)" >>"$LOG_FILE" 2>/dev/null

nohup setsid --fork "$ORCA_BIN" serve --mobile-pairing --pairing-address 127.0.0.1 \
    </dev/null >>"$LOG_FILE" 2>&1 &

exit 0
EOF
chmod 700 ~/.config/orca/autostart-orca-serve.sh
touch ~/.config/orca/logs/orca-autostart.log
chmod 600 ~/.config/orca/logs/orca-autostart.log
```

어떻게 확인하는가

```sh
ls -l ~/.config/orca/autostart-orca-serve.sh ~/.config/orca/logs/orca-autostart.log
```

→ 스크립트는 `-rwx------`, 로그는 `-rw-------`

### 10.3 `.bashrc`에 블록 추가

```sh
cat >> ~/.bashrc <<'EOF'
# >>> orca-server-autostart (UserLAnd) >>>
# Starts the local Orca runtime server once when an interactive Bash opens.
# Idempotent: an already-running server is left untouched. Disable by removing
# these three lines (backup: ~/.bashrc.bak-orca-autostart).
if [ -x "$HOME/.config/orca/autostart-orca-serve.sh" ]; then
    "$HOME/.config/orca/autostart-orca-serve.sh" >/dev/null 2>&1
fi
# <<< orca-server-autostart (UserLAnd) <<<
EOF
```

어떻게 확인하는가

```sh
tail -n 8 ~/.bashrc
```

→ 방금 넣은 마커 블록이 맨 아래에 있다.

### 10.4 새 터미널에서 자동 실행 확인

새 터미널을 연다.

```sh
orca status --json | grep -E '"running"|"pid"'
tail -n 1 ~/.config/orca/logs/orca-autostart.log
```

→ `"running": true`와 PID 번호, `no server found, starting:` 로그

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

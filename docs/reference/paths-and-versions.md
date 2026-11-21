# 경로와 버전 레퍼런스

이 문서는 Orca 서버가 사용하는 파일·로그 경로와 이 저장소 도구의 버전을 기술한다.

## 파일과 로그 경로

| 이름 | 경로 | 권한 | 설명 |
| --- | --- | --- | --- |
| 자동 실행 스크립트 | `~/.config/orca/autostart-orca-serve.sh` | `700` (`-rwx------`) | 대화형 셸에서 서버를 한 번 시작한다. 이미 떠 있으면 아무 동작도 하지 않는다. |
| lock v2 | `~/.config/orca/logs/orca-autostart.lock.v2` | `600` | `flock -n 9`이 잡는 락 파일. 동시 터미널 열기를 직렬화한다. |
| 자동 실행 로그 | `~/.config/orca/logs/orca-autostart.log` | `600` (`-rw-------`) | `starting:` / `already serving ... no action` 상태 마커를 남긴다. |
| 데몬 로그 | `~/.config/orca/logs/daemon.log` | `600` | 데몬의 오류·실패 메시지. |
| 추적 로그 | `~/.config/orca/logs/orcad.trace.ndjson` | `600` | orcad 이벤트의 NDJSON 스트림. |
| CLI 래퍼 | `~/.config/orca/cli/bin/orca` | `700` | `status`/`pair` 전용 래퍼. |
| serve 런처 | `/opt/orca-server/bin/orca-ide` | `755` | 릴리즈 기본 런처. serve에 사용한다. |
| `.bashrc` 마커 블록 | `~/.bashrc`의 `# >>> orca-server-autostart (UserLAnd) >>>` ~ `# <<< orca-server-autostart (UserLAnd) <<<` | `644` | 대화형 셸에서 상태 메시지와 `pairingUrl` 한 줄을 출력한다. 비대화형 셸은 무영향. |
| `.bashrc` 백업 | `~/.bashrc.bak-<YYYYMMDD>-<HHMMSS>-<라벨>` | `644` | 설치 시 타임스탬프로 생성. 예: `~/.bashrc.bak-20261121-072207-status`. |

자동 실행 스크립트의 상태 마커는 표준출력으로 `existing <pid>` 또는 `started`를 내보낸다. `.bashrc` 블록은 이를 `Orca: 기존 서버 사용 (pid ...)` 또는 `Orca: 서버를 새로 시작했습니다`로 바꿔 출력한다.

## 도구 버전

| 도구 | 버전 | 확인 명령 |
| --- | --- | --- |
| mise | `2026.11.10` | `~/.local/bin/mise --version` |
| uv | `0.13.9` | `uv --version` |
| Python | `3.13.18` | `uv run python --version` |
| zensical | `0.1.3` | `uv run zensical --version` |
| prek | `0.5.11` | `uv run prek --version` |
| gh | `2.105.0` | `gh --version` |
| opencode | `2.3.2` | `~/.opencode/bin/opencode --version` |
| orca-ide | `1.4.267` | `/opt/orca-server/bin/orca-ide --version` |

이 시스템은 UserLAnd 위 Ubuntu 26.04.1 LTS arm64다. gh는 apt가 아니라 `gh_2.105.0_linux_arm64.tar.gz` 릴리즈를 `curl`로 받아 설치한다.

## 현재 서버 프로세스

| 항목 | 값 |
| --- | --- |
| serve 프로세스 | `/opt/orca-server/bin/orca-ide serve --refuse-public --pairing-address 127.0.0.1` (`--bind` 없음) |
| orcad 바인드 | 필요할 때 `0.0.0.0`으로 확장 |
| 광고 주소 | `127.0.0.1` |
| 공인 요청 | `--refuse-public`로 거부 |
| 모바일 offer | `available: true`, `scope: mobile`, `endpoint: ws://127.0.0.1:6768`, `connectionMode: local-only` |

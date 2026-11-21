# CLI와 serve 플래그 레퍼런스

이 문서는 Orca 서버 관련 명령 경로, `serve` 플래그, 환경 변수의 값을 기술한다.

## CLI 경로

| 이름 | 경로 | 용도 | 예시 |
| --- | --- | --- | --- |
| `orca` | `~/.config/orca/cli/bin/orca` | `status`/`pair` 전용. `ELECTRON_RUN_AS_NODE`를 해제한다. | `orca status --json` |
| `orca-ide` (PATH 래퍼) | `~/.config/orca/cli/bin/orca-ide` | `orca`와 같은 래퍼. `serve`에 쓰면 exit 1. | `orca-ide serve` → exit 1 |
| `orca-ide` (serve 런처) | `/opt/orca-server/bin/orca-ide` | `serve` 런처. `ELECTRON_RUN_AS_NODE=1`을 설정한다. 절대경로로 호출한다. | `/opt/orca-server/bin/orca-ide serve --refuse-public --pairing-address 127.0.0.1` |

`~/.config/orca/cli/bin`이 PATH 앞에 있으므로 `serve`에는 절대경로가 필요하다.

## serve 플래그

현재 서버 실행 명령: `/opt/orca-server/bin/orca-ide serve --refuse-public --pairing-address 127.0.0.1`

| 이름 | 기본값 | 설명 | 예시 |
| --- | --- | --- | --- |
| `--refuse-public` | 없음(플래그) | 공인 IP 요청을 강제 거부한다. localhost/LAN/Tailscale은 허용한다. | `--refuse-public` |
| `--allow-public` | 없음(플래그) | 공인 요청을 허용한다. `--refuse-public`과 반대 방향. | `--allow-public` |
| `--pairing-address` | 없음 | 페어링에 광고할 주소. 현재 값은 `127.0.0.1`. | `--pairing-address 127.0.0.1` |
| `--port` | `6768` | 바인드 포트. 6768이 점유되면 다른 포트로 이동한다. 명시하면 고정되고 점유 시 오류로 끝난다. | `--port 6768` |
| `--bind` | 없음(생략) | 바인드 호스트. 이 설정에서는 생략한다. 특정 IP로 고정하면 orcad의 widened bind가 거부된다. | 사용하지 않음 |
| `--mobile-pairing` | 없음(플래그) | 모바일 페어링을 serve 단계에서 처리한다. 이 환경에서는 bind와 양립 불가. | 사용하지 않음 |

`--bind`를 지정한 값이 `0.0.0.0`이 아니면 orcad의 `pinnedBindHost`가 고정되어 widen이 거부되고 모바일 페어링이 `network_exposure_failed`가 된다. 현재 orcad 프로세스는 필요할 때 `0.0.0.0`으로 넓힌다.

## pair 플래그

| 이름 | 기본값 | 설명 | 예시 |
| --- | --- | --- | --- |
| `--mobile` | 없음(플래그) | 모바일 범위의 offer를 만든다. | `orca pair --mobile --address 127.0.0.1` |
| `--address` | 없음 | offer의 endpoint 주소. | `--address 127.0.0.1` |
| `--rotate` | 없음(플래그) | 같은 offer 재사용을 중단하고 새 offer를 만든다. | `orca pair --mobile --address 127.0.0.1 --rotate` |
| `--json` | 없음(플래그) | `pairingUrl`, `available`, `scope`, `endpoint`, `qr` 등을 JSON으로 출력한다. | `orca pair --mobile --address 127.0.0.1 --json` |

`pairingUrl`은 `available: true`, `scope: mobile`, `endpoint: ws://127.0.0.1:6768`로 발급된다. 정적 링크는 없고 서버 시작마다 갱신된다.

## 환경 변수와 조건

| 이름 | 값 | 설명 | 예시 |
| --- | --- | --- | --- |
| `ELECTRON_RUN_AS_NODE` | 래퍼에서 해제, serve 런처에서 `1` | 앱 컨텍스트 검사(LU())에 영향을 준다. | `unset ELECTRON_RUN_AS_NODE` |
| `ORCA_APP_EXECUTABLE` | 앱 자체 터미널에서 설정 | 설정된 곳에서는 `orca serve`도 동작한다. | Orca 앱 터미널 |
| `ORCA_USER_DATA_PATH` | `/home/userland/.config/orca` | CLI가 읽는 데이터 경로. 래퍼가 내보낸다. | `export ORCA_USER_DATA_PATH='...'` |
| `NODE_OPTIONS` | 래퍼에서 해제 | 래퍼가 `serve`와 `status`/`pair`를 분리할 때 정리한다. | `unset NODE_OPTIONS` |
| `NODE_REPL_EXTERNAL_MODULE` | 래퍼에서 해제 | 위와 같다. | `unset NODE_REPL_EXTERNAL_MODULE` |

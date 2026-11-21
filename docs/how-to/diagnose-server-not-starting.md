# 서버가 안 뜰 때 진단하기

`orca status`가 `"running": false`일 때 원인을 순서대로 좁혀 서버가 뜨게 만든다.

전제 조건: [튜토리얼](../tutorials/userland-orca-server.md)의 설치가 끝나 있었고, 갑자기 서버가 뜨지 않는다.

## 1. 실제 상태 확인

```sh
orca status --json | grep -E '"running"|"pid"'
```

예상 결과: `"running": true`면 진단 끝. `"running": false`면 2단계로.

## 2. 래퍼를 serve에 쓰지 않았는지 확인

```sh
orca-ide serve --refuse-public --pairing-address 127.0.0.1; echo "exit=$?"
```

예상 결과: `exit=1`. PATH의 `orca-ide`도 래퍼라 serve가 안 된다. 릴리즈 런처 절대경로를 쓴다.

```sh
/opt/orca-server/bin/orca-ide serve --refuse-public --pairing-address 127.0.0.1
```

예상 결과: `bound endpoint`가 출력되고 서버가 붙는다. 성공하면 5단계로.

## 3. 실행 중인 프로세스 확인

```sh
ps -eo pid,args | grep -E 'orcad|orca-ide' | grep -v grep
```

예상 결과: `serve --refuse-public --pairing-address 127.0.0.1` 프로세스와, 넓혀진 `--bind 0.0.0.0` orcad 프로세스가 보인다.

## 4. 자동 실행 로그 확인

```sh
tail -n 20 ~/.config/orca/logs/orca-autostart.log
grep -iE 'error|failed|network_exposure_failed' ~/.config/orca/logs/daemon.log | tail -n 20
```

예상 결과: `starting:` 직후 실패 흔적이 보이면 해당 원인을 처리한다. `network_exposure_failed`가 나오면 serve 명령에 `--bind`가 들어가지 않았는지 확인한다.

## 5. 포트 확인

```sh
orca status --json | grep -E '"port"|"running"'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:6768/
```

예상 결과: HTTP 응답 코드. 6768이 점유되면 서버가 다른 포트로 이동하므로 상태의 포트 값으로 curl 주소를 바꿔 다시 시도한다.

## 성공 확인

```sh
orca status --json | grep -E '"running"|"pid"'
orca pair --mobile --address 127.0.0.1 --json | grep -E '"available"|"scope"'
```

→ `"running": true`, PID 번호, `"available": true`, `"scope": "mobile"`.

자주 나오는 원인의 배경은 [serve 런처와 앱 컨텍스트](../explanation/serve-launcher.md), [모바일 페어링과 네트워크 노출](../explanation/mobile-pairing-network.md), [flock 락과 idempotent 자동 실행](../explanation/flock-autostart.md)에 있다.

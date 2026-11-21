# 서버 로그에서 상태·오류 확인하기

`~/.config/orca/logs/`의 로그를 읽어 Orca 서버의 상태와 최근 오류를 확인한다.

전제 조건: 서버가 한 번 이상 실행되어 로그 디렉터리가 만들어져 있다.

## 1. 로그 파일 확인

```sh
ls -l ~/.config/orca/logs/
```

예상 결과: `orca-autostart.log`, `daemon.log`, `orcad.trace.ndjson`, `orca-autostart.lock.v2`가 보인다.

## 2. 자동 실행 기록 보기

```sh
tail -n 10 ~/.config/orca/logs/orca-autostart.log
```

예상 결과: `no server found, starting:` 또는 `already serving this profile (pid ...); no action` 줄이 타임스탬프와 함께 나온다.

## 3. 데몬 오류 검색

```sh
grep -iE 'error|failed|fatal' ~/.config/orca/logs/daemon.log | tail -n 20
```

예상 결과: 오류가 있으면 해당 줄이 나오고, 없으면 출력이 비어 있다.

## 4. 추적 이벤트 확인

```sh
tail -n 5 ~/.config/orca/logs/orcad.trace.ndjson | tail -c 2000
```

예상 결과: JSON 줄이 NDJSON 형식으로 출력된다.

## 성공 확인

서버가 살아 있는지는 로그와 별개로 상태로 확인한다.

```sh
orca status --json | grep -E '"running"|"pid"'
```

→ `"running": true`와 PID 번호. 로그 필드의 정확한 경로와 용도는 [경로와 버전](../reference/paths-and-versions.md)에 있다. 서버가 `"running": false`면 [서버가 안 뜰 때 진단하기](diagnose-server-not-starting.md)로 간다.

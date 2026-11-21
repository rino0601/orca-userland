# 자동 실행 다시 켜기

꺼져 있던 터미널 자동 실행을 다시 켜서 새 대화형 세션에서 서버가 저절로 뜨게 한다.

전제 조건: `~/.config/orca/autostart-orca-serve.sh`와 `~/.config/orca/cli/bin/orca`가 이미 설치되어 있다(처음 설치는 [튜토리얼](../tutorials/userland-orca-server.md)).

## 1. 마커 블록 확인

```sh
grep -c 'orca-server-autostart' ~/.bashrc
```

예상 결과: `2`(시작 마커와 끝 마커). `0`이면 2단계로 간다.

## 2. 블록이 없으면 다시 추가

백업에서 복원하거나, 백업이 없으면 튜토리얼의 [10.3단계](../tutorials/userland-orca-server.md) 블록을 `~/.bashrc` 끝에 다시 붙여넣는다.

```sh
ls -1 ~/.bashrc.bak-* | tail -1
```

예상 결과: 타임스탬프가 붙은 백업 파일 경로(예: `~/.bashrc.bak-20261121-072207-status`).

## 3. 스크립트 실행 권한 확인

```sh
chmod 700 ~/.config/orca/autostart-orca-serve.sh
ls -l ~/.config/orca/autostart-orca-serve.sh
```

예상 결과: `-rwx------`.

## 4. 새 터미널에서 확인

새 터미널을 연다.

```sh
orca status --json | grep -E '"running"|"pid"'
tail -n 1 ~/.config/orca/logs/orca-autostart.log
```

예상 결과: 터미널에 `Orca: 서버를 새로 시작했습니다` 또는 `Orca: 기존 서버 사용 (pid ...)`, 로그 경로 줄, `orca://` 링크 한 줄이 출력되고 `"running": true`가 나온다.

## 성공 확인

마커 블록이 `2`줄 있고 새 대화형 세션에서 위 출력이 나오면 자동 실행이 켜진 것이다. 동작 원리는 [flock 락과 idempotent 자동 실행](../explanation/flock-autostart.md)에 있다.

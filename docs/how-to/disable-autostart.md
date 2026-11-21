# 자동 실행 끄기·되돌리기

새 터미널에서 서버가 저절로 뜨지 않게 자동 실행을 끄고 `.bashrc`를 백업 상태로 되돌린다.

전제 조건: 설치 때 만든 타임스탬프 백업(예: `~/.bashrc.bak-20261121-072207-status`)이 있다.

## 1. 복원할 백업 고르기

```sh
ls -1 ~/.bashrc.bak-*
```

예상 결과: 타임스탬프가 붙은 백업 파일 목록. 자동 실행을 넣기 직전의 것을 고른다.

## 2. `.bashrc` 원복

```sh
cp ~/.bashrc.bak-20261121-072207-status ~/.bashrc
```

예상 결과: 화면 출력 없이 끝난다. 파일 이름은 1단계에서 고른 것으로 바꾼다.

## 3. 마커 블록이 사라졌는지 확인

```sh
grep -c 'orca-server-autostart' ~/.bashrc || true
```

예상 결과: `0`.

## 성공 확인

새 터미널을 연다. `Orca: ...` 줄과 `orca://` 링크가 출력되지 않으면 자동 실행이 꺼진 것이다.

```sh
grep -c 'orca-server-autostart' ~/.bashrc || true
orca status --json | grep -E '"running"|"pid"'
```

이미 떠 있는 서버는 그대로다. 이 절차는 서버를 죽이지 않는다. 중복 실행을 막는 방식은 [flock 락과 idempotent 자동 실행](../explanation/flock-autostart.md)에 있다.

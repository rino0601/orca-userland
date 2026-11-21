# 모바일 페어링 링크 다시 얻기

서버를 재시작하지 않고 휴대폰 Orca 앱을 연결할 `orca://` 링크를 다시 발급한다.

전제 조건: Orca 서버가 떠 있고(확인: [서버 상태 확인](check-server-logs.md)) `~/.config/orca/cli/bin/orca`가 실행 가능하다.

## 1. 링크 발급

```sh
orca pair --mobile --address 127.0.0.1
```

예상 결과: `The client will connect to ws://127.0.0.1:6768.`와 `orca://...` 링크 한 줄.

## 2. 새 offer로 강제 갱신

같은 offer를 버리고 새 링크가 필요할 때만 `--rotate`를 붙인다.

```sh
orca pair --mobile --address 127.0.0.1 --rotate
```

예상 결과: 이전과 다른 `orca://...` 링크 한 줄.

## 성공 확인

```sh
orca pair --mobile --address 127.0.0.1 --json | grep -E '"available"|"scope"|"endpoint"'
```

→ `"available": true`, `"scope": "mobile"`, `"endpoint": "ws://127.0.0.1:6768"`.

출력된 링크를 휴대폰 Orca 앱에 붙여넣으면 연결된다. 링크는 비밀번호처럼 다룬다. 링크가 갱신되는 시점과 노출 범위는 [모바일 페어링과 네트워크 노출](../explanation/mobile-pairing-network.md)에 있다.

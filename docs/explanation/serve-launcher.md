# 왜 serve에 래퍼가 아니라 릴리즈 런처 절대경로를 쓰는가

이 저장소에는 비슷한 이름의 `orca` 명령이 여럿 있다. 그중 `serve`에 어떤 것을 쓰는가가 가장 헷갈리는 부분인데, 그 이유는 앱 컨텍스트 검사와 환경 변수에 있다.

## 두 CLI의 역할 분리

`~/.config/orca/cli/bin/orca`는 `status`와 `pair`를 위해 만든 얇은 래퍼다. 이 래퍼는 `ORCA_USER_DATA_PATH`를 지정하고 `NODE_OPTIONS`, `NODE_REPL_EXTERNAL_MODULE`, `ELECTRON_RUN_AS_NODE`를 해제한 뒤 번들 Node로 `index.js`를 실행한다. 덕분에 서버가 떠 있는지 묻거나 링크를 발급하는 작업은 가볍게 처리된다.

하지만 바로 그 `unset ELECTRON_RUN_AS_NODE` 때문에 이 래퍼로 `serve`를 시작하면 실패한다. orcad의 serve 진입점은 LU()로 시작하는 앱 컨텍스트 검사를 수행하는데, 이 검사는 `ELECTRON_RUN_AS_NODE`가 설정되어 있어야 통과한다. 래퍼가 그 값을 지워 버리므로 "This `orca` command isn't running from an installed Orca app"이라는 오류가 나온다.

## 런처의 절대경로가 필요한 이유

`/opt/orca-server/bin/orca-ide`는 릴리즈가 제공하는 기본 런처다. 이 런처는 `ELECTRON_RUN_AS_NODE=1`을 설정해서 serve가 앱 컨텍스트 검사를 통과하게 만든다. 문제는 PATH 순서다. `~/.config/orca/cli/bin`이 PATH 앞에 있으므로 `orca-ide serve`라고 쓰면 설치된 런처가 아니라 같은 이름의 래퍼를 잡는다. 그 래퍼는 위와 같이 `ELECTRON_RUN_AS_NODE`를 해제하므로 exit 1이 난다.

그래서 serve는 항상 절대경로 `/opt/orca-server/bin/orca-ide`로 호출한다. 경로를 줄이면 "설치된 앱 런처"라는 정체성이 사라지고, 검사를 통과하지 못한다. 이 구분은 [CLI와 serve 플래그 레퍼런스](../reference/cli-and-serve.md)에 표로 정리되어 있다.

## ORCA_APP_EXECUTABLE이 설정된 경우

Orca 앱 자체 터미널처럼 `ORCA_APP_EXECUTABLE`이 설정된 곳에서는 `orca serve`도 동작한다. 앱이 컨텍스트를 직접 제공하므로 래퍼가 `ELECTRON_RUN_AS_NODE`를 해제했더라도 검사를 통과할 수 있기 때문이다. 일반 UserLAnd 터미널에는 이 값이 없으므로 절대경로 런처가 필요한 것이다.

자동 실행 스크립트가 `status`/`pair`에는 래퍼를, `serve`에는 절대경로 런처를 쓰는 것도 이 차이를 반영한다([flock 락과 idempotent 자동 실행](flock-autostart.md) 참고).

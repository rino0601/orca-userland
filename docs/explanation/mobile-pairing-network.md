# 모바일 페어링과 bind·공인 요청 필터 설계

서버 명령에 `--refuse-public`을 붙이고 `--bind`를 빼는 것은 임의의 선택이 아니다. 모바일 앱이 같은 기기에서 연결하는 방식과, Orcad가 네트워크 노출을 넓히는 규칙이 맞물린 결과다.

## 페어링은 광고 주소로 이루어진다

`orca pair --mobile --address 127.0.0.1`은 `127.0.0.1`을 endpoint로 광고하는 offer를 만든다. UserLAnd의 PRoot은 Android와 네임스페이스를 공유하므로, 같은 기기 위의 Orca 앱은 이 주소에 닿을 수 있다. 현재 발급되는 offer는 `available: true`, `scope: mobile`, `connectionMode: local-only`이며 endpoint는 `ws://127.0.0.1:6768`다.

여기서 중요한 점은 정적 링크가 없다는 것이다. 링크는 서버가 시작될 때마다 갱신되고, `--rotate`를 붙이기 전까지는 같은 offer가 재사용된다. 그래서 문서에 미리 적어 둔 `orca://` 코드가 통하지 않는다. 링크는 비밀번호처럼 취급해서 화면 공유나 채팅, 이슈에 붙여넣지 않는다([모바일 페어링 링크 다시 얻기](../how-to/get-mobile-pairing-link.md) 참고).

## 왜 --bind를 고정하면 안 되는가

Orcad는 모바일 클라이언트가 연결해야 할 때 바인드를 모든 인터페이스(`0.0.0.0`)로 넓힌다. 이때 내부적으로 `pinnedBindHost` 값을 검사한다. serve 명령에 `--bind <특정 IP>`를 주면 이 값이 `0.0.0.0`이 아닌 상태로 고정되고, Orcad는 widen을 거부한다. 결과는 `network_exposure_failed`로 모바일 페어링이 실패한다.

그래서 serve 명령에서는 `--bind`를 아예 생략한다. 고정된 값이 없어야 Orcad가 필요할 때 `0.0.0.0`으로 넓힐 여지가 생긴다. 현재 실제로 떠 있는 orcad 프로세스도 `--bind 0.0.0.0`으로 넓혀진 상태다. 이 규칙은 [CLI와 serve 플래그 레퍼런스](../reference/cli-and-serve.md)에도 적혀 있다.

`--mobile-pairing`을 serve 단계에서 함께 쓰지 않는 것도 같은 맥락이다. bind와 양립할 수 없으므로, 모바일 링크는 서버를 띄운 뒤 `orca pair --mobile`로 따로 받는다.

## 공인 요청은 왜 거부하는가

`--refuse-public`은 공인 IP에서 들어오는 요청을 강제로 거부한다. 반면 localhost와 LAN, Tailscale 같은 사설 경로는 허용한다. 광고 주소가 `127.0.0.1`이고 기기 안의 앱만 연결하면 되므로, 공인 노출은 이 시나리오에 필요가 없고 오히려 링크가 새는 순간 위험해진다.

공인 연결이 허용되는 경우는 따로 정해져 있다. `--allow-public`을 쓰거나, `--pairing-address`에 공인 주소를 주거나, 공인 주소로 페어링된 기기 기록이 있을 때다. 이 환경에서는 그런 조건이 없으므로 `--refuse-public`이 기본처럼 동작한다. 즉 "필요할 때만 안으로 넓히고, 바깥은 항상 막는다"는 쪽이 설계의 방향이다. 이 판단의 배경이 되는 실행 환경은 [UserLAnd/PRoot 환경](userland-proot.md)에 설명되어 있다.

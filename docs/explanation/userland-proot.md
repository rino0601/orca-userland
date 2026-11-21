# UserLAnd/PRoot 환경이 일반 Linux와 다른 이유

이 저장소의 명령들이 데스크톱 Ubuntu와 조금 다르게 동작하는 이유는 UserLAnd가 PRoot 위에서 Ubuntu를 돌리기 때문이다. 여기서는 그 차이가 서버 설정에 어떤 의미를 갖는지 정리한다.

## PRoot은 가상 머신이 아니다

UserLAnd의 Ubuntu는 커널을 따로 띄우지 않는다. Android 커널 위에서 PRoot이 `chroot` 비슷한 파일 시스템 뷰를 사용자 공간에서 만들어 낸다. 시스템 호출은 PRoot이 가로채서 경로를 바꿔 전달한다. 그래서 `apt`나 `curl`은 익숙하게 동작하지만, 진짜 부팅이나 커널 모듈 조작은 불가능하다. `sudo`가 의미 있는 것도 이 사용자 공간 안에서만이다.

이 차이 때문에 네임스페이스 격리도 기대만큼 강하지 않다. PRoot은 커널 네임스페이스를 새로 만들지 않고 Android 쪽과 자원을 공유한다. 서버가 `127.0.0.1`을 광고해도 휴대폰의 Orca 앱이 같은 Android 기기 안에서 그 주소에 닿을 수 있는 이유가 바로 이 공유다. 데스크톱에서는 `127.0.0.1`이 같은 머신 안의 프로세스만 볼 수 있지만, 여기서는 "같은 머신"의 경계가 Android 기기 전체로 넓어진다.

## arm64라는 사실

이 기기는 arm64(aarch64)다. 그래서 바이너리를 x86_64용으로 받으면 실행되지 않는다. `gh`를 apt가 아니라 `gh_2.105.0_linux_arm64.tar.gz` 릴리즈로 받는 것도 이 때문이다. Orca 서버 역시 `uname -m`을 `aarch64 → arm64`로 바꿔 릴리즈 자산 이름을 만든다. Node 런타임 경로에 해시가 붙는 것도 릴리즈가 아키텍처별로 번들되기 때문이다.

## 프로세스 모니터: btop과 htop

PRoot은 Android 커널의 파일 시스템 뷰를 그대로 노출하지 않는다. 커널이 채우는 `/sys`의 일부 경로는 UserLAnd 안에서 읽히지 않는다. btop은 시작할 때 `/sys/devices`를 순회하다가 `ERROR: Exception in Shared::init() -> filesystem error:directory iterator cannot open directory: Permission denied [/sys/devices]`로 끝나는 경우가 있다. 시각화가 좋아도 이 환경에서는 뜨지 않을 수 있다.

htop은 프로세스 정보를 주로 `/proc`에서 읽는다. 이 경로는 UserLAnd 안에서도 접근할 수 있으므로 htop은 같은 권한 문제 없이 프로세스를 보여 준다. UserLAnd에서 htop이 잘 맞는 이유가 여기에 있다. 설치 단계는 [튜토리얼](../tutorials/userland-orca-server.md)에 있다.

## 이 환경이 자동 실행 설계에 미치는 영향

로그인 셸이 매번 새로 만들어지는 모바일 터미널 특성상, 서버를 한 번 띄워 두고 재사용하는 편이 안정적이다. PRoot 세션이 닫히면 터미널이 죽고, 그 터미널이 서버를 붙잡고 있으면 서버도 같이 끊긴다. 그래서 자동 실행 스크립트는 `setsid`와 `nohup`으로 서버를 터미널에서 분리한다([flock 락과 idempotent 자동 실행](flock-autostart.md) 참고).

또한 새 터미널을 열 때마다 `.bashrc`가 실행되므로, 거기 넣은 블록이 방법이나 원리를 설명하는 대신 짧은 상태 메시지와 링크 한 줄만 출력하게 제한한 것이다. 이 환경의 아키텍처와 네임스페이스 공유를 이해하면 왜 `127.0.0.1` 광고와 공인 차단(`--refuse-public`)이 함께 쓰이는지도 자연스럽게 이해된다([모바일 페어링과 네트워크 노출](mobile-pairing-network.md) 참고).

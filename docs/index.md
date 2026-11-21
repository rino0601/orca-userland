# Orca Userland

mise가 uv를 설치·관리하고, uv가 Python 3.13과 zensical 의존성을 관리합니다.

```sh
mise install
uv sync
uv run zensical serve
```

문서는 Diátaxis 네 종류로 나뉩니다.

- **튜토리얼** — [UserLAnd에서 Orca 서버 시작하기](tutorials/userland-orca-server.md): 처음 설치부터 자동 실행까지 한 번에 따라 합니다.
- **실전 가이드** — 특정 목표를 위한 짧은 레시피: [모바일 링크 다시 얻기](how-to/get-mobile-pairing-link.md), [자동 실행 켜기](how-to/enable-autostart.md), [자동 실행 끄기](how-to/disable-autostart.md), [로그 확인](how-to/check-server-logs.md), [gh 설치](how-to/install-gh-from-release.md), [서버 진단](how-to/diagnose-server-not-starting.md).
- **레퍼런스** — 정확한 값: [CLI와 serve 플래그](reference/cli-and-serve.md), [경로와 버전](reference/paths-and-versions.md).
- **설명** — 왜 이렇게 되었는가: [Diátaxis 개요](explanation/diataxis.md), [UserLAnd/PRoot 환경](explanation/userland-proot.md), [serve 런처](explanation/serve-launcher.md), [모바일 페어링 설계](explanation/mobile-pairing-network.md), [flock과 자동 실행](explanation/flock-autostart.md).

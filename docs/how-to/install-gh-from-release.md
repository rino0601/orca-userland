# gh 바이너리를 GitHub 릴리즈로 설치하기

apt 저장소 대신 GitHub 릴리즈의 arm64 tarball을 받아 `gh` 2.105.0을 `~/.local/bin/gh`에 설치한다.

전제 조건: `curl`, `tar`, `install`이 있고 `~/.local/bin`이 PATH에 있다.

## 1. 릴리즈 받기

```sh
arch=$(dpkg --print-architecture)
version=2.105.0
curl -fL https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${arch}.tar.gz -o /tmp/gh.tar.gz
tar -xzf /tmp/gh.tar.gz -C /tmp
```

예상 결과: `/tmp/gh_2.105.0_linux_arm64/` 디렉터리가 생긴다.

## 2. 설치하기

```sh
install -m 755 /tmp/gh_${version}_linux_${arch}/bin/gh $HOME/.local/bin/gh
```

예상 결과: 화면 출력 없이 끝난다.

## 성공 확인

```sh
gh --version
command -v gh
```

→ `gh version 2.105.0 ...`와 `/home/userland/.local/bin/gh`.

apt가 아닌 릴리즈를 쓰는 이유와 정확한 버전 값은 [경로와 버전](../reference/paths-and-versions.md)에 있다. 설치 후 로그인은 [튜토리얼의 8단계](../tutorials/userland-orca-server.md)를 따른다.

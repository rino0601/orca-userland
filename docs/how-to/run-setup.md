# `mise run setup`으로 개발 환경 준비하기

`mise run setup` 한 번으로 dev 의존성(prek 포함)을 동기화하고, 버전 경로에 묶이지 않는 git pre-commit 훅을 설치한다.

전제 조건: `mise install`을 한 번 실행해 mise가 관리하는 uv가 PATH에 있다.

## 1. 설정 실행

저장소 루트에서 다음을 실행한다.

```sh
mise run setup
```

예상 결과: `uv sync`가 의존성을 확인한 뒤 `prek install`이 `.git/hooks/pre-commit`을 만든다. 훅이 이미 있으면 `Overwriting existing hook ...`과 함께 같은 내용으로 덮어쓴다. `prek.toml`에 정의된 검사는 커밋 때 실제로 실행되고, 설정 파일이 없는 worktree에서는 `--allow-missing-config`가 검사를 건너뛰게 한다.

## 2. 확인

```sh
uv run prek --version
cat .git/hooks/pre-commit
```

→ `prek 0.5.11` 이상이 출력되고, 훅에 `exec uv run prek hook-impl ...` 한 줄이 들어 있다.

훅이 실행 파일 경로가 아니라 런처 명령을 적는 이유는 [git 훅과 `--hook-command`](../explanation/hook-command.md)에 있다. 문서 사이트가 빌드되는지는 `uv run zensical build`로 따로 확인할 수 있다.

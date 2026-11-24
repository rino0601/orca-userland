# UserLAnd Orca 서버 업그레이드

[설치 튜토리얼](../tutorials/userland-orca-server.md)의 서버 전용 설치를 대상으로 한다. 안정 릴리스 버전 하나를 지정하면 `uname -m`에 맞는 Linux ARM64 또는 x64 아카이브와 SHA-256 목록을 받는다. 기존 설치와 새 패키지는 별도 디렉터리에 두고, 전환 후에도 실행 경로는 `/opt/orca-server/bin/orca-ide`다. [공식 서버 패키징 안내](https://github.com/stablyai/orca/blob/main/docs/site/content/docs/remote-servers.mdx)

## 1. 목표 버전 계획과 준비

저장소 디렉터리에서 아래 예시 버전을 원하는 안정 릴리스 태그로 바꾼다.

```sh
scripts/upgrade-orca-server --plan v1.4.272
scripts/upgrade-orca-server --prepare v1.4.272
```

계획 모드는 다운로드나 파일 쓰기 없이 릴리스 URL, 경로, 작업 순서를 출력한다. 준비는 서버가 켜진 동안 가능하다. 사용자 전용(700) 임시 디렉터리에 다운로드하고 선택한 아카이브의 체크섬 항목이 정확히 하나인지 확인한다. 압축을 푼 뒤 격리 프로필에서 공식 런처와 번들 Node CLI의 버전을 검사한다. 마지막 줄의 `WORKDIR`를 기록한다. 체크섬과 아카이브는 같은 GitHub 릴리스에서 받으므로 전송 손상이나 아카이브 불일치를 검출하며, 릴리스 자체는 GitHub의 공식 저장소를 신뢰한다.

`/tmp`가 재부팅 시 비워지는 환경에서는 준비 명령을 실행할 때 `TMPDIR`에 프로필과 설치 경로 밖의 영구 디렉터리를 지정한다. 다운로드, 새 패키지, 기존 설치 및 프로필 백업을 모두 수용할 공간이 필요하다.

## 2. 독립 UserLAnd 터미널에서 전환

Orca 세션에서 실행 중인 에이전트나 터미널은 서버가 중지되면 연결을 잃을 수 있다. Android에서 UserLAnd 터미널을 직접 열고 그 터미널을 유지한다. 진행 중인 작업을 저장하고, 모바일 연결이 끊기는 유지보수 시간을 잡는다. 설치 프로필 소유자로 실행하고 스크립트 전체에 `sudo`를 붙이지 않는다. 설치 튜토리얼의 도구들이 필요하다. `~/.bashrc` 백업과 자동 실행 블록 제거는 스크립트가 처리하므로, 독립 터미널에서는 서버만 중지하면 된다.

1. 포그라운드 서버는 해당 터미널에서 Ctrl+C로 중지한다. 자동 실행으로 분리된 서버는 `~/.config/orca/cli/bin/orca status --json`의 `result.app.pid` 및 `ps -p PID -o user=,args=`로 현재 사용자의 Orca serve 프로세스인지 확인한 뒤 해당 PID에 `kill -TERM PID`를 보낸다. 상태가 `running: false`, 런타임이 `not_running`으로 돌아올 때까지 기다린다. PID나 상태를 확인할 수 없으면 [서버 진단](diagnose-server-not-starting.md)을 먼저 따른다.
2. 독립 터미널에서 준비한 경로를 지정해 적용한다.

    ```sh
    scripts/upgrade-orca-server --apply v1.4.272 /tmp/orca-upgrade.XXXXXXXX
    ```

    예시 출력:

    ```text
    Profile backup: /tmp/orca-upgrade.XXXXXXXX/backup.XXXXXXXX/profile
    Bashrc backup: /tmp/orca-upgrade.XXXXXXXX/backup.XXXXXXXX/bashrc
    Install backup after switch: /opt/orca-server.upgrade.XXXXXXXX/previous
    Installed v1.4.272. Start Orca and verify the existing mobile connection from the independent terminal.
    Bashrc restored: /home/userland/.bashrc
    ```

적용은 체크섬을 다시 검사하고 자동 실행과 같은 flock을 잡은 상태에서 기존 래퍼로 중지를 확인한다. 프로필 전체와 `~/.bashrc`를 준비 작업 디렉터리의 같은 백업 디렉터리에 보관한다. 시작 마커와 종료 마커가 각각 하나씩 있고 시작이 앞에 있어야 하며, 형태가 이상하면 파일을 바꾸지 않고 중단한다. 자동 실행 블록은 양 마커를 포함해 원자적으로 제거한 뒤 전환에 사용하고, 성공 여부와 관계없이 종료 경로에서 백업으로 복구한다. 블록이 없으면 제거와 복구를 생략한다. 설치 파일 복사와 디렉터리 전환에만 `sudo`를 사용한다. 이전 설치를 `/opt/orca-server.upgrade.XXXXXXXX/previous`로 옮기며, 새 설치의 두 CLI 버전이 맞으면 `status`와 `pair`용 래퍼를 교체한다. 새 래퍼는 패키지에 적힌 Node 런타임 경로를 사용한다. 출력된 백업 경로 세 개를 기록한다. 작업 디렉터리와 백업에는 인증 및 페어링 데이터가 포함될 수 있으므로 사용자만 접근할 수 있는 곳에 보관한다.

전환 중 명령 실패나 Ctrl+C, TERM, HUP가 발생하면 스크립트가 이전 설치와 래퍼를 롤백하고 `.bashrc`도 백업에서 자동 복구한 뒤 종료한다. 복구가 실패하면 `Bashrc restore needs manual recovery` 메시지가 나온다. 적용 단계의 버전 확인은 격리 프로필에서 실행하며, 스크립트는 서버를 시작하거나 실제 프로필에 마이그레이션을 수행하지 않는다. 강제 종료나 기기 종료로 복원이 중단되면 출력된 백업 경로를 사용한다.

## 3. 기존 모바일 연결 확인

독립 UserLAnd 터미널에서 이전과 같은 프로필 및 플래그로 실행한다.

```sh
ORCA_USER_DATA_PATH="$HOME/.config/orca" \
    /opt/orca-server/bin/orca-ide serve --refuse-public --pairing-address 127.0.0.1
```

다른 터미널로 `~/.config/orca/cli/bin/orca status --json`을 실행하고 서버와 런타임이 준비되었는지 확인한다. 휴대폰에서 저장된 연결을 열어 기존 워크스페이스가 보이는지 확인한다. 같은 프로필, 키, 주소와 포트를 유지하므로 기존 연결로 먼저 시도한다. 버전 간 마이그레이션이나 앱 호환성에 따라 롤백이 필요할 수 있다. `.bashrc`의 자동 실행 블록은 적용이 끝날 때 이미 복구되어 있다. 자동 실행 스크립트는 상태 확인과 flock으로 중복 시작을 막으므로, 검증 중 새 셸을 열어도 서버는 그대로다. 포그라운드 서버를 Ctrl+C로 중지하고 새 대화형 셸을 열어 자동 실행을 확인한다.

## 시작 또는 모바일 연결 확인에 실패했을 때

`.bashrc`는 적용 종료 시 자동 복구된다. `Bashrc restore needs manual recovery` 메시지가 나왔을 때만 아래 `bashrc_backup` 경로로 수동 복구한다. 새 서버를 중지한 뒤 출력된 경로를 사용하여 독립 터미널에서 복원한다. 아래 예시의 경로를 실제 값으로 바꾼다. 설치 백업의 상위 디렉터리는 root 전용(700)이므로 `sudo ls`로 `previous`가 있고 `rejected-manual`은 없는지 확인한다. 프로필 백업도 확인하고, 각 명령이 성공한 뒤 다음 명령을 진행한다.

```sh
install_backup=/opt/orca-server.upgrade.XXXXXXXX
profile_backup=/tmp/orca-upgrade.XXXXXXXX/backup.XXXXXXXX/profile
bashrc_backup=/tmp/orca-upgrade.XXXXXXXX/backup.XXXXXXXX/bashrc

# 현재 설치가 남아 있을 때만 아래 첫 줄을 실행한다.
sudo mv -T /opt/orca-server "$install_backup/rejected-manual"
sudo mv -T "$install_backup/previous" /opt/orca-server

# 새 버전이 기록한 프로필도 원인 분석을 위해 별도로 보관한다.
restored=$(mktemp -d "$HOME/.config/orca-restored.XXXXXXXX")
cp -a "$profile_backup" "$restored/profile"
displaced=$(mktemp -d "$HOME/.config/orca-displaced.XXXXXXXX")
mv -T "$HOME/.config/orca" "$displaced/profile"
mv -T "$restored/profile" "$HOME/.config/orca"
```

전환 도중 이미 설치가 복원됐다면 설치 디렉터리 이동은 생략한다. `.bashrc` 자동 복구가 실패했다면 프로필 복원 뒤 `cp -p "$bashrc_backup" "$HOME/.bashrc"`로 원래 블록을 되돌린다. 마지막 프로필 이동에 실패하면 `"$displaced/profile"`을 원위치에 돌려놓고 경로 및 권한을 확인한다. 이전 서버를 같은 플래그로 시작해 모바일 연결을 확인한 뒤 자동 실행을 확인한다. 저장된 백업에는 프로필 이력과 비밀값이 있으므로 정상 동작을 확인한 뒤 보존 기간을 정하고 정리한다.

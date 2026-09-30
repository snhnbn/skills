# hwpx-mcp Windows 설치 가이드 (Claude Desktop + 한글 제어)

대상 저장소: [Topabaem05/hwpx-mcp](https://github.com/Topabaem05/hwpx-mcp) (`pyproject.toml`, README 확인 완료 — 2026-09-30 기준)

이 폴더의 파일은 **사용자의 실제 Windows PC**에서 실행/사용하기 위한 것입니다. 이 리포지토리(클라우드 세션)에서는 설치를 대신 실행할 수 없으므로, 아래 파일을 PC로 옮겨 사용하세요.

## 파일 구성

- `setup.ps1` — git clone, uv 설치 확인, 의존성 설치(`uv sync`), Claude Desktop 설정 자동 병합까지 처리하는 PowerShell 스크립트
- `claude_desktop_config.example.json` — 수동으로 설정할 경우 참고할 예시 (두 가지 연결 방식 중 하나만 남기고 사용)

## 사전 확인 사항 (중요, 공식 README 기준)

1. **Hancom Office 2010 이상**이 설치되어 있어야 기존 HWP 문서의 읽기·표/서식 편집 등 Windows COM 기능이 동작합니다. 없으면 신규 HWPX 생성 정도만 가능합니다.
2. Windows 전용 기능입니다 (Linux/macOS는 HWPX 생성과 HWP 읽기만 지원, 원문 안내와 동일).
3. 별도 설정 파일 없이도 최초 실행은 가능하다고 명시되어 있습니다(서버가 COM 사용 가능 여부를 자동 감지).

## 사용 순서

1. Windows PC에 [Claude Desktop](https://claude.ai/download)을 설치합니다.
2. `setup.ps1`을 PC로 복사한 뒤, PowerShell에서 실행합니다.

   ```powershell
   ./setup.ps1
   ```

   기본적으로 `%USERPROFILE%\hwpx-mcp` 폴더에 저장소를 clone합니다. 다른 위치를 쓰려면:

   ```powershell
   ./setup.ps1 -InstallDir "D:\tools\hwpx-mcp"
   ```

3. 스크립트가 자동으로 `%APPDATA%\Claude\claude_desktop_config.json`에 `hwpx-mcp` 항목을 추가합니다.
   - 기존 설정 파일이 있으면 **삭제하지 않고 타임스탬프 백업(.bak.날짜시각)** 후 병합합니다.
   - 자동 병합을 원하지 않으면 `-SkipConfigMerge` 옵션을 주고, `claude_desktop_config.example.json`을 참고해 수동으로 편집하세요.
4. Claude Desktop을 완전히 종료했다가 다시 실행합니다.

## 연결 방식 두 가지 (택1)

- **uv 방식 (기본, 권장)**: `command: cmd`, `args: ["/c", "uv --directory <설치경로> run hwpx-mcp"]`
  uv가 최초 실행 시 알아서 venv를 만들고 의존성을 설치하므로 관리가 간단합니다.
- **venv 직접 지정 방식 (대안)**: `command: <설치경로>\.venv\Scripts\python.exe`, `args: ["-m", "hwpx_mcp.server"]`, `cwd: <설치경로>`
  uv 방식이 동작하지 않을 때 대안으로 사용하세요. `claude_desktop_config.example.json`에 두 항목을 모두 넣어뒀지만, **실제 사용 시에는 하나만 남기고 다른 하나는 지우세요.**

## 문서 작업 시 권장 절차

전체 문서를 한 번에 맡기기보다, 대표 2~3쪽 사본으로 먼저 검증하세요.

| 순서 | 작업 기준 |
|---|---|
| 전체 문서 읽기 | 목차, 핵심 주장, 용어, 문체·제목 체계 파악 |
| 작성 위치 분석 | 대상 부분의 앞뒤 본문·표와 비교 |
| 내용 작성 | 제공 자료 근거로 집필, 근거 부족한 부분은 표시 |
| 양식에 입력 | 기존 문단·표 서식을 살려 사본에 반영 |
| 결과 확인 | PDF로 내보내 쪽 나눔·표 넘침 확인 |

## 검증 상태

- `pyproject.toml`의 진입점(`hwpx_mcp.server`), `pywin32` 의존성, `uv --directory ... run hwpx-mcp` 연결 방식: **확인됨** (저장소 원문 fetch).
- 실제 PC에서 hwpx-mcp 서버가 정상 구동되는지, HWP 파일 편집이 실제로 의도대로 동작하는지: **미검증** — 반드시 사본으로 먼저 테스트하세요.
- 설치 중 오류가 발생하면 오류 메시지 전체를 알려주시면 그에 맞춰 안내하겠습니다.

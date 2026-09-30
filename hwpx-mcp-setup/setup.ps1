#Requires -Version 5.1
<#
  hwpx-mcp (Windows 한글 제어 MCP) 설치 및 Claude Desktop 연결 스크립트
  대상 저장소: https://github.com/Topabaem05/hwpx-mcp
  실행 위치: Windows PowerShell (관리자 권한 불필요)

  이 스크립트가 하는 일:
    1. uv, git 설치 여부 확인 (없으면 winget으로 uv 설치 안내)
    2. hwpx-mcp 저장소를 지정한 폴더에 clone (이미 있으면 pull)
    3. uv sync 로 가상환경/의존성 사전 설치 (실행 시점 오류를 미리 잡기 위함)
    4. %APPDATA%\Claude\claude_desktop_config.json 에 hwpx-mcp 항목을 추가
       - 기존 설정 파일은 삭제/전체 덮어쓰기 하지 않고, 타임스탬프 백업 후 병합
#>

param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE "hwpx-mcp"),
    [switch]$SkipConfigMerge
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

# 1. 사전 도구 확인 ---------------------------------------------------------
Write-Step "필수 도구 확인 (git, uv)"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "git이 설치되어 있지 않습니다. https://git-scm.com/download/win 에서 먼저 설치한 뒤 다시 실행해 주세요." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "uv가 설치되어 있지 않아 winget으로 설치를 시도합니다."
    winget install --id=astral-sh.uv -e
    Write-Host "uv 설치 후에는 이 PowerShell 창을 닫고 새로 연 다음, 스크립트를 다시 실행해 주세요." -ForegroundColor Yellow
    exit 0
}

Write-Host "git, uv 확인 완료."

# 2. 저장소 clone / pull ----------------------------------------------------
Write-Step "hwpx-mcp 저장소 준비: $InstallDir"

if (Test-Path (Join-Path $InstallDir ".git")) {
    Write-Host "이미 clone된 저장소가 있어 최신 상태로 갱신합니다 (git pull)."
    Push-Location $InstallDir
    git pull
    Pop-Location
} else {
    git clone https://github.com/Topabaem05/hwpx-mcp.git $InstallDir
}

# 3. 의존성 사전 설치 --------------------------------------------------------
Write-Step "uv sync로 가상환경 및 의존성 설치 (최초 1회, 시간이 걸릴 수 있음)"

Push-Location $InstallDir
uv sync
Pop-Location

# 4. Claude Desktop 설정 병합 ------------------------------------------------
if ($SkipConfigMerge) {
    Write-Step "설정 병합은 건너뜁니다 (-SkipConfigMerge 지정됨)"
} else {
    Write-Step "Claude Desktop 설정 파일에 hwpx-mcp 항목 추가"

    $claudeDir = Join-Path $env:APPDATA "Claude"
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }
    $configPath = Join-Path $claudeDir "claude_desktop_config.json"

    if (Test-Path $configPath) {
        $backupPath = "$configPath.bak.$(Get-Date -Format yyyyMMdd_HHmmss)"
        Copy-Item $configPath $backupPath
        Write-Host "기존 설정 파일 백업: $backupPath"
        $configRaw = Get-Content $configPath -Raw
        if ([string]::IsNullOrWhiteSpace($configRaw)) {
            $config = [PSCustomObject]@{}
        } else {
            $config = $configRaw | ConvertFrom-Json
        }
    } else {
        $config = [PSCustomObject]@{}
    }

    if (-not ($config.PSObject.Properties.Name -contains "mcpServers")) {
        $config | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{})
    }

    # uv --directory 방식 (공식 README 1순위 권장 방식)
    $hwpxEntry = [PSCustomObject]@{
        command = "cmd"
        args    = @("/c", "uv --directory `"$InstallDir`" run hwpx-mcp")
    }

    if ($config.mcpServers.PSObject.Properties.Name -contains "hwpx-mcp") {
        $config.mcpServers.PSObject.Properties.Remove("hwpx-mcp")
    }
    $config.mcpServers | Add-Member -NotePropertyName "hwpx-mcp" -NotePropertyValue $hwpxEntry

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8

    Write-Host "설정 파일 갱신 완료: $configPath"
}

# 5. 마무리 안내 --------------------------------------------------------------
Write-Step "설치 완료"
Write-Host "다음 사항을 확인해 주세요:"
Write-Host "  1) Hancom Office 2010 이상이 이 PC에 설치되어 있어야 기존 HWP 문서 읽기/편집(COM 제어)이 가능합니다."
Write-Host "     (미설치 시에는 신규 HWPX 생성 등 제한된 기능만 동작합니다.)"
Write-Host "  2) Claude Desktop을 완전히 종료했다가 다시 실행해 주세요."
Write-Host "  3) 대화창에서 'hwpx-mcp' 도구가 인식되는지 확인해 주세요."
Write-Host "  4) 반드시 원본이 아닌 사본 문서로 먼저 시험해 주세요."

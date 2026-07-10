# PostToolUse 훅 — 도구 호출 로그 자동 기록
# 저장소 루트 기준 상대 경로 (다른 hook과 동일한 방식 — session-start.ps1 / check-sentinel.ps1 참고)
$debugLog = ".tool_log_debug.txt"
$logFile  = ".tool_log.jsonl"

# --- 디버그: hook 진입 기록 (절대 경로, 조건 없이 즉시 기록) ---
try {
    $debugEntry = "$(Get-Date -Format 'o') [ENTER] tool-logger.ps1 | PID=$PID | PSScriptRoot=$PSScriptRoot | PWD=$PWD"
    [System.IO.File]::AppendAllText($debugLog, $debugEntry + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
} catch { }

# --- stdin 읽기 (다중 fallback) ---
$jsonString = $null

# 방법 1: $input pipeline (PowerShell 권장 방식)
try {
    $inputLines = @($input)
    if ($inputLines.Count -gt 0) {
        $jsonString = $inputLines -join "`n"
    }
} catch { }

# 방법 2: [Console]::In.ReadToEnd() — $input이 비어있을 경우
if (-not $jsonString -or -not $jsonString.Trim()) {
    try {
        $jsonString = [Console]::In.ReadToEnd()
    } catch { }
}

# 방법 3: stdin 스트림 직접 읽기
if (-not $jsonString -or -not $jsonString.Trim()) {
    try {
        $stdinStream = [System.Console]::OpenStandardInput()
        $reader = New-Object System.IO.StreamReader($stdinStream)
        $jsonString = $reader.ReadToEnd()
        $reader.Close()
    } catch { }
}

# --- 디버그: stdin 읽기 결과 기록 ---
try {
    $stdinLen = if ($jsonString) { $jsonString.Length } else { 0 }
    [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [INFO] stdin length=$stdinLen" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
} catch { }

# stdin이 비어있으면 타임스탬프만 기록하고 종료
if (-not $jsonString -or -not $jsonString.Trim()) {
    try {
        $fallback = "{`"timestamp`":`"$(Get-Date -Format 'o')`",`"tool`":`"unknown`",`"path`":`"`",`"note`":`"stdin_empty`"}"
        [System.IO.File]::AppendAllText($logFile, $fallback + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
        [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [WARN] stdin empty — fallback written" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
    } catch { }
    exit 0
}

# --- JSON 파싱 ---
$data = $null
try {
    $data = $jsonString | ConvertFrom-Json
} catch {
    # JSON 파싱 실패 시 regex로 핵심 필드만 추출 (한국어 인코딩 문제 대비)
    try {
        $parseErr = $_.Exception.Message
        [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [WARN] JSON parse failed (regex fallback): $parseErr" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
        $toolNameMatch   = [regex]::Match($jsonString, '"tool_name"\s*:\s*"([^"]+)"')
        $filePathMatch   = [regex]::Match($jsonString, '"file_path"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"')
        $sessionIdMatch  = [regex]::Match($jsonString, '"session_id"\s*:\s*"([^"]+)"')
        $agentIdMatch    = [regex]::Match($jsonString, '"agent_id"\s*:\s*"([^"]+)"')
        $agentTypeMatch  = [regex]::Match($jsonString, '"agent_type"\s*:\s*"([^"]+)"')
        $toolName  = if ($toolNameMatch.Success)  { $toolNameMatch.Groups[1].Value } else { "parse_error" }
        $toolPath  = if ($filePathMatch.Success)  { $filePathMatch.Groups[1].Value -replace '\\\\', '\' } else { "" }
        # 아래 3개는 실패해도(빈 문자열) 기존 필드(tool/path)는 안전하게 기록된다
        $sessionId = if ($sessionIdMatch.Success)  { $sessionIdMatch.Groups[1].Value } else { "" }
        $agentId   = if ($agentIdMatch.Success)    { $agentIdMatch.Groups[1].Value } else { "" }
        $agentType = if ($agentTypeMatch.Success)  { $agentTypeMatch.Groups[1].Value } else { "" }
        $fallback = "{`"timestamp`":`"$(Get-Date -Format 'o')`",`"tool`":`"$toolName`",`"path`":`"$toolPath`",`"session_id`":`"$sessionId`",`"agent_id`":`"$agentId`",`"agent_type`":`"$agentType`",`"note`":`"regex_fallback`"}"
        [System.IO.File]::AppendAllText($logFile, $fallback + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
        [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [OK] regex fallback: tool=$toolName path=$toolPath agent_id=$agentId" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
    } catch { }
    exit 0
}

# --- 로그 엔트리 생성 ---
try {
    $toolName = if ($data.tool_name) { $data.tool_name } else { "unknown" }
    $toolPath = if ($data.tool_input -and $data.tool_input.file_path) { $data.tool_input.file_path } `
                elseif ($data.tool_input -and $data.tool_input.command)   { $data.tool_input.command }   `
                else { "" }

    # session_id/agent_id/agent_type — PostToolUse stdin JSON에 실존 확인됨 (developer PoC, .tool_log_debug.txt raw JSON 실측)
    # 필드 부재 시(예: chief 최상위 세션은 agent_id가 없을 수 있음) 빈 문자열로 안전하게 기록
    $sessionId = if ($data.session_id) { $data.session_id } else { "" }
    $agentId   = if ($data.agent_id)   { $data.agent_id }   else { "" }
    $agentType = if ($data.agent_type) { $data.agent_type } else { "" }

    $entry = [PSCustomObject]@{
        timestamp  = (Get-Date -Format "o")
        tool       = $toolName
        path       = $toolPath
        session_id = $sessionId
        agent_id   = $agentId
        agent_type = $agentType
    }

    $line = $entry | ConvertTo-Json -Compress
    [System.IO.File]::AppendAllText($logFile, $line + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
    [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [OK] logged tool=$toolName path=$toolPath agent_id=$agentId" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
} catch {
    try {
        [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [ERROR] entry write failed: $_" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
    } catch { }
}

# 500줄 초과 시 오래된 줄 제거
try {
    $lines = [System.IO.File]::ReadAllLines($logFile, [System.Text.Encoding]::UTF8)
    if ($lines.Count -gt 500) {
        $trimmed = $lines | Select-Object -Last 500
        [System.IO.File]::WriteAllLines($logFile, $trimmed, [System.Text.Encoding]::UTF8)
    }
} catch { }

exit 0

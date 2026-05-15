# PostToolUse 훅 — 도구 호출 로그 자동 기록
# 절대 경로 사용 (PSScriptRoot 의존 제거)
$debugLog = "C:\Users\wptmd\Desktop\joomidang\.tool_log_debug.txt"
$logFile  = "C:\Users\wptmd\Desktop\joomidang\.tool_log.jsonl"

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
        $toolNameMatch = [regex]::Match($jsonString, '"tool_name"\s*:\s*"([^"]+)"')
        $filePathMatch = [regex]::Match($jsonString, '"file_path"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"')
        $toolName = if ($toolNameMatch.Success) { $toolNameMatch.Groups[1].Value } else { "parse_error" }
        $toolPath = if ($filePathMatch.Success) { $filePathMatch.Groups[1].Value -replace '\\\\', '\' } else { "" }
        $fallback = "{`"timestamp`":`"$(Get-Date -Format 'o')`",`"tool`":`"$toolName`",`"path`":`"$toolPath`",`"note`":`"regex_fallback`"}"
        [System.IO.File]::AppendAllText($logFile, $fallback + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
        [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [OK] regex fallback: tool=$toolName path=$toolPath" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
    } catch { }
    exit 0
}

# --- 로그 엔트리 생성 ---
try {
    $toolName = if ($data.tool_name) { $data.tool_name } else { "unknown" }
    $toolPath = if ($data.tool_input -and $data.tool_input.file_path) { $data.tool_input.file_path } `
                elseif ($data.tool_input -and $data.tool_input.command)   { $data.tool_input.command }   `
                else { "" }

    $entry = [PSCustomObject]@{
        timestamp = (Get-Date -Format "o")
        tool      = $toolName
        path      = $toolPath
    }

    $line = $entry | ConvertTo-Json -Compress
    [System.IO.File]::AppendAllText($logFile, $line + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
    [System.IO.File]::AppendAllText($debugLog, "$(Get-Date -Format 'o') [OK] logged tool=$toolName path=$toolPath" + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
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

# PostToolUse 훅 — 도구 호출 로그 자동 기록
$jsonString = [Console]::In.ReadToEnd()
if (-not $jsonString.Trim()) { exit 0 }

try {
    $data = $jsonString | ConvertFrom-Json
} catch {
    exit 0
}

$logFile = Join-Path $PSScriptRoot "..\..\.tool_log.jsonl"
$logFile = [System.IO.Path]::GetFullPath($logFile)
$entry = [PSCustomObject]@{
    timestamp = (Get-Date -Format "o")
    tool      = $data.tool_name
    path      = if ($data.tool_input.file_path) { $data.tool_input.file_path } `
                elseif ($data.tool_input.command) { $data.tool_input.command } `
                else { "" }
}

$line = $entry | ConvertTo-Json -Compress
Add-Content -Path $logFile -Value $line -Encoding UTF8

# 500줄 초과 시 오래된 줄 제거
$lines = Get-Content $logFile -Encoding UTF8 -ErrorAction SilentlyContinue
if ($lines.Count -gt 500) {
    $lines | Select-Object -Last 500 | Set-Content $logFile -Encoding UTF8
}

exit 0

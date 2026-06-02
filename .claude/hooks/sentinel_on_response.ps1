# Stop 훅 — 응답 완료 시 sentinel 체크
# 내가 답변을 끝낼 때마다 이번 응답 중 발생한 violations.log 신규 이벤트를 보고한다

$monitorDir  = "$env:USERPROFILE\.claude\monitoring"
$logFile     = "$monitorDir\violations.log"
$markerFile  = "$monitorDir\.last_line_checked"

if (-not (Test-Path $monitorDir)) { New-Item -ItemType Directory -Force -Path $monitorDir | Out-Null }
if (-not (Test-Path $logFile))    { New-Item -ItemType File    -Force -Path $logFile     | Out-Null }

$lastLine = 0
if (Test-Path $markerFile) {
    try { $lastLine = [int]([System.IO.File]::ReadAllText($markerFile).Trim()) } catch {}
}

$allLines  = @()
$newEvents = @()
if (Test-Path $logFile) {
    $allLines = @([System.IO.File]::ReadAllLines($logFile, [System.Text.Encoding]::UTF8))
    if ($allLines.Count -gt $lastLine) {
        $newEvents = $allLines[$lastLine..($allLines.Count - 1)]
    }
}

[System.IO.File]::WriteAllText($markerFile, [string]($allLines.Count), [System.Text.Encoding]::UTF8)

$violations = $newEvents | Where-Object { $_ -match "\[SENTINEL:BLOCK\]|\[STABILITY:ALERT\]|\[OVERSEER:WARN\]" }
$warnings   = $newEvents | Where-Object { $_ -match "\[SENTINEL:WARN\]|\[STABILITY:ERROR\]" }

if ($violations.Count -gt 0) {
    Write-Host ""
    Write-Host "┌─── [SENTINEL] 위반 감지 ─────────────────────────────────┐"
    foreach ($v in $violations) { Write-Host "│  $v" }
    Write-Host "└──────────────────────────────────────────────────────────┘"
} elseif ($warnings.Count -gt 0) {
    Write-Host "⚠  [SENTINEL] 경고:"
    foreach ($w in $warnings) { Write-Host "   $w" }
} else {
    Write-Host "[SENTINEL] OK"
}

# SessionStart 훅 — 이전 세션 마커 초기화 + 위임 남용 감지
$sentinel   = ".sentinel_active"
$sessionMark = ".session_mark"
$delegation  = ".delegation_active"
$logFile     = ".tool_log.jsonl"
$abuseLog    = ".tool_log_debug.txt"

# ── 이전 로그에서 위임 남용 패턴 감지 ──────────────────────
# 패턴: .delegation_active Write → .py/bat/sh Edit (Agent 호출 없음)
if (Test-Path $logFile) {
    try {
        $entries = Get-Content $logFile -Encoding UTF8 | ForEach-Object {
            if ($_.Trim()) { $_ | ConvertFrom-Json }
        }

        $delegationWritten = $false
        $agentCalledAfter  = $false
        $abuseDetected     = $false
        $abusePath         = ""

        foreach ($e in $entries) {
            $tool = $e.tool
            $path = $e.path

            if ($tool -eq "Write" -and $path -match "\.delegation_active$") {
                $delegationWritten = $true
                $agentCalledAfter  = $false
            }
            elseif ($delegationWritten -and $tool -eq "Agent") {
                $agentCalledAfter = $true
            }
            elseif ($delegationWritten -and -not $agentCalledAfter -and
                    $tool -in @("Edit","Write") -and
                    $path -match "\.(py|bat|sh)$") {
                $abuseDetected = $true
                $abusePath     = $path
            }
        }

        if ($abuseDetected) {
            $msg = "[session-start] ⚠ 위임 남용 탐지 — 이전 세션에서 .delegation_active 생성 후 Agent 호출 없이 코드 파일 직접 수정:`n  파일: $abusePath`n  → VIOLATION_LOG 확인 및 원칙 A 위반 처리 필요"
            Write-Host $msg
            Add-Content $abuseLog "$(Get-Date -Format 'o') [ABUSE] $msg" -Encoding UTF8
        }
    } catch {
        # 로그 파싱 실패는 무시
    }
}

# ── 마커 초기화 ──────────────────────────────────────────
if (Test-Path $sentinel)   { Remove-Item $sentinel   -Force }
if (Test-Path $delegation) { Remove-Item $delegation -Force }

Set-Content $sessionMark (Get-Date -Format "o") -Encoding UTF8

# ── 이전 세션 로그 아카이브 후 초기화 ────────────────────
if (Test-Path $logFile) {
    $archive = ".tool_log_prev.jsonl"
    Copy-Item $logFile $archive -Force
    Remove-Item $logFile -Force
}

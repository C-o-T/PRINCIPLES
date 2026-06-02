# sentinel_on_response.ps1 — Stop hook (v2 국세청 강화판)
# 역할:
#   1. transcript 파싱 → IPE 블록 존재 여부 자동 감지
#   2. 총 책임자가 직접 실행(Edit/Write/Bash)했는지 감지 → 원칙 A 위반 체크
#   3. Agent 위임(서브 세션) 호출 여부 확인
#   4. violations.log 신규 항목 보고
# 출력은 다음 응답 시작 전 컨텍스트에 주입 → 총 책임자 우회 불가

$monitorDir = "$env:USERPROFILE\.claude\monitoring"
$logFile    = "$monitorDir\violations.log"
$markerFile = "$monitorDir\.last_line_checked"

if (-not (Test-Path $monitorDir)) { New-Item -ItemType Directory -Force -Path $monitorDir | Out-Null }
if (-not (Test-Path $logFile))    { New-Item -ItemType File -Force -Path $logFile | Out-Null }

# ── stdin 에서 transcript_path 파싱 ──────────────────────────────────
$transcriptPath = $null
try {
    $raw  = [Console]::In.ReadToEnd()
    $data = $raw | ConvertFrom-Json
    $transcriptPath = $data.transcript_path
} catch {}

# ── 마지막 assistant 응답 파싱 ───────────────────────────────────────
$hasIPE             = $false
$hasAgentDelegation = $false
$hasDirectWork      = $false
$lastText           = ""

$directWorkTools = @("Edit", "Write", "Bash", "PowerShell")

if ($transcriptPath -and (Test-Path $transcriptPath)) {
    $lines = Get-Content $transcriptPath -Tail 150 -ErrorAction SilentlyContinue

    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        try {
            $entry = $lines[$i] | ConvertFrom-Json
            if ($entry.role -eq "assistant") {

                if ($entry.content -is [array]) {
                    # 텍스트 블록
                    $textBlocks = $entry.content | Where-Object { $_.type -eq "text" }
                    $lastText   = ($textBlocks | ForEach-Object { $_.text }) -join " "

                    # 툴 사용 분류
                    $toolUses           = $entry.content | Where-Object { $_.type -eq "tool_use" }
                    $hasAgentDelegation = ($toolUses | Where-Object { $_.name -eq "Agent" }).Count -gt 0
                    $hasDirectWork      = ($toolUses | Where-Object { $_.name -in $directWorkTools }).Count -gt 0

                } elseif ($entry.content -is [string]) {
                    $lastText = $entry.content
                }
                break
            }
        } catch {}
    }

    $hasIPE = $lastText -match "\[IPE\s*(체크|Check)\]"
}

$isMeaningful = $lastText.Length -gt 80

# ── 위반 판정 및 로그 기록 ───────────────────────────────────────────
$ipeViolation   = $isMeaningful -and -not $hasIPE
$directViolation = $hasDirectWork -and -not $hasAgentDelegation

if ($ipeViolation) {
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [SENTINEL:WARN] IPE 체크 블록 미감지 — 총 책임자 원칙 I 위반"
}
if ($directViolation) {
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [SENTINEL:WARN] 총 책임자 직접 실행 감지(Edit/Write/Bash) — 원칙 A 위임 위반 의심"
}

# ── violations.log 신규 항목 수집 ────────────────────────────────────
$lastLine = 0
if (Test-Path $markerFile) {
    try { $lastLine = [int](Get-Content $markerFile -Raw) } catch {}
}
$allLines  = @(Get-Content $logFile -ErrorAction SilentlyContinue)
$newEvents = @()
if ($allLines.Count -gt $lastLine) {
    $newEvents = $allLines[$lastLine..($allLines.Count - 1)]
}
$allLines.Count | Set-Content -Path $markerFile

$hardViolations = $newEvents | Where-Object { $_ -match "\[SENTINEL:BLOCK\]|\[STABILITY:ALERT\]" }
$warnings       = $newEvents | Where-Object { $_ -match "\[SENTINEL:WARN\]|\[STABILITY:ERROR\]|\[OVERSEER:WARN\]" }

# ── 출력 (다음 턴 컨텍스트에 주입) ──────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  [국세청 세션] 자동 감사 — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ($isMeaningful) {
    # IPE 체크
    if ($hasIPE) {
        Write-Host "  ✅ IPE 체크      : 감지됨"
    } else {
        Write-Host "  🚨 IPE 체크      : 미감지 — 다음 응답 시작 전 반드시 IPE 블록 포함"
    }

    # 위임 vs 직접 실행
    if ($hasAgentDelegation) {
        Write-Host "  ✅ 서브 세션 위임 : Agent 호출 감지 — 원칙 A 준수"
    } elseif ($hasDirectWork) {
        Write-Host "  🚨 원칙 A 위반   : 총 책임자 직접 실행 감지 — 서브 세션에 위임했어야 함"
    } else {
        Write-Host "  ℹ  직접 실행 없음 : 조율/답변 응답으로 판단"
    }

    # 국세청 검토 여부
    if ($hasAgentDelegation) {
        Write-Host "  ✅ 국세청 검토   : Agent 위임 완료"
    } else {
        Write-Host "  ⚠  국세청 검토   : 중요 작업 완료 후 국세청 세션(Agent) 검토 호출 권고"
    }
} else {
    Write-Host "  ℹ  단순 응답 — 감사 항목 해당 없음"
}

# violations.log 경고
if ($hardViolations.Count -gt 0) {
    Write-Host "  ──────────────────────────────────────────────────────────"
    Write-Host "  🚨 하드 위반:"
    foreach ($v in $hardViolations) { Write-Host "     $v" }
} elseif ($warnings.Count -gt 0) {
    Write-Host "  ──────────────────────────────────────────────────────────"
    Write-Host "  ⚠  경고 누적:"
    foreach ($w in $warnings) { Write-Host "     $w" }
} else {
    Write-Host "  ✅ 로그 위반      : 없음"
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

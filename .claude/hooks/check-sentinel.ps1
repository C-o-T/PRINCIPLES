# UserPromptSubmit 훅 — 감시 세션 활성화 여부 확인
$sentinel = ".sentinel_active"
$sessionMark = ".session_mark"

if (Test-Path $sentinel) {
    exit 0
}

if (Test-Path $sessionMark) {
    $age = (Get-Date) - (Get-Item $sessionMark).LastWriteTime
    if ($age.TotalMinutes -lt 10) {
        exit 0
    }
}

Write-Host "[sentinel hook] 감시 세션이 활성화되지 않았습니다."
Write-Host ""
Write-Host "세션 시작 10분이 경과했습니다."
Write-Host "overseer / stability / sentinel Agent 3개를 실행한 후"
Write-Host "Write 도구로 .sentinel_active 파일을 생성하세요."
exit 2

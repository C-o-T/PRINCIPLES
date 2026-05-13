# SessionStart 훅 — 이전 세션 마커 초기화

$sentinel = ".claude\.sentinel_active"
$sessionMark = ".claude\.session_mark"

if (Test-Path $sentinel) {
    Remove-Item $sentinel -Force
}

Set-Content $sessionMark (Get-Date -Format "o") -Encoding UTF8

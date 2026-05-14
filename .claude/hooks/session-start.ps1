# SessionStart 훅 — 이전 세션 마커 초기화
$sentinel = ".sentinel_active"
$sessionMark = ".session_mark"
$delegation = ".delegation_active"

if (Test-Path $sentinel) { Remove-Item $sentinel -Force }
if (Test-Path $delegation) { Remove-Item $delegation -Force }

Set-Content $sessionMark (Get-Date -Format "o") -Encoding UTF8

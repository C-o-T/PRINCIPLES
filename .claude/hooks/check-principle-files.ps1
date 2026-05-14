# PreToolUse 훅 — 원칙 파일 직접 수정 차단 (원칙 A 집행)
$jsonString = [Console]::In.ReadToEnd()
if (-not $jsonString.Trim()) { exit 0 }

try {
    $data = $jsonString | ConvertFrom-Json
} catch {
    exit 0
}

$toolName = $data.tool_name
if ($toolName -notin @("Edit", "Write")) { exit 0 }

$filePath = $data.tool_input.file_path
if (-not $filePath) { exit 0 }

$filePath = $filePath -replace '\\', '/'

$protected = @(
    "AGENT_PRINCIPLES\.md$",
    "sessions/_shared/PRINCIPLES\.md$",
    "sessions/[^/]+/CLAUDE\.md$",
    "^CLAUDE\.md$",
    ".*/CLAUDE\.md$",
    "START_HERE\.md$",
    "README\.md$",
    "\.tool_log\.jsonl$"
)

$isProtected = $false
foreach ($p in $protected) {
    if ($filePath -match $p) { $isProtected = $true; break }
}

if (-not $isProtected) { exit 0 }

if (Test-Path ".delegation_active") { exit 0 }

Write-Host "[principle-guard] 원칙 파일 직접 수정 차단 (원칙 A)"
Write-Host ""
Write-Host "대상 파일: $filePath"
Write-Host ""
Write-Host "원칙 파일은 chief가 직접 수정할 수 없습니다."
Write-Host "content-qa 또는 developer 세션에 위임하세요."
Write-Host ""
Write-Host "위임 절차:"
Write-Host "  1. Write 도구로 .delegation_active 파일 생성 (내용: 위임 대상 세션명)"
Write-Host "  2. Agent 도구로 해당 세션 실행"
Write-Host "  3. 세션 완료 후 .delegation_active 삭제"
exit 2

# PreToolUse 훅 — 원칙 파일 + 코드 파일 직접 수정 차단 (원칙 A 집행)
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
$ext = [System.IO.Path]::GetExtension($filePath).ToLower()

# ── 보호 대상 1: 원칙 파일 ──────────────────────────────────
$protectedPatterns = @(
    "AGENT_PRINCIPLES\.md$",
    "sessions/_shared/PRINCIPLES\.md$",
    "sessions/[^/]+/CLAUDE\.md$",
    "^CLAUDE\.md$",
    ".*/CLAUDE\.md$",
    "START_HERE\.md$",
    "README\.md$",
    "\.tool_log\.jsonl$"
)

$isPrincipleFile = $false
foreach ($p in $protectedPatterns) {
    if ($filePath -match $p) { $isPrincipleFile = $true; break }
}

# ── 보호 대상 2: 코드 파일 (.py / .bat / .sh) ──────────────
$codeExtensions = @(".py", ".bat", ".sh")
$isCodeFile = $codeExtensions -contains $ext

# ── 예외: .delegation_active 존재 시 통과 (위임 절차 이행 중) ──
if ($isPrincipleFile -or $isCodeFile) {
    if (Test-Path ".delegation_active") { exit 0 }
}

# ── 원칙 파일 차단 메시지 ──────────────────────────────────
if ($isPrincipleFile) {
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
}

# ── 코드 파일 차단 메시지 ──────────────────────────────────
if ($isCodeFile) {
    Write-Host "[code-guard] 코드 파일 직접 수정 차단 (원칙 A — 위임 의무)"
    Write-Host ""
    Write-Host "대상 파일: $filePath"
    Write-Host ""
    Write-Host "chief는 코드 파일을 직접 수정할 수 없습니다."
    Write-Host "반드시 developer 세션에 위임하세요."
    Write-Host ""
    Write-Host "위임 절차:"
    Write-Host "  1. Write 도구로 .delegation_active 파일 생성 (내용: developer)"
    Write-Host "  2. Agent 도구로 developer 세션 실행"
    Write-Host "  3. developer 세션이 코드 수정 완료 후 .delegation_active 삭제"
    Write-Host ""
    Write-Host "※ 이 차단을 우회해 .delegation_active 직접 생성 후 편집 시"
    Write-Host "  tool-logger가 기록 → 다음 세션 시작 시 sentinel이 탐지"
    exit 2
}

exit 0

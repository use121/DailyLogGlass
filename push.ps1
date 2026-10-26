param(
    [string]$User = "use121",
    [string]$Repo = "DailyLogGlass"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "  DailyLog Glass · 推送助手" -ForegroundColor Cyan
Write-Host "  目标仓库: https://github.com/$User/$Repo"
Write-Host ""

$tokenSecure = Read-Host "粘贴 GitHub Token（输入时不显示）" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSecure)
$token = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "Token 为空，已退出。" -ForegroundColor Red
    Read-Host "按回车关闭"
    exit 1
}

git branch -M main 2>$null
git remote remove origin 2>$null
git remote add origin "https://${User}:${token}@github.com/$User/$Repo.git"

Write-Host ""
Write-Host "正在推送..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    git remote set-url origin "https://github.com/$User/$Repo.git"
    Write-Host ""
    Write-Host "推送成功" -ForegroundColor Green
    Write-Host "  仓库:   https://github.com/$User/$Repo"
    Write-Host "  Actions: https://github.com/$User/$Repo/actions"
    Write-Host ""
    Write-Host "Actions 会自动开始编译，约 3-6 分钟。"
    Write-Host "跑完后在运行页面底部 Artifacts 下载 DailyLogGlass-ipa。"
} else {
    Write-Host ""
    Write-Host "推送失败。" -ForegroundColor Red
    Write-Host "常见原因："
    Write-Host "  1. 仓库还没在 GitHub 上创建"
    Write-Host "  2. Token 没有 Contents: Read and write 权限"
    Write-Host "  3. 用户名或仓库名写错"
}

Write-Host ""
Read-Host "按回车关闭"

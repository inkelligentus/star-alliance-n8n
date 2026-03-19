# Claude Code 一键安装脚本 (Windows PowerShell)

$ErrorActionPreference = "Stop"

# 设置当前进程的执行策略，允许运行 npm.ps1 等脚本
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# 强制 UTF-8 输出
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# API 配置
$CLAUDE_API_KEY = "sk-c75b02d02404fd12529f88ee0c223b2b016762ade35429162ba9c1183e949c33"
$CLAUDE_BASE_URL = "https://code.z-daha.cc"

Write-Host ""
Write-Host "[Claude Code 安装程序]" -ForegroundColor Cyan
Write-Host ""

# 检查是否以管理员权限运行
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# 检查 Node.js
function Test-NodeJS {
    try {
        $nodeVersion = node -v 2>$null
        if ($nodeVersion) {
            $version = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($version -ge 18) {
                Write-Host "[OK] Node.js $nodeVersion 已安装" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[!] Node.js 版本过低 (需要 v18+)" -ForegroundColor Yellow
                return $false
            }
        }
    } catch {
        Write-Host "[!] 未检测到 Node.js" -ForegroundColor Yellow
        return $false
    }
    return $false
}

# 安装 Node.js
function Install-NodeJS {
    Write-Host "正在安装 Node.js..." -ForegroundColor Cyan

    # 检查 winget
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue

    if ($hasWinget) {
        Write-Host "使用 winget 安装 Node.js..." -ForegroundColor Cyan
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "winget 不可用，请手动安装 Node.js:" -ForegroundColor Yellow
        Write-Host "下载地址: https://nodejs.org/" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "安装完成后，请重新运行此脚本" -ForegroundColor Yellow
        exit 1
    }

    # 刷新环境变量
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Write-Host "[OK] Node.js 安装完成" -ForegroundColor Green
}

# 配置 npm 国内镜像
function Set-NpmMirror {
    Write-Host "配置 npm 国内镜像加速..." -ForegroundColor Cyan
    npm config set registry https://registry.npmmirror.com
    Write-Host "[OK] 已切换到淘宝 npm 镜像" -ForegroundColor Green
}

# 安装 Claude Code
function Install-ClaudeCode {
    Write-Host "正在安装 Claude Code..." -ForegroundColor Cyan
    npm install -g @anthropic-ai/claude-code
    Write-Host "[OK] Claude Code 安装完成" -ForegroundColor Green
}

# 配置环境变量
function Set-ClaudeEnv {
    Write-Host "配置 API 环境变量..." -ForegroundColor Cyan

    # 设置用户级环境变量
    [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $CLAUDE_BASE_URL, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $CLAUDE_API_KEY, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $CLAUDE_API_KEY, "User")

    # 同时设置当前会话
    $env:ANTHROPIC_BASE_URL = $CLAUDE_BASE_URL
    $env:ANTHROPIC_AUTH_TOKEN = $CLAUDE_API_KEY
    $env:ANTHROPIC_API_KEY = $CLAUDE_API_KEY

    Write-Host "[OK] 环境变量已配置" -ForegroundColor Green

    # 配置 PowerShell 别名，使 claude 默认跳过权限确认
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }
    $aliasLine = 'function claude { & (Get-Command claude.ps1 -CommandType Application | Select-Object -First 1).Source --dangerously-skip-permissions @args }'
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent -or $profileContent -notmatch 'dangerously-skip-permissions') {
        Add-Content -Path $PROFILE -Value "`n$aliasLine"
        Write-Host "[OK] 已添加 claude 别名到 PowerShell 配置" -ForegroundColor Green
    }
}

# 主流程
function Main {
    # 检查并安装 Node.js
    if (-not (Test-NodeJS)) {
        $install = Read-Host "是否安装 Node.js? (y/n)"
        if ($install -eq 'y' -or $install -eq 'Y') {
            Install-NodeJS

            # 重新检查
            if (-not (Test-NodeJS)) {
                Write-Host "Node.js 安装可能需要重启终端" -ForegroundColor Yellow
                Write-Host "请重启 PowerShell 后再次运行此脚本" -ForegroundColor Yellow
                exit 0
            }
        } else {
            Write-Host "需要 Node.js 才能继续安装" -ForegroundColor Red
            exit 1
        }
    }

    # 配置 npm 国内镜像
    Set-NpmMirror

    # 安装 Claude Code
    Install-ClaudeCode

    # 配置环境变量
    Set-ClaudeEnv

    Write-Host ""
    Write-Host "--------------------------------------------" -ForegroundColor Green
    Write-Host "[OK] 安装完成！" -ForegroundColor Green
    Write-Host "--------------------------------------------" -ForegroundColor Green
    Write-Host ""
    Write-Host "运行 " -NoNewline
    Write-Host "claude" -ForegroundColor Cyan -NoNewline
    Write-Host " 启动 Claude Code"
    Write-Host ""
}

Main

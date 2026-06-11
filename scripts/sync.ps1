#!/usr/bin/env pwsh
# ========================================
#   Scoop CN Mirror - GitHub Actions 同步脚本
#   从官方 bucket 拉取最新清单，替换为国内镜像地址
# ========================================

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$RepoRoot = $PSScriptRoot | Split-Path
$BucketDir = Join-Path $RepoRoot 'bucket'
$BucketsDir = '/tmp/scoop-buckets'

# 颜色输出（兼容 PowerShell Core on Linux）
function Write-Info($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "  [ERR]  $msg" -ForegroundColor Red }

# 读取配置
$ConfigPath = Join-Path $PSScriptRoot 'config.json'
if (-not (Test-Path $ConfigPath)) {
    Write-Err "config.json 不存在: $ConfigPath"
    exit 1
}
$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# 确保 bucket 目录存在
if (-not (Test-Path $BucketDir)) {
    New-Item -ItemType Directory -Path $BucketDir -Force | Out-Null
}

# ---------- Hash 获取 ----------
function Get-RemoteHash($url, $rule) {
    # 1. 尝试 hashSuffix 文件
    if ($rule.hashSuffix) {
        $hashUrl = "$url$($rule.hashSuffix)"
        Write-Info "尝试 hash 文件: $hashUrl"
        try {
            $content = (Invoke-WebRequest $hashUrl -TimeoutSec 30 -ErrorAction Stop).Content.Trim()
            $hash = ($content -split '\s+')[0].ToLower()
            if ($hash -match '^[a-f0-9]{64}$') { return $hash }
        } catch { }
    }

    # 2. 尝试 SHASUMS256.txt (Node.js)
    if ($rule.hashFromShasums) {
        $fileName = Split-Path $url -Leaf
        $baseUrl = ($url -replace '/[^/]+$', '')
        $shasumsUrl = "$baseUrl/SHASUMS256.txt"
        Write-Info "尝试 SHASUMS256: $shasumsUrl"
        try {
            $lines = (Invoke-WebRequest $shasumsUrl -TimeoutSec 30 -ErrorAction Stop).Content -split "`n"
            foreach ($line in $lines) {
                if ($line -match "^([a-f0-9]{64})\s+$fileName") {
                    return $matches[1].ToLower()
                }
            }
        } catch { }
    }

    # 3. 下载文件计算 hash
    Write-Warn "下载文件计算 hash（可能需要几分钟）..."
    $tmp = "/tmp/scoop_hash_$(Get-Random)"
    try {
        Invoke-WebRequest $url -OutFile $tmp -TimeoutSec 300 -ErrorAction Stop
        $hash = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        return $hash
    } catch {
        Write-Err "下载失败: $_"
        if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        return $null
    }
}

# ---------- URL 替换 ----------
function Get-MirrorUrl($originalUrl, $rule) {
    $regex = [regex]::new($rule.pattern)
    $m = $regex.Match($originalUrl)
    if (-not $m.Success) { return $null }

    # 通用替换：{1} {2} ... 对应捕获组
    $result = $rule.rewrite
    for ($i = 1; $i -lt $m.Groups.Count; $i++) {
        $result = $result -replace "\{$i\}", $m.Groups[$i].Value
    }
    return $result
}

# ---------- 重写清单 ----------
function Rewrite-Manifest($content, $softName, $rule) {
    $obj = $content | ConvertFrom-Json
    $changed = $false

    # 处理顶层 url
    if ($obj.url) {
        $newUrl = Get-MirrorUrl $obj.url $rule
        if ($newUrl) {
            Write-Info "重写 url: $newUrl"
            $hash = Get-RemoteHash $newUrl $rule
            if ($hash) {
                $obj.url = $newUrl
                $obj.hash = $hash
                $changed = $true
                Write-Ok "hash = $hash"
            } else {
                Write-Warn "无法获取 hash，跳过"
            }
        }
    }

    # 处理 architecture.64bit.url
    if ($obj.PSObject.Properties['architecture'] -and
        $obj.architecture.PSObject.Properties['64bit'] -and
        $obj.architecture.'64bit'.PSObject.Properties['url']) {

        $origUrl = $obj.architecture.'64bit'.url
        $newUrl = Get-MirrorUrl $origUrl $rule
        if ($newUrl) {
            Write-Info "重写 64bit url: $newUrl"
            $hash = Get-RemoteHash $newUrl $rule
            if ($hash) {
                $obj.architecture.'64bit'.url = $newUrl
                $obj.architecture.'64bit'.hash = $hash
                $changed = $true
                Write-Ok "hash = $hash"
            } else {
                Write-Warn "无法获取 hash，跳过"
            }
        }
    }

    # 处理 32bit 和 arm64（如果原始也是境外源）
    foreach ($arch in @('32bit', 'arm64')) {
        if ($obj.PSObject.Properties['architecture'] -and
            $obj.architecture.PSObject.Properties[$arch] -and
            $obj.architecture.$arch.PSObject.Properties['url']) {

            $origUrl = $obj.architecture.$arch.url
            $newUrl = Get-MirrorUrl $origUrl $rule
            if ($newUrl) {
                Write-Info "重写 $arch url: $newUrl"
                $hash = Get-RemoteHash $newUrl $rule
                if ($hash) {
                    $obj.architecture.$arch.url = $newUrl
                    $obj.architecture.$arch.hash = $hash
                    $changed = $true
                    Write-Ok "hash = $hash"
                }
            }
        }
    }

    if ($changed) { return $obj }
    return $null
}

# ---------- 主流程 ----------
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Scoop CN Mirror 同步" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Bucket 目录: $BucketDir"
Write-Host "软件数量:  $($Config.software.Count)"
Write-Host ""

$updated = 0
$skipped = 0
$failed = 0

foreach ($sw in $Config.software) {
    $name = $sw.name
    $source = $sw.source
    $ruleName = $sw.rule

    Write-Host "[$name]" -ForegroundColor Cyan

    $rule = $Config.rules.$ruleName
    if (-not $rule) {
        Write-Err "未找到规则: $ruleName"
        $failed++
        continue
    }

    $sourcePath = "$BucketsDir/$source/bucket/$name.json"
    if (-not (Test-Path $sourcePath)) {
        Write-Warn "官方 bucket 中不存在: $source/$name.json"
        $skipped++
        continue
    }

    $content = Get-Content $sourcePath -Raw -ErrorAction Stop
    $rewritten = $null
    try {
        $rewritten = Rewrite-Manifest $content $name $rule
    } catch {
        Write-Err "处理失败: $_"
        $failed++
        continue
    }

    if ($rewritten) {
        $outPath = Join-Path $BucketDir "$name.json"
        $rewritten | ConvertTo-Json -Depth 10 | Set-Content $outPath -Encoding UTF8
        Write-Ok "已更新: $outPath"
        $updated++
    } else {
        Write-Info "无需更新"
        $skipped++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  同步完成" -ForegroundColor Green
Write-Host "  更新: $updated"
Write-Host "  跳过: $skipped"
Write-Host "  失败: $failed"
Write-Host "========================================" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 }

# BeefTV 本地开发一键启动
# 用法：在仓库根目录执行 .\dev.ps1
# 注意：首次运行需要允许脚本执行：Set-ExecutionPolicy -Scope Process Bypass

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$devRoot  = "C:\Users\Administrator\.localdev"

$goBin  = Join-Path $devRoot "go\bin"
$bunBin = Join-Path $devRoot "bun\node_modules\.bin"
$gccBin = Join-Path $devRoot "mingw64\bin"

foreach ($p in @($goBin, $bunBin, $gccBin)) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "缺少工具目录：$p，请参考 DEV-ENV.md"
    }
}

$env:PATH = "$goBin;$bunBin;$gccBin;$env:PATH"

# go-sqlite3 必须走 CGO
$env:CGO_ENABLED = "1"
$env:CANVAS_BACKEND_ADDR = "127.0.0.1:8080"
$env:GOPROXY = "https://goproxy.cn,direct"

$dataDir = Join-Path $repoRoot ".local\project-workbench-debug"
$goBuild = Join-Path $repoRoot ".local\cache\go-build"
$goMod   = Join-Path $repoRoot ".local\cache\go-mod"
foreach ($d in @($dataDir, $goBuild, $goMod)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}
$env:GOCACHE = $goBuild
$env:GOMODCACHE = $goMod
$env:CANVAS_BACKEND_DATA_DIR = $dataDir

foreach ($port in @(3000, 8080)) {
    $busy = $null -ne (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($busy) { throw "端口 $port 已被占用，请先关闭占用进程。" }
}

$ps = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

Write-Host "启动后端 (127.0.0.1:8080) ..." -ForegroundColor Cyan
Start-Process $ps -ArgumentList @(
    "-NoExit", "-Command",
    "`$env:PATH='$goBin;$gccBin;' + `$env:PATH; `$env:CGO_ENABLED='1'; `$env:CANVAS_BACKEND_ADDR='127.0.0.1:8080'; `$env:CANVAS_BACKEND_DATA_DIR='$dataDir'; `$env:GOCACHE='$goBuild'; `$env:GOMODCACHE='$goMod'; Set-Location '$repoRoot\backend'; go run ./cmd/server"
)

Write-Host "启动前端 (127.0.0.1:3000) ..." -ForegroundColor Cyan
Start-Process $ps -ArgumentList @(
    "-NoExit", "-Command",
    "`$env:PATH='$bunBin;' + `$env:PATH; `$env:VITE_API_PROXY_TARGET='http://127.0.0.1:8080'; Set-Location '$repoRoot\web'; bun run dev -- --host 127.0.0.1 --port 3000"
)

Write-Host ""
Write-Host "已打开两个窗口。约 30 秒后访问 http://localhost:3000" -ForegroundColor Green
Write-Host "后端健康检查：http://127.0.0.1:8080/api/health" -ForegroundColor Green

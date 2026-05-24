# Ubuntu WSL2 を完全削除するスクリプト
# 実行後に setup.ps1 (管理者) を実行してください。

param(
    [string]$DistroName = "Ubuntu"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$msg) {
    Write-Host "`n>>> $msg" -ForegroundColor Cyan
}
function Write-OK([string]$msg) {
    Write-Host "    OK: $msg" -ForegroundColor Green
}
function Write-Warn([string]$msg) {
    Write-Host "    !! $msg" -ForegroundColor Yellow
}

# ============================================================
# 現在の状態を表示
# ============================================================
Write-Step "現在の WSL ディストリビューション一覧"
wsl --list --verbose

# ============================================================
# 警告と確認
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "  警告: データは完全に削除されます" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "  対象: $DistroName"
Write-Host "  削除されるもの: ホームディレクトリ・インストール済みパッケージ・全設定"
Write-Host ""

$confirm = Read-Host "本当に '$DistroName' を削除しますか? (yes と入力して確認)"
if ($confirm -ne "yes") {
    Write-Host "キャンセルしました。" -ForegroundColor Yellow
    exit 0
}

# ============================================================
# Step 1: WSL を停止
# ============================================================
Write-Step "WSL を停止"
wsl --shutdown
Start-Sleep -Seconds 2
Write-OK "WSL 停止完了"

# ============================================================
# Step 2: Ubuntu を削除
# ============================================================
Write-Step "$DistroName を削除"

try {
    wsl --unregister $DistroName
    Write-OK "$DistroName を削除しました"
} catch {
    Write-Warn "$DistroName は見つかりませんでした（スキップ）"
}

# ============================================================
# 完了
# ============================================================
Write-Host ""
Write-Host "========================================"  -ForegroundColor Green
Write-Host "  削除完了"                               -ForegroundColor Green
Write-Host "========================================"  -ForegroundColor Green
Write-Host @"

次のステップ:
  PowerShell を管理者で開いて以下を実行してください:
    cd  <リポジトリのパス>\ubuntu-on-wsl2
    Set-ExecutionPolicy Bypass -Scope Process
    .\setup.ps1

"@

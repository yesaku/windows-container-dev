#Requires -RunAsAdministrator
# 実行方法: PowerShell を管理者で開き
#   Set-ExecutionPolicy Bypass -Scope Process; .\setup.ps1

$ErrorActionPreference = "Stop"

function Write-Step([string]$msg) {
    Write-Host "`n>>> $msg" -ForegroundColor Cyan
}
function Write-OK([string]$msg) {
    Write-Host "    OK: $msg" -ForegroundColor Green
}

# ============================================================
# Step 1: WSL2 有効化（初回は再起動が必要）
# ============================================================
Write-Step "WSL2 の確認"

$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmFeature  = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

if ($wslFeature.State -ne "Enabled" -or $vmFeature.State -ne "Enabled") {
    Write-Host "    WSL2 を有効化します（完了後に再起動します）..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart | Out-Null
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart | Out-Null

    # 再起動後にこのスクリプトを自動継続
    $me = $MyInvocation.MyCommand.Path
    $action  = New-ScheduledTaskAction -Execute "powershell.exe" `
                   -Argument "-ExecutionPolicy Bypass -File `"$me`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    Register-ScheduledTask -TaskName "DevEnvSetup_Continue" `
        -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

    Write-Host "    再起動後、セットアップが自動的に続行されます。" -ForegroundColor Yellow
    Restart-Computer -Force
    exit
}
Write-OK "WSL2 は有効です"
wsl --set-default-version 2 2>$null | Out-Null

# ============================================================
# Step 2: Ubuntu のインストール
# ============================================================
Write-Step "Ubuntu の確認・インストール"

$distros = wsl --list --quiet 2>$null
$ubuntuReady = $distros | Where-Object { $_ -match "Ubuntu" }

if (-not $ubuntuReady) {
    Write-Host "    Ubuntu をインストールします。" -ForegroundColor Yellow
    Write-Host "    インストール後、このターミナルが Ubuntu に切り替わります。" -ForegroundColor Yellow
    Write-Host "    ユーザー名とパスワードを設定したら、'exit' と入力して PowerShell に戻ってください。" -ForegroundColor Yellow
    wsl --install -d Ubuntu
    # Ubuntu で exit するまでここで待機。exit 後に次の処理へ進む。
} else {
    Write-OK "Ubuntu はインストール済みです"
}

# ============================================================
# Step 3: WSL2 内で Docker Engine をセットアップ
# ============================================================
Write-Step "WSL2 Ubuntu 内に Docker Engine をセットアップ"

$shellScript = Join-Path $PSScriptRoot "setup-wsl.sh"
if (-not (Test-Path $shellScript)) {
    Write-Host "    エラー: setup-wsl.sh が見つかりません。" -ForegroundColor Red
    Write-Host "    setup.ps1 と同じフォルダに setup-wsl.sh を置いてください。" -ForegroundColor Red
    exit 1
}

$drive  = $shellScript.Substring(0, 1).ToLower()
$wslSh  = "/mnt/$drive/" + $shellScript.Substring(3).Replace("\", "/")
wsl -d Ubuntu bash "$wslSh"
Write-OK "Docker Engine セットアップ完了"

Write-Host "    WSL2 を再起動します（systemd 有効化）..."
wsl --shutdown
Start-Sleep -Seconds 3
Write-OK "WSL2 再起動完了"

# ============================================================
# Step 4: セットアップ自動継続のタスクを削除
# ============================================================
Write-Step "セットアップ自動継続のタスクを削除..."
Unregister-ScheduledTask -TaskName "DevEnvSetup_Continue" -Confirm:$false -ErrorAction SilentlyContinue

# ============================================================
# 完了
# ============================================================
Write-Host ""
Write-Host "========================================"  -ForegroundColor Green
Write-Host "  セットアップ完了!"                      -ForegroundColor Green
Write-Host "========================================"  -ForegroundColor Green
Write-Host @"

次のステップ:
  1. WSL2 に入る: wsl
  2. 任意のフォルダを作成してプロジェクトを clone する
  3. コンテナを起動する

"@

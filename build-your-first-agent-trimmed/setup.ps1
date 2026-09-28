<#
=============================================================================
Day2 Lab 3 ワンステップセットアップ (Windows 用)
macOS / Linux の方は setup.sh を使ってください: bash setup.sh

使い方 (このフォルダで):
  powershell -ExecutionPolicy Bypass -File setup.ps1

やること:
  1. Python 仮想環境 (.venv) を作成
  2. 依存パッケージをインストール (src/workshop/requirements.txt)
  3. .env.sample → .env をコピー (既にある場合はスキップ)
  4. ダミー CSV から SQLite (omics.db) を作成
=============================================================================
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

function Write-Info { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }

# --- Python コマンドの自動検出 (py -3 / python / python3、3.9 以上) ---
$PyArgs = $null
foreach ($cand in @(@('py', '-3'), @('python'), @('python3'))) {
  $exe = $cand[0]
  if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) { continue }
  $extra = @()
  if ($cand.Count -gt 1) { $extra = $cand[1..($cand.Count - 1)] }
  $ver = & $exe @extra -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
  if ($ver -and ($ver -match '^(\d+)\.(\d+)')) {
    $maj = [int]$Matches[1]; $min = [int]$Matches[2]
    if ($maj -gt 3 -or ($maj -eq 3 -and $min -ge 9)) {
      $PyArgs = @($exe) + $extra
      if ($min -eq 9 -and $maj -eq 3) {
        Write-Host "  [注意] ワークショップの推奨は Python 3.10 以上です (3.9 でも動作します)。" -ForegroundColor Yellow
      }
      break
    }
  }
}
if (-not $PyArgs) {
  Write-Host "エラー: Python 3.9 以上が見つかりません。先に setup\setup_env.ps1 を実行してください。" -ForegroundColor Red
  exit 1
}
$pyVerText = & $PyArgs[0] @($PyArgs | Select-Object -Skip 1) --version
Write-Info "Python を検出しました: $($PyArgs -join ' ') ($pyVerText)"

# --- 1. 仮想環境 ---
if (Test-Path .venv) {
  Write-Ok ".venv はすでに存在します (再作成しません)"
} else {
  Write-Info "仮想環境 .venv を作成します..."
  & $PyArgs[0] @($PyArgs | Select-Object -Skip 1) -m venv .venv
  if ($LASTEXITCODE -ne 0) { throw "venv の作成に失敗しました" }
  Write-Ok ".venv を作成しました"
}

$VenvPython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $VenvPython)) { throw ".venv\Scripts\python.exe が見つかりません" }

# --- 2. 依存パッケージ ---
Write-Info "依存パッケージをインストールします..."
& $VenvPython -m pip install --upgrade pip | Out-Null
& $VenvPython -m pip install -r src\workshop\requirements.txt
if ($LASTEXITCODE -ne 0) { throw "pip install に失敗しました" }
Write-Ok "依存パッケージをインストールしました"

# --- 3. .env ---
if (Test-Path .env) {
  Write-Ok ".env はすでに存在します (上書きしません)"
} else {
  Copy-Item .env.sample .env
  Write-Ok ".env.sample から .env を作成しました"
}

# --- 4. SQLite DB 作成 ---
Write-Info "ダミー CSV から SQLite データベース (omics.db) を作成します..."
& $VenvPython build_omics_db.py
if ($LASTEXITCODE -ne 0) { throw "build_omics_db.py の実行に失敗しました" }
Write-Ok "omics.db を作成しました"

Write-Host ""
Write-Info "セットアップ完了! 次のステップ:"
Write-Host @"

  1. .env をエディタで開き、2 つの値を記入してください
       PROJECT_ENDPOINT        … Lab 0 の terraform output の ai_foundry_project_endpoint
       MODEL_DEPLOYMENT_NAME   … gpt-4o

  2. エージェントを実行します
       .venv\Scripts\Activate.ps1   # 新しいターミナルの場合
       python src\workshop\main.py

"@

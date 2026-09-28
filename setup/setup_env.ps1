<#
=============================================================================
Kirin R&D Azure Workshop (Day2: 2026-09-29) 環境セットアップスクリプト
Windows (winget) 向け

使い方 (PowerShell を開いて):

  powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1
  powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1 -WithVSCode

※ 実行ポリシーでブロックされた場合は、必ず上記の -ExecutionPolicy Bypass
  付きで起動してください (このセッションだけ一時的に許可されます)。
※ インストール時に管理者権限 (UAC) の確認が出る場合があります。
  管理者権限がない場合は winget がユーザー scope でインストールを試みます。
macOS の方は setup/setup_env.sh を使ってください。
=============================================================================
#>
[CmdletBinding()]
param(
  [switch]$WithVSCode
)

$ErrorActionPreference = 'Stop'
$script:Issues = 0

function Write-Info { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  [注意] $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "  [要対応] $Msg" -ForegroundColor Red; $script:Issues++ }

# インストール直後のコマンドを現在のセッションでも見つけられるよう、
# マシン/ユーザーの PATH を再読み込みする
function Update-SessionPath {
  $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$machine;$user"
}

# winget でパッケージをインストール (冪等: すでにあればスキップ)
function Install-WingetPackage {
  param(
    [string]$Id,
    [string]$CommandName,
    [string]$DisplayName
  )
  if ($CommandName -and (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
    Write-Ok "$DisplayName はすでにインストールされています"
    return
  }
  Write-Info "$DisplayName をインストールします (winget: $Id) ..."
  winget install --id $Id -e --accept-source-agreements --accept-package-agreements --disable-interactivity
  if ($LASTEXITCODE -ne 0) {
    # 既にインストール済みなどの場合もあるため、まずコマンドの有無を再確認
    Update-SessionPath
    if ($CommandName -and (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
      Write-Ok "$DisplayName はすでにインストールされています"
      return
    }
    Write-Fail "$DisplayName のインストールに失敗しました (winget exit code: $LASTEXITCODE)。管理者権限のあるターミナルで再試行してください。"
    return
  }
  Update-SessionPath
  Write-Ok "$DisplayName をインストールしました"
}

# Terraform のバージョンが 1.12 以上 2.0 未満かを判定
function Test-TerraformVersion {
  param([string]$Version)
  $parts = $Version.Split('.')
  if ($parts.Count -lt 2) { return $false }
  $major = 0; $minor = 0
  if (-not [int]::TryParse($parts[0], [ref]$major)) { return $false }
  if (-not [int]::TryParse(($parts[1] -replace '[^0-9].*$', ''), [ref]$minor)) { return $false }
  return ($major -eq 1 -and $minor -ge 12)
}

Write-Info "Kirin Workshop 環境セットアップ (Windows / winget) を開始します。"

# --- winget 本体の確認 ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Fail "winget が見つかりません。Microsoft Store から『アプリ インストーラー』(App Installer) をインストールするか、Windows を最新に更新してから再実行してください。"
  Write-Host ""
  Write-Host "  https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor Yellow
  exit 1
}
Write-Ok "winget が見つかりました ($(winget --version))"

# --- Azure CLI ---
if (Get-Command az -ErrorAction SilentlyContinue) {
  Write-Ok "Azure CLI はすでにインストールされています"
} else {
  Install-WingetPackage -Id 'Microsoft.AzureCLI' -CommandName 'az' -DisplayName 'Azure CLI'
}

# --- Terraform (1.12 以上 2.0 未満が必要) ---
if (Get-Command terraform -ErrorAction SilentlyContinue) {
  $tfv = $null
  try {
    $tfJson = terraform version -json | ConvertFrom-Json
    $tfv = $tfJson.terraform_version
  } catch {
    $line = (terraform version | Select-Object -First 1)
    if ($line -match 'v([0-9]+\.[0-9]+(\.[0-9]+)?)') { $tfv = $Matches[1] }
  }
  if ($tfv -and (Test-TerraformVersion $tfv)) {
    Write-Ok "Terraform はすでにインストールされています (v$tfv)。再インストールはしません。"
  } else {
    Write-Warn "Terraform v$($tfv ?? '不明') が見つかりましたが、本ワークショップには v1.12 以上 2.0 未満が必要です。"
    Write-Warn "既存の Terraform は上書きしません。アップグレードする場合は:"
    Write-Warn "  winget upgrade --id HashiCorp.Terraform -e"
    $script:Issues++
  }
} else {
  Install-WingetPackage -Id 'HashiCorp.Terraform' -CommandName 'terraform' -DisplayName 'Terraform'
}

# --- Git ---
Install-WingetPackage -Id 'Git.Git' -CommandName 'git' -DisplayName 'Git'

# --- Python 3.12 (Lab 3 で使用。3.10 以上なら既存のもので OK) ---
$pyOk = $false
foreach ($cmd in @('python', 'py')) {
  $exe = Get-Command $cmd -ErrorAction SilentlyContinue
  if (-not $exe) { continue }
  $v = $null
  if ($cmd -eq 'py') {
    $v = (& py -3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null)
  } else {
    $v = (& python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null)
  }
  if ($v -and ($v -match '^(\d+)\.(\d+)')) {
    $maj = [int]$Matches[1]; $min = [int]$Matches[2]
    if ($maj -gt 3 -or ($maj -eq 3 -and $min -ge 10)) {
      Write-Ok "Python 3.10 以上が見つかりました ($cmd: $v)"
      $pyOk = $true
      break
    }
  }
}
if (-not $pyOk) {
  Install-WingetPackage -Id 'Python.Python.3.12' -CommandName 'python' -DisplayName 'Python 3.12'
}

# --- VS Code (オプション) ---
if ($WithVSCode) {
  if ((Get-Command code -ErrorAction SilentlyContinue) -or (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe")) {
    Write-Ok "VS Code はすでにインストールされています"
  } else {
    Install-WingetPackage -Id 'Microsoft.VisualStudioCode' -CommandName 'code' -DisplayName 'VS Code'
  }
} else {
  Write-Warn "VS Code はスキップしました (任意)。必要なら次を実行してください:"
  Write-Warn "  powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1 -WithVSCode"
}

# --- 最終チェックリスト ---
Write-Host ""
Write-Info "最終チェックリスト (バージョン確認)"
Write-Warn "インストール直後は、新しいターミナルを開き直さないとバージョンが正しく表示されないことがあります。"

function Show-Version {
  param([string]$Name, [scriptblock]$Cmd)
  try {
    $out = (& $Cmd 2>&1 | Select-Object -First 1)
    Write-Ok "$Name : $out"
  } catch {
    Write-Fail "$Name が見つかりません。ターミナルを開き直すか、上のログを確認してください。"
  }
}

Show-Version 'az'        { az version }
Show-Version 'terraform' { terraform version }
Show-Version 'git'       { git --version }
Show-Version 'python'    { python --version }

Write-Host ""
if ($script:Issues -gt 0) {
  Write-Warn "一部のツールに未解決の問題があります。上の [要対応] / [注意] を確認してください。"
  Write-Warn "当日 13:00-13:15 の環境セットアップ時間に講師・助教へお声がけください。"
} else {
  Write-Ok "すべての必須ツールが揃いました!"
}

Write-Host ""
Write-Info "次のステップ: Azure にログインして、使用するサブスクリプションを選択してください。"
Write-Host @"

  # Azure にログイン (ブラウザが自動で開きます)
  az login

  # 使用するサブスクリプションを指定 (座席カード記載の ID)
  az account set --subscription "<サブスクリプションID>"

  # 選択結果を目視で確認
  az account show

"@

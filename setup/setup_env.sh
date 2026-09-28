#!/usr/bin/env bash
# =============================================================================
# Kirin R&D Azure Workshop (Day2: 2026-09-29) 環境セットアップスクリプト
# macOS (Homebrew) 向け / Linux (apt) はベストエフォート対応
#
# 使い方:
#   bash setup/setup_env.sh                # 必須ツールをインストール
#   bash setup/setup_env.sh --with-vscode  # VS Code もインストール
#
# Windows の方はこのスクリプトではなく setup\setup_env.ps1 を使ってください。
# =============================================================================
set -euo pipefail

WITH_VSCODE=0
for arg in "$@"; do
  case "$arg" in
    --with-vscode) WITH_VSCODE=1 ;;
    -h|--help)
      echo "使い方: bash setup/setup_env.sh [--with-vscode]"
      exit 0
      ;;
  esac
done

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '  \033[1;32m[OK]\033[0m %s\n' "$*"; }
warn()  { printf '  \033[1;33m[注意]\033[0m %s\n' "$*"; }
fail()  { printf '  \033[1;31m[要対応]\033[0m %s\n' "$*"; }

OS="$(uname -s)"

# -----------------------------------------------------------------------------
# Windows (Git Bash など) から実行された場合は PowerShell 版へ案内して終了
# -----------------------------------------------------------------------------
case "${OS}" in
  Darwin|Linux) ;;
  *)
    echo "このスクリプトは macOS / Linux 用です。"
    echo "Windows の方は setup\setup_env.ps1 を使ってください:"
    echo "  powershell -ExecutionPolicy Bypass -File setup\setup_env.ps1"
    exit 0
    ;;
esac

# -----------------------------------------------------------------------------
# バージョン比較ヘルパー
# -----------------------------------------------------------------------------
# terraform のバージョンが 1.12 以上 2.0 未満かを判定 (0=OK, 1=NG)
tf_version_supported() {
  local ver="$1" major minor rest
  major="${ver%%.*}"
  rest="${ver#*.}"
  minor="${rest%%.*}"
  [[ "${major}" =~ ^[0-9]+$ && "${minor}" =~ ^[0-9]+$ ]] || return 1
  if [[ "${major}" -eq 1 && "${minor}" -ge 12 ]]; then return 0; fi
  return 1
}

# python のバージョンが 3.10 以上かを判定
py_version_supported() {
  local ver="$1" major minor rest
  major="${ver%%.*}"
  rest="${ver#*.}"
  minor="${rest%%.*}"
  [[ "${major}" =~ ^[0-9]+$ && "${minor}" =~ ^[0-9]+$ ]] || return 1
  if [[ "${major}" -gt 3 || ( "${major}" -eq 3 && "${minor}" -ge 10 ) ]]; then return 0; fi
  return 1
}

# 利用可能な python3 (3.10 以上) を探してコマンド名を返す。見つからなければ空
find_python() {
  local cand
  for cand in python3 python3.14 python3.13 python3.12 python3.11 python3.10; do
    if command -v "${cand}" >/dev/null 2>&1; then
      local v
      v="$("${cand}" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
      if [[ -n "${v}" ]] && py_version_supported "${v}"; then
        echo "${cand}"
        return 0
      fi
    fi
  done
  return 1
}

ISSUES=0

# =============================================================================
# macOS: Homebrew でインストール
# =============================================================================
setup_macos() {
  info "macOS を検出しました。Homebrew でセットアップします。"

  # --- Homebrew 本体 ---
  if command -v brew >/dev/null 2>&1; then
    ok "Homebrew はすでにインストールされています ($(brew --version | head -1))"
  else
    info "Homebrew が見つかりません。非対話モードでインストールします..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # このシェルでも brew を使えるようにする
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    ok "Homebrew をインストールしました"
    warn "次回以降のターミナルで brew を使うには、シェルの設定ファイル (.zprofile) に"
    warn "  eval \"\$(/opt/homebrew/bin/brew shellenv)\""
    warn "を追記してください (インストーラの案内どおりです)。"
  fi

  # --- Azure CLI ---
  if command -v az >/dev/null 2>&1; then
    local azv
    azv="$(az version 2>/dev/null | sed -n 's/.*"azure-cli": *"\([^"]*\)".*/azure-cli \1/p' | head -1)"
    ok "Azure CLI はすでにインストールされています (${azv:-検出済み})"
  else
    info "Azure CLI をインストールします..."
    brew install azure-cli
    ok "Azure CLI をインストールしました"
  fi

  # --- Terraform (1.12 以上 2.0 未満が必要) ---
  if command -v terraform >/dev/null 2>&1; then
    local tfv
    tfv="$(terraform version -json 2>/dev/null | sed -n 's/.*"terraform_version": *"\([^"]*\)".*/\1/p' | head -1)"
    [[ -z "${tfv}" ]] && tfv="$(terraform version 2>/dev/null | sed -n 's/^Terraform v\([0-9.]*\).*/\1/p' | head -1)"
    if [[ -n "${tfv}" ]] && tf_version_supported "${tfv}"; then
      ok "Terraform はすでにインストールされています (v${tfv})。再インストールはしません。"
    else
      warn "Terraform v${tfv:-不明} が見つかりましたが、本ワークショップには v1.12 以上 2.0 未満が必要です。"
      warn "既存の Terraform は上書きしません。hashicorp/tap の最新版を別途インストールしてください:"
      warn "  brew tap hashicorp/tap && brew install hashicorp/tap/terraform"
      ISSUES=$((ISSUES + 1))
    fi
  else
    info "Terraform をインストールします (hashicorp/tap)..."
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    ok "Terraform をインストールしました ($(terraform version | head -1))"
  fi

  # --- Git ---
  if command -v git >/dev/null 2>&1; then
    ok "Git はすでにインストールされています ($(git --version))"
  else
    info "Git をインストールします..."
    brew install git
    ok "Git をインストールしました"
  fi

  # --- Python 3.10+ (Lab 3 で使用) ---
  local pycmd=""
  if pycmd="$(find_python)"; then
    ok "Python 3.10 以上が見つかりました (${pycmd}: $("${pycmd}" --version))"
  else
    info "Python 3.10 以上が見つかりません。python@3.12 をインストールします..."
    brew install python@3.12
    if pycmd="$(find_python)"; then
      ok "Python をインストールしました (${pycmd}: $("${pycmd}" --version))"
    else
      fail "Python のインストールを確認できませんでした。ターミナルを開き直して再確認してください。"
      ISSUES=$((ISSUES + 1))
    fi
  fi

  # --- VS Code (オプション) ---
  if [[ "${WITH_VSCODE}" -eq 1 ]]; then
    if command -v code >/dev/null 2>&1 || [[ -d "/Applications/Visual Studio Code.app" ]]; then
      ok "VS Code はすでにインストールされています"
    else
      info "VS Code をインストールします..."
      brew install --cask visual-studio-code
      ok "VS Code をインストールしました"
    fi
  else
    warn "VS Code はスキップしました (任意)。必要なら次を実行してください:"
    warn "  bash setup/setup_env.sh --with-vscode   (または brew install --cask visual-studio-code)"
  fi
}

# =============================================================================
# Linux (apt): ベストエフォート。配布物によって手順が異なるため注意書きつき
# =============================================================================
setup_linux() {
  info "Linux を検出しました。apt ベースのディストリビューションにベストエフォートで対応します。"
  warn "Linux 版は動作保証外です。途中で失敗した場合は表示される公式手順に従ってください。"

  if ! command -v apt-get >/dev/null 2>&1; then
    fail "apt-get が見つかりません。お使いのディストリビューションの公式手順で"
    fail "Azure CLI / Terraform (>=1.12) / Git / Python 3.10+ をインストールしてください。"
    exit 1
  fi

  local SUDO=""
  if [[ "${EUID}" -ne 0 ]]; then SUDO="sudo"; fi

  ${SUDO} apt-get update

  # Git / Python は apt で入ることが多い
  command -v git >/dev/null 2>&1 || ${SUDO} apt-get install -y git
  if find_python >/dev/null 2>&1; then
    ok "Python 3.10 以上が見つかりました"
  else
    warn "python3 / python3-pip を apt でインストールしますが、バージョンが 3.10 未満の可能性があります。"
    warn "古かった場合は deadsnakes PPA などで 3.10 以上を入れてください。"
    ${SUDO} apt-get install -y python3 python3-pip python3-venv
  fi

  # Azure CLI / Terraform は公式リポジトリ追加が必要なため、専用インストーラを案内
  if command -v az >/dev/null 2>&1; then
    ok "Azure CLI はすでにインストールされています"
  else
    info "Azure CLI を Microsoft 公式スクリプトでインストールします..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | ${SUDO} bash
  fi

  if command -v terraform >/dev/null 2>&1; then
    local tfv
    tfv="$(terraform version 2>/dev/null | sed -n 's/^Terraform v\([0-9.]*\).*/\1/p' | head -1)"
    if [[ -n "${tfv}" ]] && tf_version_supported "${tfv}"; then
      ok "Terraform v${tfv} が見つかりました"
    else
      fail "Terraform v${tfv:-不明} は要件 (1.12 以上 2.0 未満) を満たしません。"
      fail "https://developer.hashicorp.com/terraform/install の手順で更新してください。"
      ISSUES=$((ISSUES + 1))
    fi
  else
    warn "Terraform は apt 標準リポジトリにありません。HashiCorp 公式リポジトリを追加します..."
    ${SUDO} apt-get install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | ${SUDO} gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      | ${SUDO} tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    ${SUDO} apt-get update && ${SUDO} apt-get install -y terraform
  fi

  warn "VS Code (任意) は https://code.visualstudio.com/ から .deb をダウンロードしてください。"
}

# =============================================================================
case "${OS}" in
  Darwin) setup_macos ;;
  Linux)  setup_linux ;;
esac

# =============================================================================
# 最終チェックリスト
# =============================================================================
echo
info "最終チェックリスト (バージョン確認)"
# az version は JSON 出力なので、見やすい 1 行に加工する
az_checklist_line() {
  az version 2>/dev/null | sed -n 's/.*"azure-cli": *"\([^"]*\)".*/azure-cli \1/p' | head -1
}
check_cmd() {
  local name="$1"; shift
  if command -v "${name}" >/dev/null 2>&1; then
    ok "$("$@" 2>&1 | head -1)"
  else
    fail "${name} が見つかりません。ターミナルを開き直すか、上のログを確認してください。"
    ISSUES=$((ISSUES + 1))
  fi
}
check_cmd az        az_checklist_line
check_cmd terraform terraform version
check_cmd git       git --version
if pycmd="$(find_python)"; then
  ok "$("${pycmd}" --version) (${pycmd})"
else
  fail "Python 3.10 以上が見つかりません。"
  ISSUES=$((ISSUES + 1))
fi

echo
if [[ "${ISSUES}" -gt 0 ]]; then
  warn "一部のツールに未解決の問題があります。上の [要対応] / [注意] を確認してください。"
  warn "当日 13:00-13:15 の環境セットアップ時間に講師・助教へお声がけください。"
else
  ok "すべての必須ツールが揃いました!"
fi

echo
info "次のステップ: Azure にログインして、使用するサブスクリプションを選択してください。"
cat <<'EOF'

  # Azure にログイン (ブラウザが自動で開きます)
  az login

  # 使用するサブスクリプションを指定 (座席カード記載の ID)
  az account set --subscription "<サブスクリプションID>"

  # 選択結果を目視で確認
  az account show

EOF

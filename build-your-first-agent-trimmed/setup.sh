#!/usr/bin/env bash
# =============================================================================
# Day2 Lab 3 ワンステップセットアップ (macOS / Linux 用)
# Windows の方は setup.ps1 を使ってください:
#   powershell -ExecutionPolicy Bypass -File setup.ps1
#
# やること:
#   1. Python 仮想環境 (.venv) を作成
#   2. 依存パッケージをインストール (src/workshop/requirements.txt)
#   3. .env.sample → .env をコピー (既にある場合はスキップ)
#   4. ダミー CSV から SQLite (omics.db) を作成
# =============================================================================
set -euo pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m[OK]\033[0m %s\n' "$*"; }

# --- Python コマンドの自動検出 (3.10 以上を優先、なければ 3.9 にフォールバック) ---
PY=""
_py_minor() {
  "$@" -c 'import sys; print(sys.version_info.minor)' 2>/dev/null || true
}
_py_major() {
  "$@" -c 'import sys; print(sys.version_info.major)' 2>/dev/null || true
}
detect_py() {
  local min_ok="$1" cand major minor
  for cand in "python3" "python" "python3.14" "python3.13" "python3.12" "python3.11" "python3.10" "py -3"; do
    # shellcheck disable=SC2086
    major="$(_py_major ${cand})"
    # shellcheck disable=SC2086
    minor="$(_py_minor ${cand})"
    [[ "${major}" =~ ^[0-9]+$ && "${minor}" =~ ^[0-9]+$ ]] || continue
    if [[ "${major}" -gt 3 || ( "${major}" -eq 3 && "${minor}" -ge "${min_ok}" ) ]]; then
      PY="${cand}"
      return 0
    fi
  done
  return 1
}

if ! detect_py 10 && ! detect_py 9; then
  echo "エラー: Python 3.9 以上が見つかりません。先に setup/setup_env.sh を実行してください。" >&2
  exit 1
fi
info "Python を検出しました: ${PY} ($(${PY} --version))"
ver_full="$(${PY} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
if [[ "${ver_full}" == "3.9" ]]; then
  echo "  [注意] ワークショップの推奨は Python 3.10 以上です (3.9 でも動作します)。"
fi

# --- 1. 仮想環境 ---
if [[ -d .venv ]]; then
  ok ".venv はすでに存在します (再作成しません)"
else
  info "仮想環境 .venv を作成します..."
  ${PY} -m venv .venv
  ok ".venv を作成しました"
fi
# shellcheck disable=SC1091
source .venv/bin/activate

# --- 2. 依存パッケージ ---
info "依存パッケージをインストールします..."
python -m pip install --upgrade pip >/dev/null
pip install -r src/workshop/requirements.txt
ok "依存パッケージをインストールしました"

# --- 3. .env ---
if [[ -f .env ]]; then
  ok ".env はすでに存在します (上書きしません)"
else
  cp .env.sample .env
  ok ".env.sample から .env を作成しました"
fi

# --- 4. SQLite DB 作成 ---
info "ダミー CSV から SQLite データベース (omics.db) を作成します..."
python build_omics_db.py
ok "omics.db を作成しました"

echo
info "セットアップ完了! 次のステップ:"
cat <<'EOF'

  1. .env をエディタで開き、2 つの値を記入してください
       PROJECT_ENDPOINT        … Lab 0 の terraform output の ai_foundry_project_endpoint
       MODEL_DEPLOYMENT_NAME   … gpt-4o

  2. エージェントを実行します
       source .venv/bin/activate   # 新しいターミナルの場合
       python src/workshop/main.py

EOF

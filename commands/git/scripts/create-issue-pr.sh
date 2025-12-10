#!/bin/bash

# Git Create Issue PR - Issue番号からブランチとDraft PRを自動作成
# Usage: ./create-issue-pr.sh <issue_number> [working_name] [base_branch]

set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Color definitions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Helper functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
error() {
    echo -e "${RED}❌ エラー: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}⚠️ 警告: $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

step() {
    echo -e "${CYAN}▶ $1${NC}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Argument validation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ $# -lt 1 ]; then
    error "引数が不足しています"
    echo ""
    echo "使用方法:"
    echo "  $0 <issue_number> [working_name] [base_branch]"
    echo ""
    echo "例:"
    echo "  $0 123                              # Issueタイトルのみでブランチ作成"
    echo "  $0 123 auth-feature                 # サフィックス付きでブランチ作成"
    echo "  $0 456 認証機能の実装               # 日本語サフィックス（自動ローマ字化）"
    echo "  $0 789 user-management develop      # ベースブランチ指定"
    exit 1
fi

ISSUE_NUMBER="$1"
WORKING_NAME="${2:-}"
BASE_BRANCH_INPUT="${3:-}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. GitHub CLI 確認
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "GitHub CLI を確認中..."
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) がインストールされていません"
    echo ""
    echo "インストール手順:"
    echo "  macOS: brew install gh"
    echo "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo "  Windows: https://github.com/cli/cli/releases"
    echo ""
    echo "インストール後、以下のコマンドで認証してください:"
    echo "  gh auth login"
    exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. Issue情報取得
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "Issue #${ISSUE_NUMBER} の情報を取得中..."
if ! ISSUE_JSON=$(gh issue view "${ISSUE_NUMBER}" --json number,title,url 2>&1); then
    error "Issue #${ISSUE_NUMBER} が見つかりません"
    echo ""
    echo "以下を確認してください:"
    echo "- Issue番号が正しいか"
    echo "- リポジトリが正しいか"
    echo "- gh コマンドが正しいリポジトリを参照しているか"
    echo ""
    echo "詳細: ${ISSUE_JSON}"
    exit 1
fi

ISSUE_TITLE=$(echo "${ISSUE_JSON}" | jq -r '.title')
ISSUE_URL=$(echo "${ISSUE_JSON}" | jq -r '.url')

success "Issue情報取得完了"
info "タイトル: ${ISSUE_TITLE}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. Issue タイトルのローマ字変換（ja2romaji使用）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "Issueタイトルのローマ字変換を確認中..."

# スクリプトディレクトリとja2romajiパスを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JA2ROMAJI_BIN="${SCRIPT_DIR}/bin/ja2romaji"

# 変換ツールの利用可否を確認
CONVERSION_AVAILABLE=false
if [ -x "${JA2ROMAJI_BIN}" ]; then
    CONVERSION_AVAILABLE=true
elif command -v ja2romaji &> /dev/null; then
    JA2ROMAJI_BIN="ja2romaji"
    CONVERSION_AVAILABLE=true
fi

# Issueタイトルに日本語が含まれているかチェック
if echo "${ISSUE_TITLE}" | grep -qP '[\p{Hiragana}\p{Katakana}\p{Han}]'; then
    info "Issueタイトルに日本語が含まれています: ${ISSUE_TITLE}"

    # 変換ツールの利用可否で分岐
    if [ "${CONVERSION_AVAILABLE}" = false ]; then
        warning "日本語→ローマ字変換ツールが見つかりません"
        echo ""
        echo "インストール方法:"
        echo "  cd ${SCRIPT_DIR}/ja2romaji"
        echo "  make install"
        echo ""
        echo "手動でローマ字に変換してください:"
        read -p "ローマ字を入力: " ISSUE_TITLE_EN

        if [ -z "${ISSUE_TITLE_EN}" ]; then
            error "ローマ字が入力されませんでした"
            exit 1
        fi

        ISSUE_TITLE_SLUG=$(echo "${ISSUE_TITLE_EN}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | cut -c1-30)
    else
        # ja2romajiで自動変換
        step "自動ローマ字変換中..."

        if ISSUE_TITLE_SLUG=$("${JA2ROMAJI_BIN}" --max-length=30 "${ISSUE_TITLE}" 2>&1); then
            success "自動変換完了: ${ISSUE_TITLE_SLUG}"
        else
            warning "自動変換に失敗しました: ${ISSUE_TITLE_SLUG}"
            echo ""
            echo "手動でローマ字に変換してください:"
            read -p "ローマ字を入力: " ISSUE_TITLE_EN

            if [ -z "${ISSUE_TITLE_EN}" ]; then
                error "ローマ字が入力されませんでした"
                exit 1
            fi

            ISSUE_TITLE_SLUG=$(echo "${ISSUE_TITLE_EN}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | cut -c1-30)
        fi
    fi
else
    # 英語の場合はそのままslug化
    ISSUE_TITLE_SLUG=$(echo "${ISSUE_TITLE}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | cut -c1-30)
fi

success "Issueタイトルslug: ${ISSUE_TITLE_SLUG}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. working_name の処理（ja2romaji使用）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WORKING_NAME_NORMALIZED=""

if [ -n "${WORKING_NAME}" ]; then
    info "working_name を処理中..."

    # 日本語検出（ひらがな、カタカナ、漢字）
    if echo "${WORKING_NAME}" | grep -qP '[\p{Hiragana}\p{Katakana}\p{Han}]'; then
        warning "日本語が検出されました: ${WORKING_NAME}"

        # 変換ツールの利用可否で分岐
        if [ "${CONVERSION_AVAILABLE}" = false ]; then
            warning "日本語→ローマ字変換ツールが見つかりません"
            echo ""
            echo "手動でローマ字に変換してください:"
            echo "例: auth-feature, user-management-screen, bug-fix"
            read -p "変換後のローマ字名: " WORKING_NAME_EN

            if [ -z "${WORKING_NAME_EN}" ]; then
                error "ローマ字名が入力されませんでした"
                exit 1
            fi

            WORKING_NAME_NORMALIZED=$(echo "${WORKING_NAME_EN}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
        else
            # ja2romajiで自動変換
            step "自動ローマ字変換中..."

            if WORKING_NAME_NORMALIZED=$("${JA2ROMAJI_BIN}" --max-length=50 "${WORKING_NAME}" 2>&1); then
                success "自動変換完了: ${WORKING_NAME_NORMALIZED}"
            else
                warning "自動変換に失敗しました: ${WORKING_NAME_NORMALIZED}"
                echo ""
                echo "手動でローマ字に変換してください:"
                read -p "変換後のローマ字名: " WORKING_NAME_EN

                if [ -z "${WORKING_NAME_EN}" ]; then
                    error "ローマ字名が入力されませんでした"
                    exit 1
                fi

                WORKING_NAME_NORMALIZED=$(echo "${WORKING_NAME_EN}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
            fi
        fi
    else
        WORKING_NAME_EN="${WORKING_NAME}"
        # 文字列正規化
        WORKING_NAME_NORMALIZED=$(echo "${WORKING_NAME_EN}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    fi

    success "正規化完了: ${WORKING_NAME_NORMALIZED}"
else
    info "working_name 省略: Issueタイトルのみでブランチ名を生成します"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. ブランチ名生成
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "ブランチ名を生成中..."

if [ -n "${WORKING_NAME_NORMALIZED}" ]; then
    BRANCH_NAME="Issue-${ISSUE_NUMBER}-${ISSUE_TITLE_SLUG}-${WORKING_NAME_NORMALIZED}"
else
    BRANCH_NAME="Issue-${ISSUE_NUMBER}-${ISSUE_TITLE_SLUG}"
fi
success "ブランチ名: ${BRANCH_NAME}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. ブランチ存在チェック
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "既存ブランチをチェック中..."
if EXISTING_BRANCH=$(git branch --list "Issue-${ISSUE_NUMBER}-*" | head -n 1 | sed 's/^[* ]*//' | tr -d ' '); then
    if [ -n "${EXISTING_BRANCH}" ]; then
        error "同じIssue番号のブランチが既に存在します"
        echo ""
        echo "既存ブランチ: ${EXISTING_BRANCH}"
        echo ""
        echo "作業を中止します。以下のいずれかを選択してください:"
        echo "1. 既存ブランチを使用する: git checkout ${EXISTING_BRANCH}"
        echo "2. working_name を指定して再実行（サフィックス追加）"
        echo "3. 既存ブランチを削除してから再実行: git branch -D ${EXISTING_BRANCH}"
        exit 1
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. base_branch_name の正規化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "ベースブランチを正規化中..."

if [ -z "${BASE_BRANCH_INPUT}" ]; then
    NORMALIZED_BASE_BRANCH="origin/main"
elif [[ "${BASE_BRANCH_INPUT}" == origin/* ]]; then
    NORMALIZED_BASE_BRANCH="${BASE_BRANCH_INPUT}"
else
    NORMALIZED_BASE_BRANCH="origin/${BASE_BRANCH_INPUT}"
fi

success "ベースブランチ: ${NORMALIZED_BASE_BRANCH}"

# ベースブランチ存在確認
info "ベースブランチの存在を確認中..."
git fetch --quiet

if ! git branch -r --list "${NORMALIZED_BASE_BRANCH}" | grep -q "${NORMALIZED_BASE_BRANCH}"; then
    error "ベースブランチ ${NORMALIZED_BASE_BRANCH} が見つかりません"
    echo ""
    echo "利用可能なリモートブランチ:"
    git branch -r
    echo ""
    echo "正しいブランチ名を指定して再実行してください。"
    exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 8. 作業ツリーの状態確認
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "作業ツリーの状態を確認中..."
if [ -n "$(git status --porcelain)" ]; then
    warning "未コミットの変更があります"
    echo ""
    echo "現在の変更を一時退避することを推奨します:"
    echo "  git stash save \"作業中の変更を一時退避\""
    echo ""
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "処理を中止しました"
        exit 0
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 9. ブランチ作成とチェックアウト
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "ブランチを作成中..."
git checkout -b "${BRANCH_NAME}" "${NORMALIZED_BASE_BRANCH}"
success "ブランチ作成完了: ${BRANCH_NAME}"
success "ベースブランチ: ${NORMALIZED_BASE_BRANCH}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 10. claudedocs/ への初回コミット作成
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "初回コミットを作成中..."
mkdir -p claudedocs

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DOC_FILE="claudedocs/issue-${ISSUE_NUMBER}-${BRANCH_NAME}.md"

cat > "${DOC_FILE}" <<EOF
# Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}

**Issue URL**: ${ISSUE_URL}

## 作業概要
${WORKING_NAME}

## ベースブランチ
${NORMALIZED_BASE_BRANCH}

## ブランチ名
${BRANCH_NAME}

## 作成日時
${TIMESTAMP}

---

## 作業ログ

<!-- ここに作業の進捗や気づきを記録してください -->
EOF

git add "${DOC_FILE}"
git commit -m "chore: Initialize work on Issue #${ISSUE_NUMBER} - ${WORKING_NAME}"
success "初回コミット作成完了: ${DOC_FILE}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 11. ブランチをリモートにプッシュ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "ブランチをリモートにプッシュ中..."
git push -u origin "${BRANCH_NAME}"
success "ブランチをリモートにプッシュ完了"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 12. Draft PR作成
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "Draft PRを作成中..."

# origin/ を除去
BASE_BRANCH_WITHOUT_ORIGIN="${NORMALIZED_BASE_BRANCH#origin/}"

if ! gh pr create \
    --draft \
    --base "${BASE_BRANCH_WITHOUT_ORIGIN}" \
    --title "[WIP] ${ISSUE_TITLE}" \
    --body "Closes #${ISSUE_NUMBER}" 2>&1; then
    warning "Draft PR の作成に失敗しました"
    echo ""
    echo "ブランチは作成済みです: ${BRANCH_NAME}"
    echo "初回コミットも完了しています。"
    echo ""
    echo "手動でPRを作成するか、以下のコマンドを実行してください:"
    echo "  gh pr create --draft --base ${BASE_BRANCH_WITHOUT_ORIGIN} --title \"[WIP] ${ISSUE_TITLE}\" --body \"Closes #${ISSUE_NUMBER}\""
else
    success "Draft PR作成完了"

    # PR URL 取得
    PR_URL=$(gh pr view --json url -q .url)
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 13. 完了メッセージ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Issue #${ISSUE_NUMBER} の作業環境を作成しました"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Issue: ${ISSUE_TITLE}"
echo "🔗 Issue URL: ${ISSUE_URL}"
echo ""
echo "🌿 ブランチ: ${BRANCH_NAME}"
echo "📂 ベースブランチ: ${NORMALIZED_BASE_BRANCH}"
echo ""
echo "📝 初回コミット: ${DOC_FILE}"
if [ -n "${PR_URL:-}" ]; then
    echo "📤 Draft PR: ${PR_URL}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "次のステップ:"
echo "1. 作業を開始してください"
echo "2. コミットを重ねてPRを更新してください"
echo "3. 準備ができたら Draft を解除してレビュー依頼してください"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

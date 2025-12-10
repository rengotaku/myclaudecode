#!/bin/bash

# Git Update PR - 変更をコミットしてPRを更新
# Usage: ./update-pr.sh [commit_message]

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
# Argument parsing
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CUSTOM_COMMIT_MESSAGE="${1:-}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. 環境確認
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "環境を確認中..."

# GitHub CLI 確認
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) がインストールされていません"
    echo ""
    echo "インストール手順:"
    echo "  macOS: brew install gh"
    echo "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    exit 1
fi

# jq 確認
if ! command -v jq &> /dev/null; then
    error "jq がインストールされていません"
    echo ""
    echo "インストール手順:"
    echo "  macOS: brew install jq"
    echo "  Linux: sudo apt-get install jq"
    exit 1
fi

# Gitリポジトリ確認
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    error "Gitリポジトリ内で実行してください"
    exit 1
fi

# 現在のブランチを取得
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "${CURRENT_BRANCH}" ]; then
    error "ブランチ名を取得できませんでした"
    exit 1
fi

success "環境確認完了"
info "現在のブランチ: ${CURRENT_BRANCH}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. PR存在確認
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "PRの存在を確認中..."

if ! PR_JSON=$(gh pr view --json number,title,url,body 2>&1); then
    error "このブランチにPRが存在しません"
    echo ""
    echo "PRを作成するには以下のコマンドを実行してください:"
    echo "  gh pr create --draft --title \"[WIP] 作業タイトル\" --body \"説明\""
    echo ""
    echo "または /git:create-issue-pr コマンドを使用してください"
    exit 1
fi

PR_NUMBER=$(echo "${PR_JSON}" | jq -r '.number')
PR_TITLE=$(echo "${PR_JSON}" | jq -r '.title')
PR_URL=$(echo "${PR_JSON}" | jq -r '.url')
PR_BODY=$(echo "${PR_JSON}" | jq -r '.body // ""')

success "PR確認完了: #${PR_NUMBER}"
info "タイトル: ${PR_TITLE}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. 変更内容の確認
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "変更内容を確認中..."

# Staged/Unstaged の変更を確認
STAGED_FILES=$(git diff --cached --name-only)
UNSTAGED_FILES=$(git diff --name-only)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard)

# 全ての変更ファイル数をカウント
TOTAL_CHANGES=0
if [ -n "${STAGED_FILES}" ]; then
    TOTAL_CHANGES=$((TOTAL_CHANGES + $(echo "${STAGED_FILES}" | wc -l)))
fi
if [ -n "${UNSTAGED_FILES}" ]; then
    TOTAL_CHANGES=$((TOTAL_CHANGES + $(echo "${UNSTAGED_FILES}" | wc -l)))
fi
if [ -n "${UNTRACKED_FILES}" ]; then
    TOTAL_CHANGES=$((TOTAL_CHANGES + $(echo "${UNTRACKED_FILES}" | wc -l)))
fi

if [ ${TOTAL_CHANGES} -eq 0 ]; then
    warning "コミットする変更がありません"
    exit 0
fi

info "変更ファイル数: ${TOTAL_CHANGES}"

# 変更内容を表示
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "変更内容:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "${STAGED_FILES}" ]; then
    echo -e "${GREEN}✓ Staged ($(echo "${STAGED_FILES}" | wc -l) files):${NC}"
    echo "${STAGED_FILES}" | sed 's/^/  /'
fi

if [ -n "${UNSTAGED_FILES}" ]; then
    echo -e "${YELLOW}⚡ Unstaged ($(echo "${UNSTAGED_FILES}" | wc -l) files):${NC}"
    echo "${UNSTAGED_FILES}" | sed 's/^/  /'
fi

if [ -n "${UNTRACKED_FILES}" ]; then
    echo -e "${CYAN}➕ Untracked ($(echo "${UNTRACKED_FILES}" | wc -l) files):${NC}"
    echo "${UNTRACKED_FILES}" | sed 's/^/  /'
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. ステージング確認
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -n "${UNSTAGED_FILES}" ] || [ -n "${UNTRACKED_FILES}" ]; then
    warning "未ステージの変更があります"
    read -p "全ての変更をステージングしますか？ (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        step "全ての変更をステージング中..."
        git add .
        success "ステージング完了"
    else
        info "ステージ済みの変更のみコミットします"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. コミットメッセージ生成または使用
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 変更ファイルの分析（常に実行）
CHANGED_FILES=$(git diff --cached --name-only)

# 差分統計を取得（常に実行）
DIFF_STAT=$(git diff --cached --numstat)
ADDED_LINES=$(echo "${DIFF_STAT}" | awk '{sum += $1} END {print sum+0}')
DELETED_LINES=$(echo "${DIFF_STAT}" | awk '{sum += $2} END {print sum+0}')

if [ -z "${CUSTOM_COMMIT_MESSAGE}" ]; then
    step "コミットメッセージを自動生成中..."

    # ファイル種別の判定
    HAS_CODE=false
    HAS_TEST=false
    HAS_DOCS=false
    COMMIT_TYPE="chore"

    while IFS= read -r file; do
        if [[ "${file}" =~ \.(ts|tsx|js|jsx|py|go|java|rs)$ ]]; then
            HAS_CODE=true
        fi
        if [[ "${file}" =~ (test|spec)\.(ts|tsx|js|jsx|py)$ ]] || [[ "${file}" =~ ^tests?/ ]]; then
            HAS_TEST=true
        fi
        if [[ "${file}" =~ \.(md|txt|rst)$ ]] || [[ "${file}" =~ ^docs?/ ]]; then
            HAS_DOCS=true
        fi
    done <<< "${CHANGED_FILES}"

    # コミットタイプの決定
    if [ ${ADDED_LINES} -gt $((DELETED_LINES * 3)) ]; then
        COMMIT_TYPE="feat"
    elif git diff --cached | grep -iq "fix\|bug\|error"; then
        COMMIT_TYPE="fix"
    elif [ "${HAS_TEST}" = true ] && [ "${HAS_CODE}" = false ]; then
        COMMIT_TYPE="test"
    elif [ "${HAS_DOCS}" = true ] && [ "${HAS_CODE}" = false ]; then
        COMMIT_TYPE="docs"
    elif [ ${ADDED_LINES} -eq ${DELETED_LINES} ]; then
        COMMIT_TYPE="refactor"
    fi

    # メッセージ本文の生成
    FIRST_FILE=$(echo "${CHANGED_FILES}" | head -n 1)
    FILE_BASENAME=$(basename "${FIRST_FILE}" | sed 's/\.[^.]*$//')
    FILE_COUNT=$(echo "${CHANGED_FILES}" | wc -l)

    if [ ${FILE_COUNT} -eq 1 ]; then
        COMMIT_MESSAGE="${COMMIT_TYPE}: Update ${FILE_BASENAME}"
    else
        COMMIT_MESSAGE="${COMMIT_TYPE}: Update ${FILE_COUNT} files including ${FILE_BASENAME}"
    fi

    info "生成されたコミットメッセージ: ${COMMIT_MESSAGE}"
    echo ""
    read -p "このメッセージを使用しますか？ (Y/n/e=編集): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ee]$ ]]; then
        read -p "コミットメッセージを入力: " COMMIT_MESSAGE
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        read -p "コミットメッセージを入力: " COMMIT_MESSAGE
    fi
else
    COMMIT_MESSAGE="${CUSTOM_COMMIT_MESSAGE}"
fi

info "コミットメッセージ: ${COMMIT_MESSAGE}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. コミット実行
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "コミット中..."

git commit -m "${COMMIT_MESSAGE}"
COMMIT_HASH=$(git rev-parse --short HEAD)

success "コミット完了: ${COMMIT_HASH}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. リモートへプッシュ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "リモートへプッシュ中..."

if git push origin "${CURRENT_BRANCH}" 2>&1; then
    success "プッシュ完了"
else
    error "プッシュに失敗しました"
    exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 8. PR概要の更新
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "PR概要を更新中..."

# タイムスタンプ生成
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 変更ファイルリストの生成（アイコン付き）
CHANGED_FILES_LIST=""
while IFS= read -r file; do
    # 変更種別を判定
    if git diff HEAD~1 HEAD --name-status | grep -q "^A.*${file}$"; then
        CHANGED_FILES_LIST="${CHANGED_FILES_LIST}- ➕ added: \`${file}\`\n"
    elif git diff HEAD~1 HEAD --name-status | grep -q "^D.*${file}$"; then
        CHANGED_FILES_LIST="${CHANGED_FILES_LIST}- ❌ deleted: \`${file}\`\n"
    else
        CHANGED_FILES_LIST="${CHANGED_FILES_LIST}- ✏️ modified: \`${file}\`\n"
    fi
done <<< "${CHANGED_FILES}"

# 変更サマリーの生成
CHANGE_SUMMARY="**変更行数**: +${ADDED_LINES} -${DELETED_LINES}"

# 更新履歴セクションの確認と追加
if echo "${PR_BODY}" | grep -q "## 📝 更新履歴"; then
    # 既存の更新履歴セクションに追加
    NEW_ENTRY="### [${TIMESTAMP}] Commit: \`${COMMIT_HASH}\`
**メッセージ**: ${COMMIT_MESSAGE}

**変更ファイル**:
${CHANGED_FILES_LIST}
${CHANGE_SUMMARY}

---
"

    # 更新履歴セクションの後に新エントリを挿入
    UPDATED_BODY=$(echo "${PR_BODY}" | awk -v entry="${NEW_ENTRY}" '
        /## 📝 更新履歴/ {
            print
            print ""
            print entry
            skip=1
            next
        }
        !skip || /^## / {
            skip=0
            print
        }
        skip
    ')
else
    # 新しく更新履歴セクションを追加
    UPDATED_BODY="${PR_BODY}

---

## 📝 更新履歴

### [${TIMESTAMP}] Commit: \`${COMMIT_HASH}\`
**メッセージ**: ${COMMIT_MESSAGE}

**変更ファイル**:
${CHANGED_FILES_LIST}
${CHANGE_SUMMARY}
"
fi

# PR概要を更新
echo "${UPDATED_BODY}" | gh pr edit "${PR_NUMBER}" --body-file -

success "PR概要更新完了"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 9. 完了メッセージ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "PR更新が完了しました"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 コミット: ${COMMIT_HASH}"
echo "💬 メッセージ: ${COMMIT_MESSAGE}"
echo "📊 変更: +${ADDED_LINES} -${DELETED_LINES}"
echo "📋 PR #${PR_NUMBER}: ${PR_TITLE}"
echo "🔗 PR URL: ${PR_URL}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

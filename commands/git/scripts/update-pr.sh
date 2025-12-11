#!/bin/bash

# Git Update PR - 変更をコミットしてPRを更新
# Usage: ./update-pr.sh [commit_message]
#
# PR本文フォーマット:
#   ## 概要
#   Issueで対応すること（Issue本文から取得）
#
#   ## 変更点
#   概要に対して対応したことを羅列
#
#   ## サブ変更
#   Issue指摘以外の対応を羅列
#
#   ## 補足
#   注意点、残作業

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
# 3. Issue番号の抽出とIssue情報取得
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "Issue情報を取得中..."

# ブランチ名からIssue番号を抽出 (例: Issue-123-xxx, feature/Issue-123-xxx)
ISSUE_NUMBER=""
if [[ "${CURRENT_BRANCH}" =~ [Ii]ssue[-_]?([0-9]+) ]]; then
    ISSUE_NUMBER="${BASH_REMATCH[1]}"
fi

ISSUE_TITLE=""
ISSUE_BODY=""

if [ -n "${ISSUE_NUMBER}" ]; then
    info "Issue番号を検出: #${ISSUE_NUMBER}"

    # Issue情報を取得
    if ISSUE_JSON=$(gh issue view "${ISSUE_NUMBER}" --json title,body 2>/dev/null); then
        ISSUE_TITLE=$(echo "${ISSUE_JSON}" | jq -r '.title // ""')
        ISSUE_BODY=$(echo "${ISSUE_JSON}" | jq -r '.body // ""')
        success "Issue情報取得完了: ${ISSUE_TITLE}"
    else
        warning "Issue #${ISSUE_NUMBER} の情報を取得できませんでした"
    fi
else
    warning "ブランチ名からIssue番号を検出できませんでした"
    info "ブランチ名形式: Issue-123-xxx または feature/Issue-123-xxx"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. 変更内容の確認
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
# 5. ステージング確認
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
# 6. コミットメッセージ生成または使用
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
# 7. コミット実行
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "コミット中..."

git commit -m "${COMMIT_MESSAGE}"
COMMIT_HASH=$(git rev-parse --short HEAD)

success "コミット完了: ${COMMIT_HASH}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 8. リモートへプッシュ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "リモートへプッシュ中..."

if git push origin "${CURRENT_BRANCH}" 2>&1; then
    success "プッシュ完了"
else
    error "プッシュに失敗しました"
    exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 9. 変更点の分類（コミットメッセージベース）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "変更点を分類中..."

# PRの全コミット履歴を取得（ベースブランチとの差分）
BASE_BRANCH=$(gh pr view --json baseRefName -q '.baseRefName' 2>/dev/null || echo "main")

# Issue関連キーワードを抽出
ISSUE_KEYWORDS=""
if [ -n "${ISSUE_TITLE}" ]; then
    # Issueタイトルから主要な単語を抽出（4文字以上）
    ISSUE_KEYWORDS=$(echo "${ISSUE_TITLE}" | tr '[:upper:]' '[:lower:]' | grep -oE '[a-z]{4,}' | sort -u || true)
fi
if [ -n "${ISSUE_BODY}" ]; then
    # Issue本文からもキーワードを抽出
    BODY_KEYWORDS=$(echo "${ISSUE_BODY}" | tr '[:upper:]' '[:lower:]' | grep -oE '[a-z]{4,}' | head -20 | sort -u || true)
    ISSUE_KEYWORDS="${ISSUE_KEYWORDS} ${BODY_KEYWORDS}"
fi

# 変更点とサブ変更を分類
MAIN_CHANGES=""
SUB_CHANGES=""

# PRに含まれる全コミットのメッセージを取得して分類
while IFS= read -r commit_msg; do
    [ -z "${commit_msg}" ] && continue

    # Issue関連かどうか判定
    IS_ISSUE_RELATED=false
    COMMIT_MSG_LOWER=$(echo "${commit_msg}" | tr '[:upper:]' '[:lower:]')

    # コミットメッセージにIssue番号が含まれているか
    if [ -n "${ISSUE_NUMBER}" ]; then
        if echo "${commit_msg}" | grep -qiE "#${ISSUE_NUMBER}|issue[- ]?${ISSUE_NUMBER}"; then
            IS_ISSUE_RELATED=true
        fi
    fi

    # Issueキーワードがコミットメッセージに含まれているか
    if [ -n "${ISSUE_KEYWORDS}" ] && [ "${IS_ISSUE_RELATED}" = false ]; then
        for word in ${ISSUE_KEYWORDS}; do
            if echo "${COMMIT_MSG_LOWER}" | grep -qi "${word}"; then
                IS_ISSUE_RELATED=true
                break
            fi
        done
    fi

    # Issue情報がない場合はデフォルトでメインの変更として扱う
    if [ -z "${ISSUE_TITLE}" ] && [ -z "${ISSUE_BODY}" ]; then
        IS_ISSUE_RELATED=true
    fi

    # 分類
    ENTRY="- ${commit_msg}"
    if [ "${IS_ISSUE_RELATED}" = true ]; then
        MAIN_CHANGES="${MAIN_CHANGES}${ENTRY}\n"
    else
        SUB_CHANGES="${SUB_CHANGES}${ENTRY}\n"
    fi
done < <(git log "${BASE_BRANCH}..HEAD" --pretty=format:"%s%n" 2>/dev/null | grep -v '^$' || echo "${COMMIT_MESSAGE}")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 10. 補足情報の入力
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "補足情報の入力"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "補足（注意点、残作業など）があれば入力してください (Enterでスキップ): " NOTES_INPUT

# 既存PR本文から補足を抽出（ある場合は引き継ぐ）
EXISTING_NOTES=""
if echo "${PR_BODY}" | grep -q "## 補足"; then
    EXISTING_NOTES=$(echo "${PR_BODY}" | sed -n '/## 補足/,/^## /p' | sed '1d;$d' | sed '/^$/d')
fi

# 補足セクションの構築
NOTES_SECTION=""
if [ -n "${NOTES_INPUT}" ] || [ -n "${EXISTING_NOTES}" ]; then
    NOTES_SECTION="## 補足\n\n"
    if [ -n "${NOTES_INPUT}" ]; then
        NOTES_SECTION="${NOTES_SECTION}- ${NOTES_INPUT}\n"
    fi
    if [ -n "${EXISTING_NOTES}" ]; then
        # 既存の補足も保持（重複しない場合）
        if [ -n "${NOTES_INPUT}" ] && ! echo "${EXISTING_NOTES}" | grep -qF "${NOTES_INPUT}"; then
            NOTES_SECTION="${NOTES_SECTION}${EXISTING_NOTES}\n"
        elif [ -z "${NOTES_INPUT}" ]; then
            NOTES_SECTION="${NOTES_SECTION}${EXISTING_NOTES}\n"
        fi
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 11. PR本文の生成
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "PR本文を生成中..."

# 概要セクション
OVERVIEW_SECTION="## 概要\n\n"
if [ -n "${ISSUE_NUMBER}" ] && [ -n "${ISSUE_TITLE}" ]; then
    OVERVIEW_SECTION="${OVERVIEW_SECTION}Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}\n\n"
    if [ -n "${ISSUE_BODY}" ]; then
        # Issue本文の最初の段落を抽出（長すぎる場合は省略）
        ISSUE_SUMMARY=$(echo "${ISSUE_BODY}" | head -20 | sed '/^$/q' | head -10)
        if [ -n "${ISSUE_SUMMARY}" ]; then
            OVERVIEW_SECTION="${OVERVIEW_SECTION}> ${ISSUE_SUMMARY}\n"
        fi
    fi
else
    OVERVIEW_SECTION="${OVERVIEW_SECTION}${PR_TITLE}\n"
fi

# 変更点セクション
CHANGES_SECTION="## 変更点\n\n"
if [ -n "${MAIN_CHANGES}" ]; then
    CHANGES_SECTION="${CHANGES_SECTION}$(echo -e "${MAIN_CHANGES}")"
else
    CHANGES_SECTION="${CHANGES_SECTION}- 変更なし\n"
fi

# サブ変更セクション（存在する場合のみ）
SUB_CHANGES_SECTION=""
if [ -n "${SUB_CHANGES}" ]; then
    SUB_CHANGES_SECTION="\n## サブ変更\n\n$(echo -e "${SUB_CHANGES}")"
fi

# 補足セクション
if [ -n "${NOTES_SECTION}" ]; then
    NOTES_SECTION="\n${NOTES_SECTION}"
fi

# PR本文を組み立て
NEW_PR_BODY=$(echo -e "${OVERVIEW_SECTION}\n${CHANGES_SECTION}${SUB_CHANGES_SECTION}${NOTES_SECTION}")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 12. PR本文の更新
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step "PR本文を更新中..."

echo "${NEW_PR_BODY}" | gh pr edit "${PR_NUMBER}" --body-file -

success "PR本文更新完了"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 13. 完了メッセージ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "PR更新が完了しました"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 コミット: ${COMMIT_HASH}"
echo "💬 メッセージ: ${COMMIT_MESSAGE}"
echo "📊 変更: +${ADDED_LINES} -${DELETED_LINES}"
if [ -n "${ISSUE_NUMBER}" ]; then
    echo "🎫 Issue: #${ISSUE_NUMBER}"
fi
echo "📋 PR #${PR_NUMBER}: ${PR_TITLE}"
echo "🔗 PR URL: ${PR_URL}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

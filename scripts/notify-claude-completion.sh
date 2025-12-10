#!/bin/bash

# Claude Code作業完了通知スクリプト（Stopフック用）
# 自動的にSlackに作業完了を通知します

set -e

# Slack Webhook URL
SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL_FOR_CLAUDE_NOTIFICATION

# 基本情報取得
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
REPO_NAME="web-todo"
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null | cut -c1-7 || echo "unknown")

# 最新のコミットメッセージを取得
LATEST_COMMIT_MSG=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "No commit message")

# 最近の作業内容を推測（最新コミットメッセージから）
if [[ "$LATEST_COMMIT_MSG" == *"feat"* ]] || [[ "$LATEST_COMMIT_MSG" == *"feature"* ]] || [[ "$LATEST_COMMIT_MSG" == *"add"* ]]; then
    WORK_TYPE="🚀 新機能実装"
elif [[ "$LATEST_COMMIT_MSG" == *"fix"* ]] || [[ "$LATEST_COMMIT_MSG" == *"bug"* ]]; then
    WORK_TYPE="🐛 バグ修正"
elif [[ "$LATEST_COMMIT_MSG" == *"refactor"* ]]; then
    WORK_TYPE="♻️ リファクタリング"
elif [[ "$LATEST_COMMIT_MSG" == *"docs"* ]] || [[ "$LATEST_COMMIT_MSG" == *"document"* ]]; then
    WORK_TYPE="📚 ドキュメント更新"
elif [[ "$LATEST_COMMIT_MSG" == *"test"* ]]; then
    WORK_TYPE="🧪 テスト追加"
else
    WORK_TYPE="⚡ コード改善"
fi

# Issue番号を抽出（コミットメッセージから #123 のような形式を探す）
ISSUE_NUM=$(echo "$LATEST_COMMIT_MSG" | grep -o '#[0-9]\+' | head -1 || echo "")
ISSUE_LINK=""
if [ -n "$ISSUE_NUM" ]; then
    ISSUE_LINK="https://github.com/rengotaku/$REPO_NAME/issues/${ISSUE_NUM#*#}"
fi

# 最近のPRを取得（gh cli利用可能な場合のみ）
RECENT_PR=""
if command -v gh >/dev/null 2>&1; then
    RECENT_PR=$(gh pr list --state merged --limit 1 --json number,title 2>/dev/null | jq -r '.[0] | "#\(.number) \(.title)"' 2>/dev/null || echo "")
fi

# Slackメッセージを構築
MESSAGE="🎉 Claude Code 作業完了！"

# JSON ペイロードを構築
PAYLOAD=$(cat <<EOF
{
  "text": "$MESSAGE",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*🎯 Claude Code - 作業完了通知*"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*🎯 作業種別:*\n$WORK_TYPE"
        },
        {
          "type": "mrkdwn",
          "text": "*⏰ 完了時刻:*\n$TIMESTAMP"
        },
        {
          "type": "mrkdwn",
          "text": "*📁 リポジトリ:*\n$REPO_NAME"
        },
        {
          "type": "mrkdwn",
          "text": "*🌿 ブランチ:*\n$CURRENT_BRANCH"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*💬 最新コミット:*\n\`$LATEST_COMMIT_MSG\`"
      }
    }
  ]
}
EOF
)

# Issue情報があれば追加
if [ -n "$ISSUE_LINK" ]; then
    # jqが利用可能な場合はjqを使用、そうでなければ手動でJSONを構築
    if command -v jq >/dev/null 2>&1; then
        PAYLOAD=$(echo "$PAYLOAD" | jq --arg issue_num "$ISSUE_NUM" --arg issue_link "$ISSUE_LINK" '.blocks += [{
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": ("*📋 関連Issue:* <" + $issue_link + "|" + $issue_num + ">")
          }
        }]')
    else
        # jqがない場合は手動でJSON文字列を追加
        ISSUE_BLOCK=",{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*📋 関連Issue:* <$ISSUE_LINK|$ISSUE_NUM>\"}}"
        PAYLOAD=$(echo "$PAYLOAD" | sed "s/\]$/,{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*📋 関連Issue:* <$ISSUE_LINK|$ISSUE_NUM>\"}}]/")
    fi
fi

# PR情報があれば追加
if [ -n "$RECENT_PR" ] && [ "$RECENT_PR" != "null" ] && [ "$RECENT_PR" != "" ]; then
    if command -v jq >/dev/null 2>&1; then
        PAYLOAD=$(echo "$PAYLOAD" | jq --arg pr_info "$RECENT_PR" '.blocks += [{
          "type": "section", 
          "text": {
            "type": "mrkdwn",
            "text": ("*🔀 関連PR:* " + $pr_info)
          }
        }]')
    fi
fi

# Slackに通知を送信
echo "🚀 Slack通知を送信中..."
if curl -X POST "$SLACK_WEBHOOK_URL" \
     -H 'Content-type: application/json' \
     --data "$PAYLOAD" \
     --silent --show-error; then
    echo "✅ Slack通知が正常に送信されました"
else
    echo "❌ Slack通知の送信に失敗しました"
    exit 1
fi
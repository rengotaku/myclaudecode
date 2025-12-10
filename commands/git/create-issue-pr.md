# Git Create Issue PR - Issue番号からブランチとDraft PRを自動作成

このコマンドは、GitHub Issueを基にして作業ブランチとDraft PRを自動生成します。

## ⚠️ 重要：Claude への指示

**このコマンドが実行されたら、以下のスクリプトを呼び出してください。スクリプトの内容を自分で実装しないでください。**

```bash
~/.claude/commands/git/scripts/create-issue-pr.sh "$issue_number" "$working_name" "$base_branch"
```

スクリプトがすべての処理を行います。Claude は引数を適切に渡すだけで済みます。

## 使用方法

```bash
/git:create-issue-pr <issue_number> <working_name> [base_branch]
```

## 引数

- **issue_number**: GitHub Issue番号（必須）
- **working_name**: 作業内容の識別子（必須、日本語可）
- **base_branch**: ベースブランチ（任意、デフォルト: main）

## 例

```bash
# 基本的な使用
/git:create-issue-pr 123 auth-feature

# 日本語の作業名
/git:create-issue-pr 456 認証機能の実装

# カスタムベースブランチ
/git:create-issue-pr 789 user-management feature/develop
```

## 処理内容

スクリプトが以下の処理を自動的に実行します：

1. ✅ 環境確認（GitHub CLI、Git リポジトリ）
2. 📋 Issue情報の取得
3. 🌐 **Issueタイトルの英語変換（Claude使用）**
   - Issueタイトルに日本語が含まれる場合、変換依頼が表示されます
   - **Claude**: 表示された日本語を英語に変換してください
   - 形式: ハイフン区切りの小文字、最大30文字
   - 例: 「Face Libraryの画像一覧を修正」→ `face-library-image-list-fix`
4. 🔤 working_name の英語変換（対話式）
5. 🌿 ブランチ名の生成
6. 🔍 既存ブランチの重複チェック
7. 📂 ベースブランチの正規化と確認
8. ⚠️ 作業ツリーの状態確認
9. ➕ ブランチ作成とチェックアウト
10. 📝 `claudedocs/` への初回コミット
11. 📤 リモートへのプッシュ
12. 🎯 Draft PR作成
13. 🎉 完了メッセージ

### 🤖 Claude の役割

**Issueタイトルに日本語が含まれる場合**、スクリプトが以下のような変換依頼を表示します：

```
【変換依頼】
以下の日本語テキストを英語に変換してください。
- ハイフン区切りの小文字形式にしてください
- 最大30文字まで
- 例: 「ユーザー管理画面の改善」→ "user-management-screen-improve"

変換対象: Face Libraryの画像一覧を修正
```

**Claude は**この依頼を見たら、適切な英語に変換して回答してください。
例: `face-library-image-list-fix`

詳細な処理内容やエラーハンドリングは、スクリプト内に実装されています。
スクリプトを直接確認してください：`~/.claude/commands/git/scripts/create-issue-pr.sh`

# Git Update PR - 変更をコミットしてPRを更新

このコマンドは、ローカルの変更をコミットし、リモートにプッシュして、PR概要を自動更新します。

## ⚠️ 重要：Claude への指示

**このコマンドが実行されたら、以下のスクリプトを呼び出してください。スクリプトの内容を自分で実装しないでください。**

```bash
~/.claude/commands/git/scripts/update-pr.sh "$commit_message"
```

スクリプトがすべての処理を行います。Claude は引数を適切に渡すだけで済みます。

## 使用方法

```bash
/git:update-pr [commit_message]
```

## 引数

- **commit_message**: コミットメッセージ（任意）
  - 指定しない場合: 変更内容から自動生成

## 例

```bash
# 自動的にコミットメッセージを生成
/git:update-pr

# カスタムコミットメッセージを指定
/git:update-pr "feat: ユーザー認証機能を追加"

# 複数行のコミットメッセージ（対話的に入力）
/git:update-pr
```

## 処理内容

スクリプトが以下の処理を自動的に実行します：

1. ✅ 環境確認（GitHub CLI、jq、Git リポジトリ、PR存在）
2. 📊 変更内容の分析（staged/unstaged/untracked）
3. 📝 コミットメッセージ自動生成（Conventional Commits形式）
4. 💬 対話的確認（ステージング、メッセージ編集）
5. ✅ コミット実行
6. 📤 リモートへプッシュ
7. 📋 PR情報の取得
8. 📝 PR概要の自動更新（更新履歴追加）
9. 🎉 完了メッセージ

### コミットメッセージ自動生成

変更内容を分析して適切なタイプを選択：
- `feat:` 新機能追加
- `fix:` バグ修正
- `refactor:` リファクタリング
- `docs:` ドキュメント更新
- `test:` テスト追加/修正
- `chore:` その他の変更

### PR概要更新形式

```markdown
## 📝 更新履歴

### [YYYY-MM-DD HH:MM:SS] Commit: `hash`
**メッセージ**: commit message
**変更ファイル**:
- ✏️ modified: file.ts
- ➕ added: new.tsx
- ❌ deleted: old.css
**変更行数**: +10 -5
```

詳細な処理内容やエラーハンドリングは、スクリプト内に実装されています。
スクリプトを直接確認してください：`~/.claude/commands/git/scripts/update-pr.sh`

# argostranslate翻訳環境セットアップガイド

日本語→英語の自動翻訳機能をGitコマンドに統合するためのセットアップ手順です。

## 📋 概要

このシステムは、Pythonの`argostranslate`ライブラリを使用して、日本語のIssueタイトルやworking_nameを自動的に英語に翻訳し、Gitブランチ名に適した形式に変換します。

## 🎯 機能

- ✅ 日本語テキストの自動翻訳（日本語→英語）
- ✅ ブランチ名用の正規化（小文字、ハイフン区切り）
- ✅ venv環境での依存関係管理
- ✅ フォールバック機能（翻訳失敗時は手動入力）

## 📦 システム要件

- Python 3.8以上
- pip（Pythonパッケージマネージャー）
- 約500MBの空きディスク容量（言語モデル用）

## 🚀 セットアップ手順

### 1. セットアップスクリプトを実行

```bash
cd ~/.claude/commands/git/scripts
./setup-translation.sh
```

### 2. セットアップ内容

スクリプトは以下の処理を自動的に実行します：

1. ✅ Python環境の確認
2. 📦 Python仮想環境（venv）の作成
3. 🔧 pipのアップグレード
4. 📥 argostranslateのインストール
5. 🌐 日本語→英語言語モデルのダウンロード
6. 🧪 動作確認テスト

### 3. セットアップ完了確認

セットアップが成功すると、以下のようなメッセージが表示されます：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 翻訳環境のセットアップが完了しました
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 venv location: ~/.claude/commands/git/scripts/venv
🐍 Python: Python 3.x.x
📦 argostranslate: installed
🌐 Language model: Japanese → English
```

## 🔧 使用方法

### コマンドラインから直接使用

```bash
cd ~/.claude/commands/git/scripts
./venv/bin/python3 ja2en.py "こんにちは、世界"
# 出力: hello-world
```

### オプション指定

```bash
# 最大文字数を指定（デフォルト: 30）
./venv/bin/python3 ja2en.py "認証機能の実装" --max-length=50
# 出力: authentication-function-implementation
```

### Gitコマンドから自動使用

翻訳環境がセットアップされていれば、`create-issue-pr.sh`が自動的に使用します：

```bash
# 日本語のIssueタイトルが自動翻訳される
/git:create-issue-pr 25 "画像一覧の修正"

# 処理フロー:
# 1. Issueタイトル「Face Libraryの画像一覧を修正」を検出
# 2. 自動翻訳: "face-library-image-list-fix"
# 3. ブランチ名生成: Issue-25-face-library-image-list-fix-image-list-fix
```

## 📁 ファイル構成

```
~/.claude/commands/git/scripts/
├── setup-translation.sh       # セットアップスクリプト
├── ja2en.py                   # 翻訳スクリプト
├── create-issue-pr.sh         # メインスクリプト（翻訳統合済み）
├── venv/                      # Python仮想環境
│   ├── bin/
│   │   └── python3
│   └── lib/
│       └── python3.x/
│           └── site-packages/
│               └── argostranslate/
└── TRANSLATION_SETUP.md       # このファイル
```

## 🔍 動作フロー

### 1. 日本語検出

```bash
ISSUE_TITLE="Face Libraryの画像一覧を修正"
# → 日本語（ひらがな、カタカナ、漢字）を検出
```

### 2. 翻訳環境チェック

```bash
if [ venv環境が存在 ]; then
    # 自動翻訳を実行
else
    # 手動入力にフォールバック
fi
```

### 3. 自動翻訳実行

```bash
python3 ja2en.py "Face Libraryの画像一覧を修正"
# → "face-library-image-list-fix"
```

### 4. ブランチ名生成

```bash
BRANCH_NAME="Issue-25-face-library-image-list-fix-ph1"
# ✅ 日本語なし、ASCII文字のみ
```

## ⚠️ トラブルシューティング

### エラー: Python3がインストールされていません

**解決方法**:
```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt-get install python3 python3-venv
```

### エラー: 翻訳環境が見つかりません

**解決方法**:
```bash
# セットアップスクリプトを再実行
~/.claude/commands/git/scripts/setup-translation.sh
```

### 翻訳の精度が低い

argostranslateはオフラインで動作する機械翻訳です。完璧な翻訳を期待しない場合は、以下の対処法があります：

1. **手動入力**: 翻訳失敗時に手動で英語を入力
2. **事前翻訳**: 重要なIssueは事前に英語タイトルを設定
3. **翻訳結果確認**: 生成されたブランチ名を確認し、必要に応じて手動調整

### venv環境の再作成

```bash
# 既存venvを削除
rm -rf ~/.claude/commands/git/scripts/venv

# セットアップスクリプトを再実行
~/.claude/commands/git/scripts/setup-translation.sh
```

## 🧪 テスト

### 翻訳テスト

```bash
cd ~/.claude/commands/git/scripts

# テスト1: 基本的な翻訳
./venv/bin/python3 ja2en.py "こんにちは、世界"
# 期待結果: hello-world

# テスト2: 長いテキスト
./venv/bin/python3 ja2en.py "ユーザー管理画面の認証機能を実装する"
# 期待結果: implement-authentication (最大30文字)

# テスト3: 最大文字数指定
./venv/bin/python3 ja2en.py "ユーザー管理画面の認証機能を実装する" --max-length=50
# 期待結果: implement-authentication-function-user-manag
```

### スクリプト統合テスト

```bash
# create-issue-pr.shの構文チェック
bash -n ~/.claude/commands/git/scripts/create-issue-pr.sh
```

## 📚 参考情報

- [argostranslate GitHub](https://github.com/argosopentech/argos-translate)
- [Python venv documentation](https://docs.python.org/3/library/venv.html)

## 💡 ベストプラクティス

1. **事前セットアップ**: プロジェクト開始時に一度セットアップ
2. **定期的な更新**: argostranslateの更新を定期的に確認
3. **バックアップ**: 重要なブランチ名は手動確認
4. **英語Issue推奨**: 可能な限り英語Issueタイトルを使用

## 🔄 アンインストール

```bash
# venv環境を削除
rm -rf ~/.claude/commands/git/scripts/venv

# 翻訳スクリプトを削除（オプション）
rm ~/.claude/commands/git/scripts/ja2en.py
rm ~/.claude/commands/git/scripts/setup-translation.sh
```

create-issue-pr.shは翻訳環境がなくても動作します（手動入力モードにフォールバック）。

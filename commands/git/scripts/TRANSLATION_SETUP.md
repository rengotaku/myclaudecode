# ja2romaji 日本語→ローマ字変換環境

日本語のIssueタイトルやworking_nameを自動的にローマ字に変換し、Gitブランチ名に適した形式に変換します。

## 概要

このシステムは、Goで実装された`ja2romaji`ツールを使用して、日本語テキストをローマ字（ヘボン式）に変換します。Kagome形態素解析器を使用して、日本語を適切に分かち書きしてからローマ字化します。

## 機能

- 日本語テキストの自動ローマ字変換（ヘボン式）
- 形態素解析による適切な単語分割
- ブランチ名用の正規化（小文字、ハイフン区切り）
- 単一バイナリで依存関係なし
- フォールバック機能（変換失敗時は手動入力）

## システム要件

- Go 1.21以上（ビルド時のみ）
- ビルド済みバイナリ使用時は依存関係なし

## ファイル構成

```
~/.claude/commands/git/scripts/
├── bin/
│   └── ja2romaji              # ビルド済みバイナリ
├── ja2romaji/                 # ソースコード
│   ├── main.go                # エントリーポイント
│   ├── romaji/                # ローマ字変換パッケージ
│   ├── go.mod
│   ├── go.sum
│   ├── Makefile
│   └── README.md
├── create-issue-pr.sh         # メインスクリプト（ja2romaji統合済み）
├── update-pr.sh               # PR更新スクリプト
└── TRANSLATION_SETUP.md       # このファイル
```

## セットアップ手順

### 1. ビルド＆インストール

```bash
cd ~/.claude/commands/git/scripts/ja2romaji
make install
```

これにより `../bin/ja2romaji` にバイナリがインストールされます。

### 2. 動作確認

```bash
~/.claude/commands/git/scripts/bin/ja2romaji "認証機能の実装"
# 出力: ninshou-kinou-no-jissou
```

## 使用方法

### コマンドラインから直接使用

```bash
cd ~/.claude/commands/git/scripts

# 基本的な変換
./bin/ja2romaji "こんにちは、世界"
# 出力: konnichiha-sekai

# 最大文字数を指定（デフォルト: 50）
./bin/ja2romaji --max-length 30 "認証機能の実装"
# 出力: ninshou-kinou-no-jissou

# 区切り文字を変更
./bin/ja2romaji --separator _ "テスト機能"
# 出力: tesuto_kinou

# 形態素解析なし（直接変換）
./bin/ja2romaji --no-morph "カタカナテキスト"
# 出力: katakanatekisuto
```

### オプション一覧

| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `--max-length N` | 50 | 最大出力文字数 |
| `--separator CHAR` | `-` | 単語区切り文字 |
| `--no-morph` | false | 形態素解析を無効化 |
| `--version` | - | バージョン表示 |
| `--help` | - | ヘルプ表示 |

### Gitコマンドから自動使用

変換環境がセットアップされていれば、`create-issue-pr.sh`が自動的に使用します：

```bash
# 日本語のIssueタイトルが自動変換される
/git:create-issue-pr 25 "画像一覧の修正"

# 処理フロー:
# 1. Issueタイトル「画像一覧を修正」を検出
# 2. 自動変換: "gazou-ichiran-wo-shuusei"
# 3. ブランチ名生成: Issue-25-gazou-ichiran-wo-shuusei
```

## 動作フロー

### 1. 日本語検出

```bash
ISSUE_TITLE="Face Libraryの画像一覧を修正"
# → 日本語（ひらがな、カタカナ、漢字）を検出
```

### 2. 変換環境チェック

```bash
if [ ja2romajiバイナリが存在 ]; then
    # 自動変換を実行
else
    # 手動入力にフォールバック
fi
```

### 3. 自動変換実行

```bash
ja2romaji "Face Libraryの画像一覧を修正"
# → "face-library-no-gazou-ichiran-wo-shuusei"
```

### 4. ブランチ名生成

```bash
BRANCH_NAME="Issue-25-face-library-no-gazou-ichiran"
# 日本語なし、ASCII文字のみ
```

## 変換の仕組み

1. **形態素解析**: Kagome + IPA辞書でテキストを単語に分割
2. **読み抽出**: 各トークンからカタカナ読みを取得
3. **ローマ字化**: カタカナをヘボン式ローマ字に変換
4. **スラグ生成**: 単語を区切り文字で結合、正規化（小文字、英数字+区切り文字のみ）
5. **長さ制限**: 指定された最大長に切り詰め

## トラブルシューティング

### エラー: バイナリが見つかりません

**解決方法**:
```bash
cd ~/.claude/commands/git/scripts/ja2romaji
make install
```

### エラー: Goがインストールされていません

**解決方法**:
```bash
# macOS
brew install go

# Ubuntu/Debian
sudo apt-get install golang-go
```

### バイナリの再ビルド

```bash
cd ~/.claude/commands/git/scripts/ja2romaji
make clean
make install
```

## 開発

### ビルド

```bash
cd ~/.claude/commands/git/scripts/ja2romaji
make build
```

### テスト

```bash
make test
```

### クロスコンパイル

```bash
# Linux
make build-linux

# macOS Intel
make build-mac-intel

# macOS ARM (M1/M2)
make build-mac-arm

# 全プラットフォーム
make build-all
```

## 依存ライブラリ

- [Kagome](https://github.com/ikawaha/kagome) - 日本語形態素解析器
- [IPA Dictionary](https://github.com/ikawaha/kagome-dict) - 形態素解析辞書

## 以前の実装との違い

| 項目 | 旧実装 (ja2en.py) | 新実装 (ja2romaji) |
|------|------------------|-------------------|
| 言語 | Python | Go |
| 方式 | 機械翻訳（日→英） | ローマ字変換 |
| 依存 | argostranslate, venv | なし（単一バイナリ） |
| サイズ | ~500MB（モデル含む） | ~15MB |
| 速度 | 遅い（モデルロード） | 高速 |
| 精度 | 翻訳品質に依存 | 一貫したローマ字出力 |

## アンインストール

```bash
# バイナリを削除
rm ~/.claude/commands/git/scripts/bin/ja2romaji

# ソースを削除（オプション）
rm -rf ~/.claude/commands/git/scripts/ja2romaji
```

create-issue-pr.shは変換環境がなくても動作します（手動入力モードにフォールバック）。

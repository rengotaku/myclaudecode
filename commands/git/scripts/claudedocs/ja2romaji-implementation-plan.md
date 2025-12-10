# ja2romaji 実装計画

## クイックスタート

### 最小限の実装手順

```bash
# 1. プロジェクト作成
cd ~/.claude/commands/git/scripts
mkdir -p ja2romaji bin
cd ja2romaji

# 2. Go モジュール初期化
go mod init github.com/takuya/ja2romaji
go get github.com/ikawaha/kagome-dict/ipa
go get github.com/ikawaha/kagome/v2/tokenizer

# 3. main.go 作成（基本実装）
# 4. ビルド
go build -o ../bin/ja2romaji .

# 5. テスト
../bin/ja2romaji "認証機能の実装"
```

## ファイル構成

```
scripts/
├── bin/
│   └── ja2romaji                  # ビルド済みバイナリ
├── ja2romaji/                     # Goプロジェクト
│   ├── go.mod                     # 依存関係定義
│   ├── go.sum                     # チェックサム
│   ├── main.go                    # エントリーポイント（~100行）
│   ├── romaji/
│   │   ├── converter.go           # 変換ロジック（~200行）
│   │   ├── converter_test.go      # テスト
│   │   └── kana_table.go          # 変換テーブル（~100行）
│   ├── Makefile                   # ビルド自動化
│   └── README.md                  # ツールドキュメント
└── create-issue-pr.sh             # 修正対象

削除予定:
├── ja2en.py                       # Python実装（削除）
├── setup-translation.sh           # セットアップスクリプト（削除）
└── venv/                          # Python環境（削除）
```

## 実装の優先順位

### Priority 1: MVP (最小動作版)
目標: 基本的な日本語→ローマ字変換が動作する

```go
// main.go - 最小実装
package main

import (
    "fmt"
    "os"
    "strings"

    "github.com/ikawaha/kagome-dict/ipa"
    "github.com/ikawaha/kagome/v2/tokenizer"
)

func main() {
    if len(os.Args) < 2 {
        fmt.Fprintln(os.Stderr, "Usage: ja2romaji <text>")
        os.Exit(1)
    }

    text := os.Args[1]
    result, err := convert(text)
    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: %v\n", err)
        os.Exit(1)
    }

    fmt.Println(result)
}

func convert(text string) (string, error) {
    // 1. Kagomeトークナイザー初期化
    t, err := tokenizer.New(ipa.Dict(), tokenizer.OmitBosEos())
    if err != nil {
        return "", err
    }

    // 2. 形態素解析
    tokens := t.Analyze(text, tokenizer.Normal)

    // 3. 読み仮名抽出とローマ字変換
    var parts []string
    for _, token := range tokens {
        reading := getReading(token)
        if reading != "" {
            romaji := kanaToRomaji(reading)
            parts = append(parts, romaji)
        }
    }

    // 4. slug化
    slug := strings.Join(parts, "-")
    slug = normalize(slug)

    return slug, nil
}

func getReading(token tokenizer.Token) string {
    // Features[7] = 読み (カタカナ)
    if len(token.Features) > 7 && token.Features[7] != "*" {
        return token.Features[7]
    }
    return ""
}

func kanaToRomaji(kana string) string {
    // 簡易実装: カタカナ→ローマ字変換
    // TODO: 完全な変換テーブル実装
    result := strings.ToLower(kana)
    // 基本的な置換
    replacements := map[string]string{
        "ニンショウ": "ninshou",
        "キノウ": "kinou",
        // ... 完全な変換テーブルへ
    }
    for k, v := range replacements {
        result = strings.ReplaceAll(result, k, v)
    }
    return result
}

func normalize(s string) string {
    // 小文字化、特殊文字除去
    s = strings.ToLower(s)
    // 英数字とハイフンのみ残す
    var result []rune
    for _, r := range s {
        if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' {
            result = append(result, r)
        }
    }
    return string(result)
}
```

**MVP完了基準**:
- [x] 基本的な日本語文字列→ローマ字変換ができる
- [x] create-issue-pr.sh から呼び出せる
- [x] エラーハンドリングがある

### Priority 2: 完全な変換テーブル実装

```go
// romaji/kana_table.go
package romaji

var kanaToRomajiTable = map[string]string{
    // 清音
    "ア": "a", "イ": "i", "ウ": "u", "エ": "e", "オ": "o",
    "カ": "ka", "キ": "ki", "ク": "ku", "ケ": "ke", "コ": "ko",
    "サ": "sa", "シ": "shi", "ス": "su", "セ": "se", "ソ": "so",
    "タ": "ta", "チ": "chi", "ツ": "tsu", "テ": "te", "ト": "to",
    "ナ": "na", "ニ": "ni", "ヌ": "nu", "ネ": "ne", "ノ": "no",
    "ハ": "ha", "ヒ": "hi", "フ": "fu", "ヘ": "he", "ホ": "ho",
    "マ": "ma", "ミ": "mi", "ム": "mu", "メ": "me", "モ": "mo",
    "ヤ": "ya", "ユ": "yu", "ヨ": "yo",
    "ラ": "ra", "リ": "ri", "ル": "ru", "レ": "re", "ロ": "ro",
    "ワ": "wa", "ヲ": "wo", "ン": "n",

    // 濁音
    "ガ": "ga", "ギ": "gi", "グ": "gu", "ゲ": "ge", "ゴ": "go",
    "ザ": "za", "ジ": "ji", "ズ": "zu", "ゼ": "ze", "ゾ": "zo",
    "ダ": "da", "ヂ": "ji", "ヅ": "zu", "デ": "de", "ド": "do",
    "バ": "ba", "ビ": "bi", "ブ": "bu", "ベ": "be", "ボ": "bo",

    // 半濁音
    "パ": "pa", "ピ": "pi", "プ": "pu", "ペ": "pe", "ポ": "po",

    // 拗音
    "キャ": "kya", "キュ": "kyu", "キョ": "kyo",
    "シャ": "sha", "シュ": "shu", "ショ": "sho",
    "チャ": "cha", "チュ": "chu", "チョ": "cho",
    "ニャ": "nya", "ニュ": "nyu", "ニョ": "nyo",
    "ヒャ": "hya", "ヒュ": "hyu", "ヒョ": "hyo",
    "ミャ": "mya", "ミュ": "myu", "ミョ": "myo",
    "リャ": "rya", "リュ": "ryu", "リョ": "ryo",
    "ギャ": "gya", "ギュ": "gyu", "ギョ": "gyo",
    "ジャ": "ja", "ジュ": "ju", "ジョ": "jo",
    "ビャ": "bya", "ビュ": "byu", "ビョ": "byo",
    "ピャ": "pya", "ピュ": "pyu", "ピョ": "pyo",
}

func ConvertKana(kana string) string {
    runes := []rune(kana)
    var result strings.Builder

    for i := 0; i < len(runes); i++ {
        // 2文字の拗音チェック
        if i+1 < len(runes) {
            twoChar := string(runes[i:i+2])
            if romaji, ok := kanaToRomajiTable[twoChar]; ok {
                result.WriteString(romaji)
                i++ // 次の文字をスキップ
                continue
            }
        }

        // 1文字変換
        oneChar := string(runes[i])
        if romaji, ok := kanaToRomajiTable[oneChar]; ok {
            result.WriteString(romaji)
        } else if oneChar == "ッ" {
            // 促音（次の子音を重ねる）
            // 簡易実装: 次の文字の最初の子音を追加
            if i+1 < len(runes) {
                nextChar := string(runes[i+1])
                if nextRomaji, ok := kanaToRomajiTable[nextChar]; ok && len(nextRomaji) > 0 {
                    result.WriteByte(nextRomaji[0])
                }
            }
        } else if oneChar == "ー" {
            // 長音（前の母音を重ねる）
            // 簡易実装: 無視 or 前の母音追加
            // ここでは無視
        } else {
            // 不明な文字はそのまま
            result.WriteString(oneChar)
        }
    }

    return result.String()
}
```

### Priority 3: オプション対応

```go
// main.go - フル実装
package main

import (
    "flag"
    "fmt"
    "os"

    "github.com/takuya/ja2romaji/romaji"
)

var (
    maxLength = flag.Int("max-length", 50, "Maximum output length")
    separator = flag.String("separator", "-", "Word separator")
    version   = flag.Bool("version", false, "Show version")
)

const Version = "1.0.0"

func main() {
    flag.Parse()

    if *version {
        fmt.Printf("ja2romaji version %s\n", Version)
        return
    }

    if flag.NArg() < 1 {
        fmt.Fprintln(os.Stderr, "Usage: ja2romaji [options] <text>")
        flag.PrintDefaults()
        os.Exit(1)
    }

    text := flag.Arg(0)

    converter := romaji.NewConverter(
        romaji.WithMaxLength(*maxLength),
        romaji.WithSeparator(*separator),
    )

    result, err := converter.Convert(text)
    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: %v\n", err)
        os.Exit(1)
    }

    fmt.Println(result)
}
```

### Priority 4: テストとビルドシステム

```makefile
# Makefile
.PHONY: build test install clean

BINARY_NAME=ja2romaji
INSTALL_DIR=../bin

build:
	go build -o $(BINARY_NAME) .

test:
	go test -v ./...

install: build
	mkdir -p $(INSTALL_DIR)
	cp $(BINARY_NAME) $(INSTALL_DIR)/

clean:
	rm -f $(BINARY_NAME)
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)

# クロスコンパイル
build-linux:
	GOOS=linux GOARCH=amd64 go build -o $(BINARY_NAME)-linux-amd64 .

build-mac:
	GOOS=darwin GOARCH=amd64 go build -o $(BINARY_NAME)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 go build -o $(BINARY_NAME)-darwin-arm64 .
```

## create-issue-pr.sh 修正

### 変更差分

```diff
-# スクリプトディレクトリとvenvパスを取得
+# スクリプトディレクトリとja2romajiパスを取得
 SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
-VENV_PYTHON="${SCRIPT_DIR}/venv/bin/python3"
-JA2EN_SCRIPT="${SCRIPT_DIR}/ja2en.py"
+JA2ROMAJI_BIN="${SCRIPT_DIR}/bin/ja2romaji"

-# 翻訳環境の確認
+# 変換ツールの確認
 TRANSLATION_AVAILABLE=false
-if [ -x "${VENV_PYTHON}" ]; then
-    if "${VENV_PYTHON}" -c "import argostranslate.translate" &> /dev/null 2>&1; then
-        TRANSLATION_AVAILABLE=true
-    fi
+if [ -x "${JA2ROMAJI_BIN}" ]; then
+    TRANSLATION_AVAILABLE=true
+elif command -v ja2romaji &> /dev/null; then
+    JA2ROMAJI_BIN="ja2romaji"
+    TRANSLATION_AVAILABLE=true
 fi

 # 翻訳機能の利用可否で分岐
 if [ "${TRANSLATION_AVAILABLE}" = false ]; then
-    warning "自動翻訳機能が利用できません"
+    warning "日本語→ローマ字変換ツールが見つかりません"
     echo ""
-    echo "必要な環境:"
-    echo "  - Python 3"
-    echo "  - argostranslate ライブラリ"
+    echo "インストール方法:"
+    echo "  cd ${SCRIPT_DIR}/ja2romaji"
+    echo "  make install"
     echo ""
-    echo "セットアップ方法:"
-    echo "  pip install argostranslate"
-    echo "  ${SCRIPT_DIR}/setup-translation.sh"
     # ...手動入力へフォールバック...
 else
-    # argostranslateで自動翻訳
-    step "自動翻訳中..."
+    # ja2romajiで自動変換
+    step "自動ローマ字変換中..."

-    if ISSUE_TITLE_SLUG=$("${VENV_PYTHON}" "${JA2EN_SCRIPT}" "${ISSUE_TITLE}" 2>&1); then
-        success "自動翻訳完了: ${ISSUE_TITLE_SLUG}"
+    if ISSUE_TITLE_SLUG=$("${JA2ROMAJI_BIN}" --max-length=30 "${ISSUE_TITLE}" 2>&1); then
+        success "自動変換完了: ${ISSUE_TITLE_SLUG}"
     else
-        warning "自動翻訳に失敗しました: ${ISSUE_TITLE_SLUG}"
+        warning "自動変換に失敗しました: ${ISSUE_TITLE_SLUG}"
         # ...手動入力へフォールバック...
     fi
```

## テスト戦略

### 単体テスト

```bash
# テストケース例
go test -v ./romaji/

# カバレッジ
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### 統合テスト

```bash
# scripts/test/integration-test.sh
#!/bin/bash
set -e

echo "Running integration tests..."

# Test 1: 基本変換
result=$(./bin/ja2romaji "認証機能")
if [[ ! "$result" =~ ^[a-z0-9-]+$ ]]; then
    echo "FAIL: Invalid output format: $result"
    exit 1
fi

# Test 2: 長さ制限
result=$(./bin/ja2romaji --max-length=10 "これは非常に長い日本語の文字列です")
if [ ${#result} -gt 10 ]; then
    echo "FAIL: Output exceeds max-length: $result"
    exit 1
fi

# Test 3: create-issue-pr.sh との統合
# (実際のIssue作成はせず、変換部分だけテスト)

echo "All integration tests passed!"
```

## マイグレーション手順

### ステップ1: 開発環境でのビルドとテスト

```bash
cd ~/.claude/commands/git/scripts/ja2romaji
make build
make test
./ja2romaji "テスト"  # 動作確認
```

### ステップ2: インストール

```bash
make install
ls -la ../bin/ja2romaji  # 確認
```

### ステップ3: create-issue-pr.sh の修正適用

```bash
# バックアップ
cp create-issue-pr.sh create-issue-pr.sh.bak

# 修正を適用（エディタまたはパッチ）
# ...
```

### ステップ4: 動作確認

```bash
# テストIssueで実行
./create-issue-pr.sh 999 "テスト機能" main
# 日本語→ローマ字変換が正常に動作することを確認
```

### ステップ5: 旧環境のクリーンアップ

```bash
# 正常動作確認後
rm -rf venv/
rm ja2en.py
rm setup-translation.sh
```

## トラブルシューティング

### 問題: ja2romajiが見つからない

```bash
# 確認
ls -la bin/ja2romaji
which ja2romaji

# 解決策
cd ja2romaji && make install
```

### 問題: 変換結果が期待と異なる

```bash
# デバッグモードで実行（実装予定）
ja2romaji --debug "問題の文字列"

# 手動フォールバックを使用
# create-issue-pr.sh 実行時に手動入力
```

### 問題: Kagomeの辞書エラー

```bash
# 依存関係の再取得
cd ja2romaji
go mod tidy
go get -u github.com/ikawaha/kagome/v2
go get -u github.com/ikawaha/kagome-dict/ipa
make clean && make build
```

## 次のステップ

1. **MVP実装**: main.go の最小実装を作成
2. **ビルドとテスト**: 動作確認
3. **変換テーブル完成**: 完全なカタカナ→ローマ字対応
4. **bashスクリプト修正**: create-issue-pr.sh 更新
5. **統合テスト**: 実際のワークフローで確認
6. **クリーンアップ**: 旧Python環境削除

# 日本語→ローマ字変換ツール設計書

## 概要
`github.com/ikawaha/kagome` を使用して、日本語テキストをローマ字（slug形式）に変換するGoツールの設計。

## 現状分析

### 現在の実装 (Python + argostranslate)
- **ツール**: `ja2en.py`
- **依存**: Python3 + argostranslate + 翻訳モデル
- **問題点**:
  - venv環境のセットアップが複雑
  - 依存関係が重い（翻訳モデルのダウンロードが必要）
  - セットアップスクリプトが必要
  - 実行時のメモリ使用量が大きい

### 新しい実装 (Go + Kagome)
- **ツール**: `ja2romaji` (Goバイナリ)
- **依存**: Go runtime（ビルド済みバイナリなら不要）
- **利点**:
  - 単一バイナリで配布可能
  - 依存関係なし（静的リンク）
  - 高速な起動と実行
  - メモリ効率的

## アーキテクチャ設計

### 1. ツール構成

```
scripts/
├── create-issue-pr.sh      # メインスクリプト（修正）
├── ja2romaji/              # 新規Goプロジェクト
│   ├── go.mod
│   ├── go.sum
│   ├── main.go             # エントリーポイント
│   ├── romaji/             # ローマ字変換パッケージ
│   │   └── converter.go
│   └── Makefile            # ビルド自動化
└── bin/
    └── ja2romaji           # ビルド済みバイナリ
```

### 2. データフロー

```
日本語入力
    ↓
[Kagome形態素解析]
    ↓
Token配列 (reading/pronunciation付き)
    ↓
[読み仮名抽出]
    ↓
カタカナ読み
    ↓
[ローマ字変換]
    ↓
slug形式出力 (lowercase, hyphen-separated)
```

### 3. 変換ロジック

#### 3.1 形態素解析
Kagomeの`reading`または`pronunciation`フィールドを使用:

```go
token.Features[7]  // reading (読み)
token.Features[8]  // pronunciation (発音)
```

出力例:
- 表層形: "認証機能"
- 読み: "ニンショウキノウ"

#### 3.2 カタカナ→ローマ字変換

標準的なヘボン式ローマ字対応表を使用:

```
ア→a, イ→i, ウ→u, エ→e, オ→o
カ→ka, キ→ki, ク→ku, ケ→ke, コ→ko
...
ン→n
ッ→(次の子音を重ねる)
ー→(長音を無視 or 母音重複)
```

#### 3.3 Slug化

1. ローマ字化: "ニンショウキノウ" → "ninshoukinou"
2. 単語区切り検出（形態素単位）: "ninshou-kinou"
3. 正規化:
   - 小文字化
   - 特殊文字除去
   - 長さ制限（オプション）

### 4. API設計

#### 4.1 コマンドラインインターフェース

```bash
ja2romaji [options] <text>

Options:
  --max-length N     出力の最大文字数 (default: 50)
  --separator CHAR   単語区切り文字 (default: -)
  --style STYLE      変換スタイル (hepburn|kunrei) (default: hepburn)
  --no-morph         形態素解析なし（直接変換）
  --version          バージョン表示
  --help             ヘルプ表示

Examples:
  ja2romaji "認証機能の実装"
  # Output: ninshou-kinou-no-jisso

  ja2romaji --max-length 30 "ユーザー管理画面の作成"
  # Output: user-kanri-gamen-no-sakusei
```

#### 4.2 プログラマティックAPI（将来的なライブラリ化）

```go
package romaji

type Converter struct {
    MaxLength int
    Separator string
    Style     Style
    UseMorph  bool
}

type Style int
const (
    Hepburn Style = iota  // ヘボン式
    Kunrei                // 訓令式
)

func NewConverter(opts ...Option) (*Converter, error)
func (c *Converter) Convert(text string) (string, error)
func (c *Converter) ConvertWithTokens(text string) (string, []Token, error)
```

## 実装計画

### Phase 1: 基本実装
1. **Go プロジェクト初期化**
   - `go mod init github.com/takuya/ja2romaji`
   - Kagome依存追加: `go get github.com/ikawaha/kagome/v2`

2. **カタカナ→ローマ字変換実装**
   - ヘボン式変換テーブル作成
   - 基本変換ロジック実装
   - 単体テスト作成

3. **形態素解析統合**
   - Kagomeトークナイザー初期化
   - 読み仮名抽出ロジック
   - 単語区切り検出

4. **CLIインターフェース実装**
   - flagパッケージでオプション処理
   - 標準入力/引数対応
   - エラーハンドリング

### Phase 2: 統合とテスト
1. **create-issue-pr.sh 修正**
   - `ja2en.py` 呼び出し → `ja2romaji` 呼び出しに変更
   - venv チェック削除
   - バイナリ存在チェック追加

2. **ビルドシステム構築**
   - Makefile作成
   - クロスコンパイル対応（Linux/macOS）
   - インストールスクリプト

3. **テストケース作成**
   - 単体テスト（カタカナ変換）
   - 統合テスト（形態素解析含む）
   - エッジケース（英数字混在、記号など）

### Phase 3: 最適化と拡張
1. **パフォーマンス最適化**
   - 辞書の事前ロード
   - メモリ使用量削減
   - 並列処理（複数入力対応）

2. **機能拡張**
   - 訓令式ローマ字対応
   - 設定ファイル対応
   - バッチ処理モード

## bashスクリプト統合設計

### 修正箇所

#### 1. 変数定義セクション (L105-108)

```bash
# 現在
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PYTHON="${SCRIPT_DIR}/venv/bin/python3"
JA2EN_SCRIPT="${SCRIPT_DIR}/ja2en.py"

# 新設計
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JA2ROMAJI_BIN="${SCRIPT_DIR}/bin/ja2romaji"
```

#### 2. 翻訳機能チェック (L110-116)

```bash
# 現在
TRANSLATION_AVAILABLE=false
if [ -x "${VENV_PYTHON}" ]; then
    if "${VENV_PYTHON}" -c "import argostranslate.translate" &> /dev/null 2>&1; then
        TRANSLATION_AVAILABLE=true
    fi
fi

# 新設計
TRANSLATION_AVAILABLE=false
if [ -x "${JA2ROMAJI_BIN}" ]; then
    # バイナリが実行可能ならOK
    TRANSLATION_AVAILABLE=true
elif command -v ja2romaji &> /dev/null; then
    # PATHにインストール済み
    JA2ROMAJI_BIN="ja2romaji"
    TRANSLATION_AVAILABLE=true
fi
```

#### 3. 翻訳実行 (L147-148, L184-185)

```bash
# 現在
if ISSUE_TITLE_SLUG=$("${PYTHON_CMD}" "${JA2EN_SCRIPT}" "${ISSUE_TITLE}" 2>&1); then

# 新設計
if ISSUE_TITLE_SLUG=$("${JA2ROMAJI_BIN}" --max-length=30 "${ISSUE_TITLE}" 2>&1); then
```

#### 4. エラーメッセージ更新 (L124-132)

```bash
# 現在
warning "自動翻訳機能が利用できません"
echo ""
echo "必要な環境:"
echo "  - Python 3"
echo "  - argostranslate ライブラリ"
echo ""
echo "セットアップ方法:"
echo "  pip install argostranslate"
echo "  ${SCRIPT_DIR}/setup-translation.sh"

# 新設計
warning "日本語→ローマ字変換ツールが見つかりません"
echo ""
echo "インストール方法:"
echo "  cd ${SCRIPT_DIR}/ja2romaji"
echo "  make install"
echo ""
echo "または、手動でビルド:"
echo "  cd ${SCRIPT_DIR}/ja2romaji"
echo "  go build -o ../bin/ja2romaji ."
```

## テスト計画

### 単体テスト

```go
// romaji/converter_test.go
func TestKatakanaToRomaji(t *testing.T) {
    tests := []struct{
        input    string
        expected string
    }{
        {"ニンショウ", "ninshou"},
        {"キノウ", "kinou"},
        {"ユーザー", "user"}, // 長音処理
        {"ガッコウ", "gakkou"}, // 促音処理
    }
    // ...
}

func TestSlugify(t *testing.T) {
    tests := []struct{
        input    string
        expected string
    }{
        {"ニンショウキノウ", "ninshou-kinou"},
        {"ユーザー管理", "user-kanri"},
    }
    // ...
}
```

### 統合テスト

```bash
# scripts/test/test-ja2romaji.sh
#!/bin/bash

# Test 1: 基本的な変換
result=$(ja2romaji "認証機能")
expected="ninshou-kinou"
if [ "$result" != "$expected" ]; then
    echo "FAIL: Expected $expected, got $result"
    exit 1
fi

# Test 2: 長い文字列と長さ制限
result=$(ja2romaji --max-length=20 "ユーザー管理画面の実装とテスト")
if [ ${#result} -gt 20 ]; then
    echo "FAIL: Output exceeds max-length"
    exit 1
fi

echo "All tests passed!"
```

## パフォーマンス目標

- **起動時間**: < 50ms
- **変換処理**: < 10ms (通常の文字列)
- **メモリ使用量**: < 20MB
- **バイナリサイズ**: < 10MB (静的リンク)

## マイグレーション手順

1. **Goツール開発と検証**
   - ja2romaji実装完了
   - テスト完了
   - バイナリビルド

2. **並行稼働期間**
   - create-issue-pr.sh で両方をサポート
   - ja2romajiを優先、フォールバックでja2en.py

3. **完全移行**
   - ja2en.py削除
   - setup-translation.sh削除
   - venv削除

4. **ドキュメント更新**
   - README更新
   - インストール手順更新

## リスク管理

### 潜在的な問題と対策

1. **辞書の不足**
   - リスク: Kagomeの辞書に含まれない専門用語
   - 対策: フォールバック機能（直接カタカナ→ローマ字変換）

2. **ビルド環境の違い**
   - リスク: 異なるOS/アーキテクチャでの動作
   - 対策: クロスコンパイル、リリースビルド自動化

3. **変換精度**
   - リスク: argostranslateとの変換結果の違い
   - 対策: テストケースで比較、必要に応じて調整

## 成功基準

- [ ] ja2romajiバイナリが正常にビルドできる
- [ ] 基本的な日本語→ローマ字変換が機能する
- [ ] create-issue-pr.shが正常に動作する
- [ ] すべてのテストケースがパスする
- [ ] パフォーマンス目標を達成する
- [ ] 既存のvenv環境を削除できる

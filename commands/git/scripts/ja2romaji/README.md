# ja2romaji - Japanese to Romaji Converter

A fast, lightweight command-line tool for converting Japanese text to romaji (romanized) slug format, using the Kagome morphological analyzer.

## Features

- **Morphological Analysis**: Uses Kagome to intelligently segment Japanese text
- **Hepburn Romanization**: Standard Hepburn-style romaji conversion
- **Slug Generation**: Produces URL-friendly lowercase slugs with configurable separators
- **Fast & Lightweight**: Single binary with no external dependencies
- **Configurable**: Customizable output length and word separators

## Installation

### From Source

```bash
cd ja2romaji
make install
```

This will build the binary and install it to `../bin/ja2romaji`.

### Build Only

```bash
make build
```

## Usage

### Basic Usage

```bash
ja2romaji "認証機能の実装"
# Output: ninshou-kinou-no-jissou
```

### With Options

```bash
# Limit output length
ja2romaji --max-length 30 "ユーザー管理画面の作成"
# Output: yuser-kanri-gamen-no-sakusei

# Custom separator
ja2romaji --separator _ "テスト機能"
# Output: tesuto_kinou

# Direct conversion (no morphological analysis)
ja2romaji --no-morph "カタカナテキスト"
# Output: katakanatekisuto
```

### Available Options

- `--max-length N`: Maximum output length (default: 50)
- `--separator CHAR`: Word separator character (default: -)
- `--no-morph`: Disable morphological analysis
- `--version`: Show version information
- `--help`: Show help message

## How It Works

1. **Morphological Analysis**: Text is analyzed using Kagome with the IPA dictionary
2. **Reading Extraction**: Katakana readings are extracted from each token
3. **Romanization**: Katakana is converted to romaji using Hepburn romanization
4. **Slug Generation**: Words are joined with separators and normalized (lowercase, alphanumeric + separator only)
5. **Length Limiting**: Output is trimmed to max-length if specified

## Examples

### Issue Branch Names

```bash
# Create branch-friendly names from Japanese issue titles
ja2romaji "ログイン機能の追加"
# Output: login-kinou-no-tsuika

ja2romaji "バグ修正：データベース接続エラー"
# Output: baguShuu-databasesetsuzokuer
```

### Integration with Shell Scripts

```bash
#!/bin/bash
ISSUE_TITLE="認証機能の実装"
SLUG=$(ja2romaji --max-length 30 "${ISSUE_TITLE}")
BRANCH_NAME="feature/${SLUG}"
echo "Branch: ${BRANCH_NAME}"
# Output: Branch: feature/ninshou-kinou-no-jissou
```

## Development

### Build

```bash
make build
```

### Run Tests

```bash
make test
```

### Clean Build Artifacts

```bash
make clean
```

### Cross-Compilation

```bash
# Linux
make build-linux

# macOS Intel
make build-mac-intel

# macOS ARM (M1/M2)
make build-mac-arm

# All platforms
make build-all
```

## Dependencies

- [Kagome](https://github.com/ikawaha/kagome) - Japanese morphological analyzer
- [IPA Dictionary](https://github.com/ikawaha/kagome-dict) - Japanese morphological dictionary

## License

This tool is part of the git workflow automation scripts.

## Related

This tool replaces the previous Python-based `ja2en.py` implementation, providing:
- Faster startup and execution
- No runtime dependencies (single static binary)
- Smaller memory footprint
- Easier deployment and maintenance

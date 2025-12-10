package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/takuya/ja2romaji/romaji"
)

const Version = "1.0.0"

var (
	maxLength = flag.Int("max-length", 50, "Maximum output length")
	separator = flag.String("separator", "-", "Word separator character")
	noMorph   = flag.Bool("no-morph", false, "Disable morphological analysis")
	version   = flag.Bool("version", false, "Show version information")
	help      = flag.Bool("help", false, "Show help message")
)

func main() {
	flag.Parse()

	if *help {
		printHelp()
		return
	}

	if *version {
		fmt.Printf("ja2romaji version %s\n", Version)
		return
	}

	if flag.NArg() < 1 {
		fmt.Fprintln(os.Stderr, "Error: No input text provided")
		fmt.Fprintln(os.Stderr, "")
		printUsage()
		os.Exit(1)
	}

	text := flag.Arg(0)

	// Create converter with options
	converter, err := romaji.NewConverter(
		romaji.WithMaxLength(*maxLength),
		romaji.WithSeparator(*separator),
		romaji.WithMorphAnalysis(!*noMorph),
	)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing converter: %v\n", err)
		os.Exit(1)
	}

	// Convert to romaji
	result, err := converter.Convert(text)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error converting text: %v\n", err)
		os.Exit(1)
	}

	// Output result
	fmt.Println(result)
}

func printUsage() {
	fmt.Fprintln(os.Stderr, "Usage: ja2romaji [options] <text>")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "Convert Japanese text to romaji slug format")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "Options:")
	flag.PrintDefaults()
}

func printHelp() {
	fmt.Println("ja2romaji - Japanese to Romaji Converter")
	fmt.Println("")
	printUsage()
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  ja2romaji \"認証機能の実装\"")
	fmt.Println("  # Output: ninshou-kinou-no-jissou")
	fmt.Println("")
	fmt.Println("  ja2romaji --max-length 30 \"ユーザー管理画面の作成\"")
	fmt.Println("  # Output: yuser-kanri-gamen-no-sakusei")
	fmt.Println("")
	fmt.Println("  ja2romaji --separator _ \"テスト機能\"")
	fmt.Println("  # Output: tesuto_kinou")
	fmt.Println("")
	fmt.Println("  ja2romaji --no-morph \"テスト\"")
	fmt.Println("  # Output: tesuto (direct conversion)")
}

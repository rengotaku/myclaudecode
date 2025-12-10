package romaji

import (
	"regexp"
	"strings"

	"github.com/ikawaha/kagome-dict/ipa"
	"github.com/ikawaha/kagome/v2/tokenizer"
)

// Converter handles Japanese to romaji conversion
type Converter struct {
	tokenizer  *tokenizer.Tokenizer
	maxLength  int
	separator  string
	useMorph   bool
}

// Option is a functional option for Converter
type Option func(*Converter)

// WithMaxLength sets the maximum output length
func WithMaxLength(length int) Option {
	return func(c *Converter) {
		c.maxLength = length
	}
}

// WithSeparator sets the word separator
func WithSeparator(sep string) Option {
	return func(c *Converter) {
		c.separator = sep
	}
}

// WithMorphAnalysis enables/disables morphological analysis
func WithMorphAnalysis(use bool) Option {
	return func(c *Converter) {
		c.useMorph = use
	}
}

// NewConverter creates a new romaji converter
func NewConverter(opts ...Option) (*Converter, error) {
	// Initialize tokenizer with IPA dictionary
	t, err := tokenizer.New(ipa.Dict(), tokenizer.OmitBosEos())
	if err != nil {
		return nil, err
	}

	c := &Converter{
		tokenizer:  t,
		maxLength:  50,
		separator:  "-",
		useMorph:   true,
	}

	for _, opt := range opts {
		opt(c)
	}

	return c, nil
}

// Convert converts Japanese text to romaji slug
func (c *Converter) Convert(text string) (string, error) {
	if c.useMorph {
		return c.convertWithMorph(text)
	}
	return c.convertDirect(text)
}

// convertWithMorph uses morphological analysis for better word segmentation
func (c *Converter) convertWithMorph(text string) (string, error) {
	tokens := c.tokenizer.Analyze(text, tokenizer.Normal)

	var parts []string
	for _, token := range tokens {
		// Get reading (katakana) from token features
		reading := c.getReading(token)
		if reading == "" {
			continue
		}

		// Convert katakana to romaji
		romaji := c.kanaToRomaji(reading)
		if romaji != "" {
			parts = append(parts, romaji)
		}
	}

	// Join with separator and normalize
	slug := strings.Join(parts, c.separator)
	slug = c.normalize(slug)

	// Apply max length
	if c.maxLength > 0 && len(slug) > c.maxLength {
		slug = slug[:c.maxLength]
		// Remove trailing separator if cut in the middle
		slug = strings.TrimSuffix(slug, c.separator)
	}

	return slug, nil
}

// convertDirect converts without morphological analysis
func (c *Converter) convertDirect(text string) (string, error) {
	romaji := c.kanaToRomaji(text)
	slug := c.normalize(romaji)

	if c.maxLength > 0 && len(slug) > c.maxLength {
		slug = slug[:c.maxLength]
	}

	return slug, nil
}

// getReading extracts reading (katakana) from token features
func (c *Converter) getReading(token tokenizer.Token) string {
	// Token features format (IPA dictionary):
	// [0] POS (part of speech)
	// [1-6] Various grammatical info
	// [7] Reading (読み) in katakana
	// [8] Pronunciation (発音) in katakana

	features := token.Features()
	if len(features) > 7 && features[7] != "*" {
		return features[7]
	}

	// Fallback to surface form if no reading available
	return token.Surface
}

// kanaToRomaji converts katakana string to romaji
func (c *Converter) kanaToRomaji(kana string) string {
	runes := []rune(kana)
	var result strings.Builder

	for i := 0; i < len(runes); i++ {
		char := runes[i]

		// Handle special characters
		switch char {
		case 'ッ':
			// Sokuon (促音) - double next consonant
			if i+1 < len(runes) {
				nextChar := string(runes[i+1])
				if romaji, ok := kanaToRomajiTable[nextChar]; ok && len(romaji) > 0 {
					result.WriteByte(romaji[0])
				}
			}
			continue

		case 'ー':
			// Long vowel mark - skip for slug simplicity
			continue

		case ' ', '　':
			// Spaces
			continue
		}

		// Try 3-character combination first (for extended sounds)
		if i+2 < len(runes) {
			threeChar := string(runes[i : i+3])
			if romaji, ok := kanaToRomajiTable[threeChar]; ok {
				result.WriteString(romaji)
				i += 2
				continue
			}
		}

		// Try 2-character combination (for yōon and other combinations)
		if i+1 < len(runes) {
			twoChar := string(runes[i : i+2])
			if romaji, ok := kanaToRomajiTable[twoChar]; ok {
				result.WriteString(romaji)
				i += 1
				continue
			}
		}

		// Try single character
		oneChar := string(char)
		if romaji, ok := kanaToRomajiTable[oneChar]; ok {
			result.WriteString(romaji)
		} else {
			// Keep unknown characters (might be ASCII already)
			if (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9') {
				result.WriteRune(char)
			}
		}
	}

	return result.String()
}

// normalize converts to lowercase, removes invalid characters
func (c *Converter) normalize(s string) string {
	// Convert to lowercase
	s = strings.ToLower(s)

	// Replace multiple separators with single
	re := regexp.MustCompile(regexp.QuoteMeta(c.separator) + `+`)
	s = re.ReplaceAllString(s, c.separator)

	// Remove characters that are not alphanumeric or separator
	var result strings.Builder
	for _, r := range s {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || string(r) == c.separator {
			result.WriteRune(r)
		}
	}

	s = result.String()

	// Trim separators from start and end
	s = strings.Trim(s, c.separator)

	return s
}

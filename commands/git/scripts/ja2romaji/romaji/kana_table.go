package romaji

// kanaToRomajiTable maps katakana characters to their Hepburn romanization
var kanaToRomajiTable = map[string]string{
	// 清音 (Seion - Unvoiced sounds)
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

	// 濁音 (Dakuon - Voiced sounds)
	"ガ": "ga", "ギ": "gi", "グ": "gu", "ゲ": "ge", "ゴ": "go",
	"ザ": "za", "ジ": "ji", "ズ": "zu", "ゼ": "ze", "ゾ": "zo",
	"ダ": "da", "ヂ": "ji", "ヅ": "zu", "デ": "de", "ド": "do",
	"バ": "ba", "ビ": "bi", "ブ": "bu", "ベ": "be", "ボ": "bo",

	// 半濁音 (Handakuon - Semi-voiced sounds)
	"パ": "pa", "ピ": "pi", "プ": "pu", "ペ": "pe", "ポ": "po",

	// 拗音 (Yōon - Palatalized sounds) - K-series
	"キャ": "kya", "キュ": "kyu", "キョ": "kyo",
	"ギャ": "gya", "ギュ": "gyu", "ギョ": "gyo",

	// S-series
	"シャ": "sha", "シュ": "shu", "ショ": "sho",
	"ジャ": "ja", "ジュ": "ju", "ジョ": "jo",

	// T-series
	"チャ": "cha", "チュ": "chu", "チョ": "cho",

	// N-series
	"ニャ": "nya", "ニュ": "nyu", "ニョ": "nyo",

	// H-series
	"ヒャ": "hya", "ヒュ": "hyu", "ヒョ": "hyo",
	"ビャ": "bya", "ビュ": "byu", "ビョ": "byo",
	"ピャ": "pya", "ピュ": "pyu", "ピョ": "pyo",

	// M-series
	"ミャ": "mya", "ミュ": "myu", "ミョ": "myo",

	// R-series
	"リャ": "rya", "リュ": "ryu", "リョ": "ryo",

	// Additional palatalized combinations
	"ファ": "fa", "フィ": "fi", "フェ": "fe", "フォ": "fo",
	"ウィ": "wi", "ウェ": "we", "ウォ": "wo",
	"ヴァ": "va", "ヴィ": "vi", "ヴ": "vu", "ヴェ": "ve", "ヴォ": "vo",
	"ティ": "ti", "ディ": "di",
	"トゥ": "tu", "ドゥ": "du",
	"ツァ": "tsa", "ツィ": "tsi", "ツェ": "tse", "ツォ": "tso",
}


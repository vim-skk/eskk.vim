" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables {{{
" s:ROM_TABLE {{{
"
" TODO
" 'kana' is for 'autoload/skk7/mode/kana.vim'.
" Move it to there.
" User can modify the table each mode
" if 'hira' and 'kana' config are separated.
"
" TODO
" Move the tables to 'autoload/skk7/table/*'.
"
let s:ROM_TABLE = {
\   "a": {"hira": "あ", "kana": "ア"},
\   "bb": {"hira": "っ", "kana": "ッ", "rest": "b"},
\   "ba": {"hira": "ば", "kana": "バ"},
\   "be": {"hira": "べ", "kana": "ベ"},
\   "bi": {"hira": "び", "kana": "ビ"},
\   "bo": {"hira": "ぼ", "kana": "ボ"},
\   "bu": {"hira": "ぶ", "kana": "ブ"},
\   "bya": {"hira": "びゃ", "kana": "ビャ"},
\   "bye": {"hira": "びぇ", "kana": "ビェ"},
\   "byi": {"hira": "びぃ", "kana": "ビィ"},
\   "byo": {"hira": "びょ", "kana": "ビョ"},
\   "byu": {"hira": "びゅ", "kana": "ビュ"},
\   "cc": {"hira": "っ", "kana": "ッ", "rest": "c"},
\   "cha": {"hira": "ちゃ", "kana": "チャ"},
\   "che": {"hira": "ちぇ", "kana": "チェ"},
\   "chi": {"hira": "ち", "kana": "チ"},
\   "cho": {"hira": "ちょ", "kana": "チョ"},
\   "chu": {"hira": "ちゅ", "kana": "チュ"},
\   "cya": {"hira": "ちゃ", "kana": "チャ"},
\   "cye": {"hira": "ちぇ", "kana": "チェ"},
\   "cyi": {"hira": "ちぃ", "kana": "チィ"},
\   "cyo": {"hira": "ちょ", "kana": "チョ"},
\   "cyu": {"hira": "ちゅ", "kana": "チュ"},
\   "dd": {"hira": "っ", "kana": "ッ", "rest": "d"},
\   "da": {"hira": "だ", "kana": "ダ"},
\   "de": {"hira": "で", "kana": "デ"},
\   "dha": {"hira": "でゃ", "kana": "デャ"},
\   "dhe": {"hira": "でぇ", "kana": "デェ"},
\   "dhi": {"hira": "でぃ", "kana": "ディ"},
\   "dho": {"hira": "でょ", "kana": "デョ"},
\   "dhu": {"hira": "でゅ", "kana": "デュ"},
\   "di": {"hira": "ぢ", "kana": "ヂ"},
\   "do": {"hira": "ど", "kana": "ド"},
\   "du": {"hira": "づ", "kana": "ヅ"},
\   "dya": {"hira": "ぢゃ", "kana": "ヂャ"},
\   "dye": {"hira": "ぢぇ", "kana": "ヂェ"},
\   "dyi": {"hira": "ぢぃ", "kana": "ヂィ"},
\   "dyo": {"hira": "ぢょ", "kana": "ヂョ"},
\   "dyu": {"hira": "ぢゅ", "kana": "ヂュ"},
\   "e": {"hira": "え", "kana": "エ"},
\   "ff": {"hira": "っ", "kana": "ッ", "rest": "f"},
\   "fa": {"hira": "ふぁ", "kana": "ファ"},
\   "fe": {"hira": "ふぇ", "kana": "フェ"},
\   "fi": {"hira": "ふぃ", "kana": "フィ"},
\   "fo": {"hira": "ふぉ", "kana": "フォ"},
\   "fu": {"hira": "ふ", "kana": "フ"},
\   "fya": {"hira": "ふゃ", "kana": "フャ"},
\   "fye": {"hira": "ふぇ", "kana": "フェ"},
\   "fyi": {"hira": "ふぃ", "kana": "フィ"},
\   "fyo": {"hira": "ふょ", "kana": "フョ"},
\   "fyu": {"hira": "ふゅ", "kana": "フュ"},
\   "gg": {"hira": "っ", "kana": "ッ", "rest": "g"},
\   "ga": {"hira": "が", "kana": "ガ"},
\   "ge": {"hira": "げ", "kana": "ゲ"},
\   "gi": {"hira": "ぎ", "kana": "ギ"},
\   "go": {"hira": "ご", "kana": "ゴ"},
\   "gu": {"hira": "ぐ", "kana": "グ"},
\   "gya": {"hira": "ぎゃ", "kana": "ギャ"},
\   "gye": {"hira": "ぎぇ", "kana": "ギェ"},
\   "gyi": {"hira": "ぎぃ", "kana": "ギィ"},
\   "gyo": {"hira": "ぎょ", "kana": "ギョ"},
\   "gyu": {"hira": "ぎゅ", "kana": "ギュ"},
\   "ha": {"hira": "は", "kana": "ハ"},
\   "he": {"hira": "へ", "kana": "ヘ"},
\   "hi": {"hira": "ひ", "kana": "ヒ"},
\   "ho": {"hira": "ほ", "kana": "ホ"},
\   "hu": {"hira": "ふ", "kana": "フ"},
\   "hya": {"hira": "ひゃ", "kana": "ヒャ"},
\   "hye": {"hira": "ひぇ", "kana": "ヒェ"},
\   "hyi": {"hira": "ひぃ", "kana": "ヒィ"},
\   "hyo": {"hira": "ひょ", "kana": "ヒョ"},
\   "hyu": {"hira": "ひゅ", "kana": "ヒュ"},
\   "i": {"hira": "い", "kana": "イ"},
\   "jj": {"hira": "っ", "kana": "ッ", "rest": "j"},
\   "ja": {"hira": "じゃ", "kana": "ジャ"},
\   "je": {"hira": "じぇ", "kana": "ジェ"},
\   "ji": {"hira": "じ", "kana": "ジ"},
\   "jo": {"hira": "じょ", "kana": "ジョ"},
\   "ju": {"hira": "じゅ", "kana": "ジュ"},
\   "jya": {"hira": "じゃ", "kana": "ジャ"},
\   "jye": {"hira": "じぇ", "kana": "ジェ"},
\   "jyi": {"hira": "じぃ", "kana": "ジィ"},
\   "jyo": {"hira": "じょ", "kana": "ジョ"},
\   "jyu": {"hira": "じゅ", "kana": "ジュ"},
\   "kk": {"hira": "っ", "kana": "ッ", "rest": "k"},
\   "ka": {"hira": "か", "kana": "カ"},
\   "ke": {"hira": "け", "kana": "ケ"},
\   "ki": {"hira": "き", "kana": "キ"},
\   "ko": {"hira": "こ", "kana": "コ"},
\   "ku": {"hira": "く", "kana": "ク"},
\   "kya": {"hira": "きゃ", "kana": "キャ"},
\   "kye": {"hira": "きぇ", "kana": "キェ"},
\   "kyi": {"hira": "きぃ", "kana": "キィ"},
\   "kyo": {"hira": "きょ", "kana": "キョ"},
\   "kyu": {"hira": "きゅ", "kana": "キュ"},
\   "ma": {"hira": "ま", "kana": "マ"},
\   "me": {"hira": "め", "kana": "メ"},
\   "mi": {"hira": "み", "kana": "ミ"},
\   "mo": {"hira": "も", "kana": "モ"},
\   "mu": {"hira": "む", "kana": "ム"},
\   "mya": {"hira": "みゃ", "kana": "ミャ"},
\   "mye": {"hira": "みぇ", "kana": "ミェ"},
\   "myi": {"hira": "みぃ", "kana": "ミィ"},
\   "myo": {"hira": "みょ", "kana": "ミョ"},
\   "myu": {"hira": "みゅ", "kana": "ミュ"},
\   "n": {"hira": "ん", "kana": "ン"},
\   "n'": {"hira": "ん", "kana": "ン"},
\   "na": {"hira": "な", "kana": "ナ"},
\   "ne": {"hira": "ね", "kana": "ネ"},
\   "ni": {"hira": "に", "kana": "ニ"},
\   "nn": {"hira": "ん", "kana": "ン"},
\   "no": {"hira": "の", "kana": "ノ"},
\   "nu": {"hira": "ぬ", "kana": "ヌ"},
\   "nya": {"hira": "にゃ", "kana": "ニャ"},
\   "nye": {"hira": "にぇ", "kana": "ニェ"},
\   "nyi": {"hira": "にぃ", "kana": "ニィ"},
\   "nyo": {"hira": "にょ", "kana": "ニョ"},
\   "nyu": {"hira": "にゅ", "kana": "ニュ"},
\   "o": {"hira": "お", "kana": "オ"},
\   "pp": {"hira": "っ", "kana": "ッ", "rest": "p"},
\   "pa": {"hira": "ぱ", "kana": "パ"},
\   "pe": {"hira": "ぺ", "kana": "ペ"},
\   "pi": {"hira": "ぴ", "kana": "ピ"},
\   "po": {"hira": "ぽ", "kana": "ポ"},
\   "pu": {"hira": "ぷ", "kana": "プ"},
\   "pya": {"hira": "ぴゃ", "kana": "ピャ"},
\   "pye": {"hira": "ぴぇ", "kana": "ピェ"},
\   "pyi": {"hira": "ぴぃ", "kana": "ピィ"},
\   "pyo": {"hira": "ぴょ", "kana": "ピョ"},
\   "pyu": {"hira": "ぴゅ", "kana": "ピュ"},
\   "rr": {"hira": "っ", "kana": "ッ", "rest": "r"},
\   "ra": {"hira": "ら", "kana": "ラ"},
\   "re": {"hira": "れ", "kana": "レ"},
\   "ri": {"hira": "り", "kana": "リ"},
\   "ro": {"hira": "ろ", "kana": "ロ"},
\   "ru": {"hira": "る", "kana": "ル"},
\   "rya": {"hira": "りゃ", "kana": "リャ"},
\   "rye": {"hira": "りぇ", "kana": "リェ"},
\   "ryi": {"hira": "りぃ", "kana": "リィ"},
\   "ryo": {"hira": "りょ", "kana": "リョ"},
\   "ryu": {"hira": "りゅ", "kana": "リュ"},
\   "ss": {"hira": "っ", "kana": "ッ", "rest": "s"},
\   "sa": {"hira": "さ", "kana": "サ"},
\   "se": {"hira": "せ", "kana": "セ"},
\   "sha": {"hira": "しゃ", "kana": "シャ"},
\   "she": {"hira": "しぇ", "kana": "シェ"},
\   "shi": {"hira": "し", "kana": "シ"},
\   "sho": {"hira": "しょ", "kana": "ショ"},
\   "shu": {"hira": "しゅ", "kana": "シュ"},
\   "si": {"hira": "し", "kana": "シ"},
\   "so": {"hira": "そ", "kana": "ソ"},
\   "su": {"hira": "す", "kana": "ス"},
\   "sya": {"hira": "しゃ", "kana": "シャ"},
\   "sye": {"hira": "しぇ", "kana": "シェ"},
\   "syi": {"hira": "しぃ", "kana": "シィ"},
\   "syo": {"hira": "しょ", "kana": "ショ"},
\   "syu": {"hira": "しゅ", "kana": "シュ"},
\   "tt": {"hira": "っ", "kana": "ッ", "rest": "t"},
\   "ta": {"hira": "た", "kana": "タ"},
\   "te": {"hira": "て", "kana": "テ"},
\   "tha": {"hira": "てぁ", "kana": "テァ"},
\   "the": {"hira": "てぇ", "kana": "テェ"},
\   "thi": {"hira": "てぃ", "kana": "ティ"},
\   "tho": {"hira": "てょ", "kana": "テョ"},
\   "thu": {"hira": "てゅ", "kana": "テュ"},
\   "ti": {"hira": "ち", "kana": "チ"},
\   "to": {"hira": "と", "kana": "ト"},
\   "tsu": {"hira": "つ", "kana": "ツ"},
\   "tu": {"hira": "つ", "kana": "ツ"},
\   "tya": {"hira": "ちゃ", "kana": "チャ"},
\   "tye": {"hira": "ちぇ", "kana": "チェ"},
\   "tyi": {"hira": "ちぃ", "kana": "チィ"},
\   "tyo": {"hira": "ちょ", "kana": "チョ"},
\   "tyu": {"hira": "ちゅ", "kana": "チュ"},
\   "u": {"hira": "う", "kana": "ウ"},
\   "vv": {"hira": "っ", "kana": "ッ", "rest": "v"},
\   "va": {"hira": "う゛ぁ", "kana": "ヴァ"},
\   "ve": {"hira": "う゛ぇ", "kana": "ヴェ"},
\   "vi": {"hira": "う゛ぃ", "kana": "ヴィ"},
\   "vo": {"hira": "う゛ぉ", "kana": "ヴォ"},
\   "vu": {"hira": "う゛", "kana": "ヴ"},
\   "ww": {"hira": "っ", "kana": "ッ", "rest": "w"},
\   "wa": {"hira": "わ", "kana": "ワ"},
\   "we": {"hira": "うぇ", "kana": "ウェ"},
\   "wi": {"hira": "うぃ", "kana": "ウィ"},
\   "wo": {"hira": "を", "kana": "ヲ"},
\   "wu": {"hira": "う", "kana": "ウ"},
\   "xx": {"hira": "っ", "kana": "ッ", "rest": "x"},
\   "xa": {"hira": "ぁ", "kana": "ァ"},
\   "xe": {"hira": "ぇ", "kana": "ェ"},
\   "xi": {"hira": "ぃ", "kana": "ィ"},
\   "xka": {"hira": "か", "kana": "ヵ"},
\   "xke": {"hira": "け", "kana": "ヶ"},
\   "xo": {"hira": "ぉ", "kana": "ォ"},
\   "xtsu": {"hira": "っ", "kana": "ッ"},
\   "xtu": {"hira": "っ", "kana": "ッ"},
\   "xu":  {"hira": "ぅ", "kana": "ゥ"},
\   "xwa": {"hira": "ゎ", "kana": "ヮ"},
\   "xwe": {"hira": "ゑ", "kana": "ヱ"},
\   "xwi": {"hira": "ゐ", "kana": "ヰ"},
\   "xya": {"hira": "ゃ", "kana": "ャ"},
\   "xyo": {"hira": "ょ", "kana": "ョ"},
\   "xyu": {"hira": "ゅ", "kana": "ュ"},
\   "yy": {"hira": "っ", "kana": "ッ", "rest": "y"},
\   "ya": {"hira": "や", "kana": "ヤ"},
\   "ye": {"hira": "いぇ", "kana": "イェ"},
\   "yo": {"hira": "よ", "kana": "ヨ"},
\   "yu": {"hira": "ゆ", "kana": "ユ"},
\   "zz": {"hira": "っ", "kana": "ッ", "rest": "z"},
\   "z,": {"hira": "‥"},
\   "z-": {"hira": "～"},
\   "z.": {"hira": "…"},
\   "z/": {"hira": "・"},
\   "z[": {"hira": "『"},
\   "z]": {"hira": "』"},
\   "za": {"hira": "ざ", "kana": "ザ"},
\   "ze": {"hira": "ぜ", "kana": "ゼ"},
\   "zh": {"hira": "←"},
\   "zi": {"hira": "じ", "kana": "ジ"},
\   "zj": {"hira": "↓"},
\   "zk": {"hira": "↑"},
\   "zl": {"hira": "→"},
\   "zo": {"hira": "ぞ", "kana": "ゾ"},
\   "zu": {"hira": "ず", "kana": "ズ"},
\   "zya": {"hira": "じゃ", "kana": "ジャ"},
\   "zye": {"hira": "じぇ", "kana": "ジェ"},
\   "zyi": {"hira": "じぃ", "kana": "ジィ"},
\   "zyo": {"hira": "じょ", "kana": "ジョ"},
\   "zyu": {"hira": "じゅ", "kana": "ジュ"},
\   "-": {"hira": "ー"},
\   ":": {"hira": "："},
\   ";": {"hira": "；"},
\   "!": {"hira": "！"},
\   "?": {"hira": "？"},
\   "[": {"hira": "「"},
\   "]": {"hira": "」"},
\}
" }}}

let s:BS = "\<C-h>"
" }}}


" Functions {{{

" Each mode must have 'load()' function
" to check if its mode exists.
func! skk7#mode#hira#load() "{{{
endfunc "}}}

" This function will be called from autoload/skk7.vim.
func! skk7#mode#hira#initialize() "{{{
    let g:skk7#rom_str_buf = ''
endfunc "}}}

func! skk7#mode#hira#enable(again) "{{{
    if !a:again
        return skk7#dispatch_key('', skk7#from_mode('hira'))
    else
        call skk7#mode#hira#initialize()
        return ''
    endif
endfunc "}}}



" Callbacks

func! skk7#mode#hira#cb_im_enter() "{{{
    call skk7#mode#hira#initialize()
endfunc "}}}



" Filter functions

func! skk7#mode#hira#filter_main(char, from, buf_str, filtered_str, buf_char, henkan_count) "{{{
    let orig_rom_str_buf = g:skk7#rom_str_buf
    let g:skk7#rom_str_buf .= a:char

    let def = skk7#table#rom_to_hira#get_definition()
    if has_key(def, g:skk7#rom_str_buf)
        let rest = get(def[g:skk7#rom_str_buf], 'rest', '')
        try
            let bs = repeat(s:BS, skk7#util#mb_strlen(orig_rom_str_buf))
            return bs . def[g:skk7#rom_str_buf].map_to . rest
        finally
            let g:skk7#rom_str_buf = rest
        endtry
    elseif skk7#table#has_candidates('rom_to_hira')
        return a:char
    else
        let g:skk7#rom_str_buf = strpart(
        \   orig_rom_str_buf,
        \   0,
        \   strlen(orig_rom_str_buf) - 1
        \) . a:char
        return s:BS . a:char
    endif
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

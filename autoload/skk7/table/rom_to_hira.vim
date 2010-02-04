" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! skk7#table#rom_to_hira#get_definition()
    return g:skk7#table#rom_to_hira#definition
endfunc


call skk7#table#define_macro()

Skk7Table rom_to_hira

call skk7#table#map("a", "あ")
call skk7#table#map("bb", "っ", 0, "b")
call skk7#table#map("ba", "ば")
call skk7#table#map("be", "べ")
call skk7#table#map("bi", "び")
call skk7#table#map("bo", "ぼ")
call skk7#table#map("bu", "ぶ")
call skk7#table#map("bya", "びゃ")
call skk7#table#map("bye", "びぇ")
call skk7#table#map("byi", "びぃ")
call skk7#table#map("byo", "びょ")
call skk7#table#map("byu", "びゅ")
call skk7#table#map("cc", "っ", 0, "c")
call skk7#table#map("cha", "ちゃ")
call skk7#table#map("che", "ちぇ")
call skk7#table#map("chi", "ち")
call skk7#table#map("cho", "ちょ")
call skk7#table#map("chu", "ちゅ")
call skk7#table#map("cya", "ちゃ")
call skk7#table#map("cye", "ちぇ")
call skk7#table#map("cyi", "ちぃ")
call skk7#table#map("cyo", "ちょ")
call skk7#table#map("cyu", "ちゅ")
call skk7#table#map("dd", "っ", 0, "d")
call skk7#table#map("da", "だ")
call skk7#table#map("de", "で")
call skk7#table#map("dha", "でゃ")
call skk7#table#map("dhe", "でぇ")
call skk7#table#map("dhi", "でぃ")
call skk7#table#map("dho", "でょ")
call skk7#table#map("dhu", "でゅ")
call skk7#table#map("di", "ぢ")
call skk7#table#map("do", "ど")
call skk7#table#map("du", "づ")
call skk7#table#map("dya", "ぢゃ")
call skk7#table#map("dye", "ぢぇ")
call skk7#table#map("dyi", "ぢぃ")
call skk7#table#map("dyo", "ぢょ")
call skk7#table#map("dyu", "ぢゅ")
call skk7#table#map("e", "え")
call skk7#table#map("ff", "っ", 0, "f")
call skk7#table#map("fa", "ふぁ")
call skk7#table#map("fe", "ふぇ")
call skk7#table#map("fi", "ふぃ")
call skk7#table#map("fo", "ふぉ")
call skk7#table#map("fu", "ふ")
call skk7#table#map("fya", "ふゃ")
call skk7#table#map("fye", "ふぇ")
call skk7#table#map("fyi", "ふぃ")
call skk7#table#map("fyo", "ふょ")
call skk7#table#map("fyu", "ふゅ")
call skk7#table#map("gg", "っ", 0, "g")
call skk7#table#map("ga", "が")
call skk7#table#map("ge", "げ")
call skk7#table#map("gi", "ぎ")
call skk7#table#map("go", "ご")
call skk7#table#map("gu", "ぐ")
call skk7#table#map("gya", "ぎゃ")
call skk7#table#map("gye", "ぎぇ")
call skk7#table#map("gyi", "ぎぃ")
call skk7#table#map("gyo", "ぎょ")
call skk7#table#map("gyu", "ぎゅ")
call skk7#table#map("ha", "は")
call skk7#table#map("he", "へ")
call skk7#table#map("hi", "ひ")
call skk7#table#map("ho", "ほ")
call skk7#table#map("hu", "ふ")
call skk7#table#map("hya", "ひゃ")
call skk7#table#map("hye", "ひぇ")
call skk7#table#map("hyi", "ひぃ")
call skk7#table#map("hyo", "ひょ")
call skk7#table#map("hyu", "ひゅ")
call skk7#table#map("i", "い")
call skk7#table#map("jj", "っ", 0, "j")
call skk7#table#map("ja", "じゃ")
call skk7#table#map("je", "じぇ")
call skk7#table#map("ji", "じ")
call skk7#table#map("jo", "じょ")
call skk7#table#map("ju", "じゅ")
call skk7#table#map("jya", "じゃ")
call skk7#table#map("jye", "じぇ")
call skk7#table#map("jyi", "じぃ")
call skk7#table#map("jyo", "じょ")
call skk7#table#map("jyu", "じゅ")
call skk7#table#map("kk", "っ", 0, "k")
call skk7#table#map("ka", "か")
call skk7#table#map("ke", "け")
call skk7#table#map("ki", "き")
call skk7#table#map("ko", "こ")
call skk7#table#map("ku", "く")
call skk7#table#map("kya", "きゃ")
call skk7#table#map("kye", "きぇ")
call skk7#table#map("kyi", "きぃ")
call skk7#table#map("kyo", "きょ")
call skk7#table#map("kyu", "きゅ")
call skk7#table#map("ma", "ま")
call skk7#table#map("me", "め")
call skk7#table#map("mi", "み")
call skk7#table#map("mo", "も")
call skk7#table#map("mu", "む")
call skk7#table#map("mya", "みゃ")
call skk7#table#map("mye", "みぇ")
call skk7#table#map("myi", "みぃ")
call skk7#table#map("myo", "みょ")
call skk7#table#map("myu", "みゅ")
call skk7#table#map("n", "ん")
call skk7#table#map("n'", "ん")
call skk7#table#map("na", "な")
call skk7#table#map("ne", "ね")
call skk7#table#map("ni", "に")
call skk7#table#map("nn", "ん")
call skk7#table#map("no", "の")
call skk7#table#map("nu", "ぬ")
call skk7#table#map("nya", "にゃ")
call skk7#table#map("nye", "にぇ")
call skk7#table#map("nyi", "にぃ")
call skk7#table#map("nyo", "にょ")
call skk7#table#map("nyu", "にゅ")
call skk7#table#map("o", "お")
call skk7#table#map("pp", "っ", 0, "p")
call skk7#table#map("pa", "ぱ")
call skk7#table#map("pe", "ぺ")
call skk7#table#map("pi", "ぴ")
call skk7#table#map("po", "ぽ")
call skk7#table#map("pu", "ぷ")
call skk7#table#map("pya", "ぴゃ")
call skk7#table#map("pye", "ぴぇ")
call skk7#table#map("pyi", "ぴぃ")
call skk7#table#map("pyo", "ぴょ")
call skk7#table#map("pyu", "ぴゅ")
call skk7#table#map("rr", "っ", 0, "r")
call skk7#table#map("ra", "ら")
call skk7#table#map("re", "れ")
call skk7#table#map("ri", "り")
call skk7#table#map("ro", "ろ")
call skk7#table#map("ru", "る")
call skk7#table#map("rya", "りゃ")
call skk7#table#map("rye", "りぇ")
call skk7#table#map("ryi", "りぃ")
call skk7#table#map("ryo", "りょ")
call skk7#table#map("ryu", "りゅ")
call skk7#table#map("ss", "っ", 0, "s")
call skk7#table#map("sa", "さ")
call skk7#table#map("se", "せ")
call skk7#table#map("sha", "しゃ")
call skk7#table#map("she", "しぇ")
call skk7#table#map("shi", "し")
call skk7#table#map("sho", "しょ")
call skk7#table#map("shu", "しゅ")
call skk7#table#map("si", "し")
call skk7#table#map("so", "そ")
call skk7#table#map("su", "す")
call skk7#table#map("sya", "しゃ")
call skk7#table#map("sye", "しぇ")
call skk7#table#map("syi", "しぃ")
call skk7#table#map("syo", "しょ")
call skk7#table#map("syu", "しゅ")
call skk7#table#map("tt", "っ", 0, "t")
call skk7#table#map("ta", "た")
call skk7#table#map("te", "て")
call skk7#table#map("tha", "てぁ")
call skk7#table#map("the", "てぇ")
call skk7#table#map("thi", "てぃ")
call skk7#table#map("tho", "てょ")
call skk7#table#map("thu", "てゅ")
call skk7#table#map("ti", "ち")
call skk7#table#map("to", "と")
call skk7#table#map("tsu", "つ")
call skk7#table#map("tu", "つ")
call skk7#table#map("tya", "ちゃ")
call skk7#table#map("tye", "ちぇ")
call skk7#table#map("tyi", "ちぃ")
call skk7#table#map("tyo", "ちょ")
call skk7#table#map("tyu", "ちゅ")
call skk7#table#map("u", "う")
call skk7#table#map("vv", "っ", 0, "v")
call skk7#table#map("va", "う゛ぁ")
call skk7#table#map("ve", "う゛ぇ")
call skk7#table#map("vi", "う゛ぃ")
call skk7#table#map("vo", "う゛ぉ")
call skk7#table#map("vu", "う゛")
call skk7#table#map("ww", "っ", 0, "w")
call skk7#table#map("wa", "わ")
call skk7#table#map("we", "うぇ")
call skk7#table#map("wi", "うぃ")
call skk7#table#map("wo", "を")
call skk7#table#map("wu", "う")
call skk7#table#map("xx", "っ", 0, "x")
call skk7#table#map("xa", "ぁ")
call skk7#table#map("xe", "ぇ")
call skk7#table#map("xi", "ぃ")
call skk7#table#map("xka", "か")
call skk7#table#map("xke", "け")
call skk7#table#map("xo", "ぉ")
call skk7#table#map("xtsu", "っ")
call skk7#table#map("xtu", "っ")
call skk7#table#map("xu", "ぅ")
call skk7#table#map("xwa", "ゎ")
call skk7#table#map("xwe", "ゑ")
call skk7#table#map("xwi", "ゐ")
call skk7#table#map("xya", "ゃ")
call skk7#table#map("xyo", "ょ")
call skk7#table#map("xyu", "ゅ")
call skk7#table#map("yy", "っ", 0, "y")
call skk7#table#map("ya", "や")
call skk7#table#map("ye", "いぇ")
call skk7#table#map("yo", "よ")
call skk7#table#map("yu", "ゆ")
call skk7#table#map("zz", "っ", 0, "z")
call skk7#table#map("z,", "‥")
call skk7#table#map("z-", "～")
call skk7#table#map("z.", "…")
call skk7#table#map("z/", "・")
call skk7#table#map("z[", "『")
call skk7#table#map("z]", "』")
call skk7#table#map("za", "ざ")
call skk7#table#map("ze", "ぜ")
call skk7#table#map("zh", "←")
call skk7#table#map("zi", "じ")
call skk7#table#map("zj", "↓")
call skk7#table#map("zk", "↑")
call skk7#table#map("zl", "→")
call skk7#table#map("zo", "ぞ")
call skk7#table#map("zu", "ず")
call skk7#table#map("zya", "じゃ")
call skk7#table#map("zye", "じぇ")
call skk7#table#map("zyi", "じぃ")
call skk7#table#map("zyo", "じょ")
call skk7#table#map("zyu", "じゅ")
call skk7#table#map("-", "ー")
call skk7#table#map(":", "：")
call skk7#table#map(";", "；")
call skk7#table#map("!", "！")
call skk7#table#map("?", "？")
call skk7#table#map("[", "「")
call skk7#table#map("]", "」")



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
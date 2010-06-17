" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Load once {{{
if exists('s:loaded')
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}
runtime! plugin/eskk.vim


function! eskk#table#rom_to_hira#load()
    " dummy
endfunction



call eskk#table#define_macro()
TableBegin hira_to_kata

Map あ ア
Map っ ッ
Map ば バ
Map べ ベ
Map び ビ
Map ぼ ボ
Map ぶ ブ
Map ち チ
Map だ ダ
Map で デ
Map ぢ ヂ
Map ど ド
Map づ ヅ
Map え エ
Map ふ フ
Map が ガ
Map げ ゲ
Map ぎ ギ
Map ご ゴ
Map ぐ グ
Map は ハ
Map へ ヘ
Map ひ ヒ
Map ほ ホ
Map ふ フ
Map い イ
Map じ ジ
Map か カ
Map け ケ
Map き キ
Map こ コ
Map く ク
Map ま マ
Map め メ
Map み ミ
Map も モ
Map む ム
Map ん ン
Map な ナ
Map ね ネ
Map に ニ
Map ん ン
Map の ノ
Map ぬ ヌ
Map お オ
Map ぱ パ
Map ぺ ペ
Map ぴ ピ
Map ぽ ポ
Map ぷ プ
Map ら ラ
Map れ レ
Map り リ
Map ろ ロ
Map る ル
Map さ サ
Map せ セ
Map し シ
Map そ ソ
Map す ス
Map た タ
Map て テ
Map ち チ
Map と ト
Map つ ツ
Map う ウ
Map う゛ ヴ
Map わ ワ
Map を ヲ
Map う ウ
Map ぁ ァ
Map ぇ ェ
Map ぃ ィ
Map ぉ ォ
Map っ ッ
Map ぅ ゥ
Map ゎ ヮ
Map ゑ ヱ
Map ゐ ヰ
Map ゃ ャ
Map ょ ョ
Map ゅ ュ
Map や ヤ
Map よ ヨ
Map ゆ ユ
Map ざ ザ
Map ぜ ゼ
Map じ ジ
Map ぞ ゾ
Map ず ズ

TableEnd
call eskk#table#undefine_macro()


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

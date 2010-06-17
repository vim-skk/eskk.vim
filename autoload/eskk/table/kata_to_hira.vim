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
TableBegin kata_to_hira

Map ア あ
Map ッ っ
Map バ ば
Map ベ べ
Map ビ び
Map ボ ぼ
Map ブ ぶ
Map チ ち
Map ダ だ
Map デ で
Map ヂ ぢ
Map ド ど
Map ヅ づ
Map エ え
Map フ ふ
Map ガ が
Map ゲ げ
Map ギ ぎ
Map ゴ ご
Map グ ぐ
Map ハ は
Map ヘ へ
Map ヒ ひ
Map ホ ほ
Map フ ふ
Map イ い
Map ジ じ
Map カ か
Map ケ け
Map キ き
Map コ こ
Map ク く
Map マ ま
Map メ め
Map ミ み
Map モ も
Map ム む
Map ン ん
Map ナ な
Map ネ ね
Map ニ に
Map ン ん
Map ノ の
Map ヌ ぬ
Map オ お
Map パ ぱ
Map ペ ぺ
Map ピ ぴ
Map ポ ぽ
Map プ ぷ
Map ラ ら
Map レ れ
Map リ り
Map ロ ろ
Map ル る
Map サ さ
Map セ せ
Map シ し
Map ソ そ
Map ス す
Map タ た
Map テ て
Map チ ち
Map ト と
Map ツ つ
Map ウ う
Map ヴ う゛
Map ワ わ
Map ヲ を
Map ウ う
Map ァ ぁ
Map ェ ぇ
Map ィ ぃ
Map ォ ぉ
Map ッ っ
Map ゥ ぅ
Map ヮ ゎ
Map ヱ ゑ
Map ヰ ゐ
Map ャ ゃ
Map ョ ょ
Map ュ ゅ
Map ヤ や
Map ヨ よ
Map ユ ゆ
Map ザ ざ
Map ゼ ぜ
Map ジ じ
Map ゾ ぞ
Map ズ ず

TableEnd
call eskk#table#undefine_macro()


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

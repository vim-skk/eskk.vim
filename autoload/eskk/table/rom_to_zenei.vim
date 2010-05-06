" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! eskk#table#rom_to_zenei#load()
    " dummy
endfunction



call eskk#table#define_macro()
TableBegin rom_to_zenei

Map <Space> 　
Map ! ！
Map " ”
Map # ＃
Map $ ＄
Map % ％
Map & ＆
Map ' ’
Map ( （
Map ) ）
Map * ＊
Map + ＋
Map , ，
Map - ー
Map . ．
Map / ／
Map 0 ０
Map 1 １
Map 2 ２
Map 3 ３
Map 4 ４
Map 5 ５
Map 6 ６
Map 7 ７
Map 8 ８
Map 9 ９
Map : ：
Map ; ；
Map < ＜
Map = ＝
Map > ＞
Map ? ？
Map @ ＠
Map A Ａ
Map B Ｂ
Map C Ｃ
Map D Ｄ
Map E Ｅ
Map F Ｆ
Map G Ｇ
Map H Ｈ
Map I Ｉ
Map J Ｊ
Map K Ｋ
Map L Ｌ
Map M Ｍ
Map N Ｎ
Map O Ｏ
Map P Ｐ
Map Q Ｑ
Map R Ｒ
Map S Ｓ
Map T Ｔ
Map U Ｕ
Map V Ｖ
Map W Ｗ
Map X Ｘ
Map Y Ｙ
Map Z Ｚ
Map [ ［
Map \ \
Map ] ］
Map ^ ＾
Map _ ＿
Map ` ‘
Map a ａ
Map b ｂ
Map c ｃ
Map d ｄ
Map e ｅ
Map f ｆ
Map g ｇ
Map h ｈ
Map i ｉ
Map j ｊ
Map k ｋ
Map l ｌ
Map m ｍ
Map n ｎ
Map o ｏ
Map p ｐ
Map q ｑ
Map r ｒ
Map s ｓ
Map t ｔ
Map u ｕ
Map v ｖ
Map w ｗ
Map x ｘ
Map y ｙ
Map z ｚ
Map { ｛
Map | ｜
Map } ｝
Map ~ ～

TableEnd
call eskk#table#undefine_macro()


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}


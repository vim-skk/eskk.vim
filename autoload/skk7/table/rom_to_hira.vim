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

Skk7TableMap a あ
Skk7TableMap -rest=b bb っ
Skk7TableMap ba ば
Skk7TableMap be べ
Skk7TableMap bi び
Skk7TableMap bo ぼ
Skk7TableMap bu ぶ
Skk7TableMap bya びゃ
Skk7TableMap bye びぇ
Skk7TableMap byi びぃ
Skk7TableMap byo びょ
Skk7TableMap byu びゅ
Skk7TableMap -rest=c cc っ
Skk7TableMap cha ちゃ
Skk7TableMap che ちぇ
Skk7TableMap chi ち
Skk7TableMap cho ちょ
Skk7TableMap chu ちゅ
Skk7TableMap cya ちゃ
Skk7TableMap cye ちぇ
Skk7TableMap cyi ちぃ
Skk7TableMap cyo ちょ
Skk7TableMap cyu ちゅ
Skk7TableMap -rest=d dd っ
Skk7TableMap da だ
Skk7TableMap de で
Skk7TableMap dha でゃ
Skk7TableMap dhe でぇ
Skk7TableMap dhi でぃ
Skk7TableMap dho でょ
Skk7TableMap dhu でゅ
Skk7TableMap di ぢ
Skk7TableMap do ど
Skk7TableMap du づ
Skk7TableMap dya ぢゃ
Skk7TableMap dye ぢぇ
Skk7TableMap dyi ぢぃ
Skk7TableMap dyo ぢょ
Skk7TableMap dyu ぢゅ
Skk7TableMap e え
Skk7TableMap -rest=f ff っ
Skk7TableMap fa ふぁ
Skk7TableMap fe ふぇ
Skk7TableMap fi ふぃ
Skk7TableMap fo ふぉ
Skk7TableMap fu ふ
Skk7TableMap fya ふゃ
Skk7TableMap fye ふぇ
Skk7TableMap fyi ふぃ
Skk7TableMap fyo ふょ
Skk7TableMap fyu ふゅ
Skk7TableMap -rest=g gg っ
Skk7TableMap ga が
Skk7TableMap ge げ
Skk7TableMap gi ぎ
Skk7TableMap go ご
Skk7TableMap gu ぐ
Skk7TableMap gya ぎゃ
Skk7TableMap gye ぎぇ
Skk7TableMap gyi ぎぃ
Skk7TableMap gyo ぎょ
Skk7TableMap gyu ぎゅ
Skk7TableMap ha は
Skk7TableMap he へ
Skk7TableMap hi ひ
Skk7TableMap ho ほ
Skk7TableMap hu ふ
Skk7TableMap hya ひゃ
Skk7TableMap hye ひぇ
Skk7TableMap hyi ひぃ
Skk7TableMap hyo ひょ
Skk7TableMap hyu ひゅ
Skk7TableMap i い
Skk7TableMap -rest=j jj っ
Skk7TableMap ja じゃ
Skk7TableMap je じぇ
Skk7TableMap ji じ
Skk7TableMap jo じょ
Skk7TableMap ju じゅ
Skk7TableMap jya じゃ
Skk7TableMap jye じぇ
Skk7TableMap jyi じぃ
Skk7TableMap jyo じょ
Skk7TableMap jyu じゅ
Skk7TableMap -rest=k kk っ
Skk7TableMap ka か
Skk7TableMap ke け
Skk7TableMap ki き
Skk7TableMap ko こ
Skk7TableMap ku く
Skk7TableMap kya きゃ
Skk7TableMap kye きぇ
Skk7TableMap kyi きぃ
Skk7TableMap kyo きょ
Skk7TableMap kyu きゅ
Skk7TableMap ma ま
Skk7TableMap me め
Skk7TableMap mi み
Skk7TableMap mo も
Skk7TableMap mu む
Skk7TableMap mya みゃ
Skk7TableMap mye みぇ
Skk7TableMap myi みぃ
Skk7TableMap myo みょ
Skk7TableMap myu みゅ
Skk7TableMap n ん
Skk7TableMap n' ん
Skk7TableMap na な
Skk7TableMap ne ね
Skk7TableMap ni に
Skk7TableMap nn ん
Skk7TableMap no の
Skk7TableMap nu ぬ
Skk7TableMap nya にゃ
Skk7TableMap nye にぇ
Skk7TableMap nyi にぃ
Skk7TableMap nyo にょ
Skk7TableMap nyu にゅ
Skk7TableMap o お
Skk7TableMap -rest=p pp っ
Skk7TableMap pa ぱ
Skk7TableMap pe ぺ
Skk7TableMap pi ぴ
Skk7TableMap po ぽ
Skk7TableMap pu ぷ
Skk7TableMap pya ぴゃ
Skk7TableMap pye ぴぇ
Skk7TableMap pyi ぴぃ
Skk7TableMap pyo ぴょ
Skk7TableMap pyu ぴゅ
Skk7TableMap -rest=r rr っ
Skk7TableMap ra ら
Skk7TableMap re れ
Skk7TableMap ri り
Skk7TableMap ro ろ
Skk7TableMap ru る
Skk7TableMap rya りゃ
Skk7TableMap rye りぇ
Skk7TableMap ryi りぃ
Skk7TableMap ryo りょ
Skk7TableMap ryu りゅ
Skk7TableMap -rest=s ss っ
Skk7TableMap sa さ
Skk7TableMap se せ
Skk7TableMap sha しゃ
Skk7TableMap she しぇ
Skk7TableMap shi し
Skk7TableMap sho しょ
Skk7TableMap shu しゅ
Skk7TableMap si し
Skk7TableMap so そ
Skk7TableMap su す
Skk7TableMap sya しゃ
Skk7TableMap sye しぇ
Skk7TableMap syi しぃ
Skk7TableMap syo しょ
Skk7TableMap syu しゅ
Skk7TableMap -rest=t tt っ
Skk7TableMap ta た
Skk7TableMap te て
Skk7TableMap tha てぁ
Skk7TableMap the てぇ
Skk7TableMap thi てぃ
Skk7TableMap tho てょ
Skk7TableMap thu てゅ
Skk7TableMap ti ち
Skk7TableMap to と
Skk7TableMap tsu つ
Skk7TableMap tu つ
Skk7TableMap tya ちゃ
Skk7TableMap tye ちぇ
Skk7TableMap tyi ちぃ
Skk7TableMap tyo ちょ
Skk7TableMap tyu ちゅ
Skk7TableMap u う
Skk7TableMap -rest=v vv っ
Skk7TableMap va う゛ぁ
Skk7TableMap ve う゛ぇ
Skk7TableMap vi う゛ぃ
Skk7TableMap vo う゛ぉ
Skk7TableMap vu う゛
Skk7TableMap -rest=w ww っ
Skk7TableMap wa わ
Skk7TableMap we うぇ
Skk7TableMap wi うぃ
Skk7TableMap wo を
Skk7TableMap wu う
Skk7TableMap -rest=x xx っ
Skk7TableMap xa ぁ
Skk7TableMap xe ぇ
Skk7TableMap xi ぃ
Skk7TableMap xka か
Skk7TableMap xke け
Skk7TableMap xo ぉ
Skk7TableMap xtsu っ
Skk7TableMap xtu っ
Skk7TableMap xu ぅ
Skk7TableMap xwa ゎ
Skk7TableMap xwe ゑ
Skk7TableMap xwi ゐ
Skk7TableMap xya ゃ
Skk7TableMap xyo ょ
Skk7TableMap xyu ゅ
Skk7TableMap -rest=y yy っ
Skk7TableMap ya や
Skk7TableMap ye いぇ
Skk7TableMap yo よ
Skk7TableMap yu ゆ
Skk7TableMap -rest=z zz っ
Skk7TableMap z, ‥
Skk7TableMap z- ～
Skk7TableMap z. …
Skk7TableMap z/ ・
Skk7TableMap z[ 『
Skk7TableMap z] 』
Skk7TableMap za ざ
Skk7TableMap ze ぜ
Skk7TableMap zh ←
Skk7TableMap zi じ
Skk7TableMap zj ↓
Skk7TableMap zk ↑
Skk7TableMap zl →
Skk7TableMap zo ぞ
Skk7TableMap zu ず
Skk7TableMap zya じゃ
Skk7TableMap zye じぇ
Skk7TableMap zyi じぃ
Skk7TableMap zyo じょ
Skk7TableMap zyu じゅ
Skk7TableMap - ー
Skk7TableMap : ：
Skk7TableMap ; ；
Skk7TableMap ! ！
Skk7TableMap ? ？
Skk7TableMap [ 「
Skk7TableMap ] 」



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

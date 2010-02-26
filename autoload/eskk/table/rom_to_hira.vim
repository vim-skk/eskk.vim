" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! eskk#table#rom_to_hira#get_definition()
    return g:eskk#table#rom_to_hira#definition
endfunc


call eskk#table#define_macro()

EskkTable rom_to_hira

EskkTableMap a あ
EskkTableMap -rest=b bb っ
EskkTableMap ba ば
EskkTableMap be べ
EskkTableMap bi び
EskkTableMap bo ぼ
EskkTableMap bu ぶ
EskkTableMap bya びゃ
EskkTableMap bye びぇ
EskkTableMap byi びぃ
EskkTableMap byo びょ
EskkTableMap byu びゅ
EskkTableMap -rest=c cc っ
EskkTableMap cha ちゃ
EskkTableMap che ちぇ
EskkTableMap chi ち
EskkTableMap cho ちょ
EskkTableMap chu ちゅ
EskkTableMap cya ちゃ
EskkTableMap cye ちぇ
EskkTableMap cyi ちぃ
EskkTableMap cyo ちょ
EskkTableMap cyu ちゅ
EskkTableMap -rest=d dd っ
EskkTableMap da だ
EskkTableMap de で
EskkTableMap dha でゃ
EskkTableMap dhe でぇ
EskkTableMap dhi でぃ
EskkTableMap dho でょ
EskkTableMap dhu でゅ
EskkTableMap di ぢ
EskkTableMap do ど
EskkTableMap du づ
EskkTableMap dya ぢゃ
EskkTableMap dye ぢぇ
EskkTableMap dyi ぢぃ
EskkTableMap dyo ぢょ
EskkTableMap dyu ぢゅ
EskkTableMap e え
EskkTableMap -rest=f ff っ
EskkTableMap fa ふぁ
EskkTableMap fe ふぇ
EskkTableMap fi ふぃ
EskkTableMap fo ふぉ
EskkTableMap fu ふ
EskkTableMap fya ふゃ
EskkTableMap fye ふぇ
EskkTableMap fyi ふぃ
EskkTableMap fyo ふょ
EskkTableMap fyu ふゅ
EskkTableMap -rest=g gg っ
EskkTableMap ga が
EskkTableMap ge げ
EskkTableMap gi ぎ
EskkTableMap go ご
EskkTableMap gu ぐ
EskkTableMap gya ぎゃ
EskkTableMap gye ぎぇ
EskkTableMap gyi ぎぃ
EskkTableMap gyo ぎょ
EskkTableMap gyu ぎゅ
EskkTableMap ha は
EskkTableMap he へ
EskkTableMap hi ひ
EskkTableMap ho ほ
EskkTableMap hu ふ
EskkTableMap hya ひゃ
EskkTableMap hye ひぇ
EskkTableMap hyi ひぃ
EskkTableMap hyo ひょ
EskkTableMap hyu ひゅ
EskkTableMap i い
EskkTableMap -rest=j jj っ
EskkTableMap ja じゃ
EskkTableMap je じぇ
EskkTableMap ji じ
EskkTableMap jo じょ
EskkTableMap ju じゅ
EskkTableMap jya じゃ
EskkTableMap jye じぇ
EskkTableMap jyi じぃ
EskkTableMap jyo じょ
EskkTableMap jyu じゅ
EskkTableMap -rest=k kk っ
EskkTableMap ka か
EskkTableMap ke け
EskkTableMap ki き
EskkTableMap ko こ
EskkTableMap ku く
EskkTableMap kya きゃ
EskkTableMap kye きぇ
EskkTableMap kyi きぃ
EskkTableMap kyo きょ
EskkTableMap kyu きゅ
EskkTableMap ma ま
EskkTableMap me め
EskkTableMap mi み
EskkTableMap mo も
EskkTableMap mu む
EskkTableMap mya みゃ
EskkTableMap mye みぇ
EskkTableMap myi みぃ
EskkTableMap myo みょ
EskkTableMap myu みゅ
EskkTableMap n ん
EskkTableMap n' ん
EskkTableMap na な
EskkTableMap ne ね
EskkTableMap ni に
EskkTableMap nn ん
EskkTableMap no の
EskkTableMap nu ぬ
EskkTableMap nya にゃ
EskkTableMap nye にぇ
EskkTableMap nyi にぃ
EskkTableMap nyo にょ
EskkTableMap nyu にゅ
EskkTableMap o お
EskkTableMap -rest=p pp っ
EskkTableMap pa ぱ
EskkTableMap pe ぺ
EskkTableMap pi ぴ
EskkTableMap po ぽ
EskkTableMap pu ぷ
EskkTableMap pya ぴゃ
EskkTableMap pye ぴぇ
EskkTableMap pyi ぴぃ
EskkTableMap pyo ぴょ
EskkTableMap pyu ぴゅ
EskkTableMap -rest=r rr っ
EskkTableMap ra ら
EskkTableMap re れ
EskkTableMap ri り
EskkTableMap ro ろ
EskkTableMap ru る
EskkTableMap rya りゃ
EskkTableMap rye りぇ
EskkTableMap ryi りぃ
EskkTableMap ryo りょ
EskkTableMap ryu りゅ
EskkTableMap -rest=s ss っ
EskkTableMap sa さ
EskkTableMap se せ
EskkTableMap sha しゃ
EskkTableMap she しぇ
EskkTableMap shi し
EskkTableMap sho しょ
EskkTableMap shu しゅ
EskkTableMap si し
EskkTableMap so そ
EskkTableMap su す
EskkTableMap sya しゃ
EskkTableMap sye しぇ
EskkTableMap syi しぃ
EskkTableMap syo しょ
EskkTableMap syu しゅ
EskkTableMap -rest=t tt っ
EskkTableMap ta た
EskkTableMap te て
EskkTableMap tha てぁ
EskkTableMap the てぇ
EskkTableMap thi てぃ
EskkTableMap tho てょ
EskkTableMap thu てゅ
EskkTableMap ti ち
EskkTableMap to と
EskkTableMap tsu つ
EskkTableMap tu つ
EskkTableMap tya ちゃ
EskkTableMap tye ちぇ
EskkTableMap tyi ちぃ
EskkTableMap tyo ちょ
EskkTableMap tyu ちゅ
EskkTableMap u う
EskkTableMap -rest=v vv っ
EskkTableMap va う゛ぁ
EskkTableMap ve う゛ぇ
EskkTableMap vi う゛ぃ
EskkTableMap vo う゛ぉ
EskkTableMap vu う゛
EskkTableMap -rest=w ww っ
EskkTableMap wa わ
EskkTableMap we うぇ
EskkTableMap wi うぃ
EskkTableMap wo を
EskkTableMap wu う
EskkTableMap -rest=x xx っ
EskkTableMap xa ぁ
EskkTableMap xe ぇ
EskkTableMap xi ぃ
EskkTableMap xka か
EskkTableMap xke け
EskkTableMap xo ぉ
EskkTableMap xtsu っ
EskkTableMap xtu っ
EskkTableMap xu ぅ
EskkTableMap xwa ゎ
EskkTableMap xwe ゑ
EskkTableMap xwi ゐ
EskkTableMap xya ゃ
EskkTableMap xyo ょ
EskkTableMap xyu ゅ
EskkTableMap -rest=y yy っ
EskkTableMap ya や
EskkTableMap ye いぇ
EskkTableMap yo よ
EskkTableMap yu ゆ
EskkTableMap -rest=z zz っ
EskkTableMap z, ‥
EskkTableMap z- ～
EskkTableMap z. …
EskkTableMap z/ ・
EskkTableMap z[ 『
EskkTableMap z] 』
EskkTableMap za ざ
EskkTableMap ze ぜ
EskkTableMap zh ←
EskkTableMap zi じ
EskkTableMap zj ↓
EskkTableMap zk ↑
EskkTableMap zl →
EskkTableMap zo ぞ
EskkTableMap zu ず
EskkTableMap zya じゃ
EskkTableMap zye じぇ
EskkTableMap zyi じぃ
EskkTableMap zyo じょ
EskkTableMap zyu じゅ
EskkTableMap - ー
EskkTableMap : ：
EskkTableMap ; ；
EskkTableMap ! ！
EskkTableMap ? ？
EskkTableMap [ 「
EskkTableMap ] 」



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

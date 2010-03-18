" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


call eskk#table#define_macro()

TableBegin rom_to_hira

Map a あ
Map -rest=b bb っ
Map ba ば
Map be べ
Map bi び
Map bo ぼ
Map bu ぶ
Map bya びゃ
Map bye びぇ
Map byi びぃ
Map byo びょ
Map byu びゅ
Map -rest=c cc っ
Map cha ちゃ
Map che ちぇ
Map chi ち
Map cho ちょ
Map chu ちゅ
Map cya ちゃ
Map cye ちぇ
Map cyi ちぃ
Map cyo ちょ
Map cyu ちゅ
Map -rest=d dd っ
Map da だ
Map de で
Map dha でゃ
Map dhe でぇ
Map dhi でぃ
Map dho でょ
Map dhu でゅ
Map di ぢ
Map do ど
Map du づ
Map dya ぢゃ
Map dye ぢぇ
Map dyi ぢぃ
Map dyo ぢょ
Map dyu ぢゅ
Map e え
Map -rest=f ff っ
Map fa ふぁ
Map fe ふぇ
Map fi ふぃ
Map fo ふぉ
Map fu ふ
Map fya ふゃ
Map fye ふぇ
Map fyi ふぃ
Map fyo ふょ
Map fyu ふゅ
Map -rest=g gg っ
Map ga が
Map ge げ
Map gi ぎ
Map go ご
Map gu ぐ
Map gya ぎゃ
Map gye ぎぇ
Map gyi ぎぃ
Map gyo ぎょ
Map gyu ぎゅ
Map -rest=h hh っ
Map ha は
Map he へ
Map hi ひ
Map ho ほ
Map hu ふ
Map hya ひゃ
Map hye ひぇ
Map hyi ひぃ
Map hyo ひょ
Map hyu ひゅ
Map i い
Map -rest=j jj っ
Map ja じゃ
Map je じぇ
Map ji じ
Map jo じょ
Map ju じゅ
Map jya じゃ
Map jye じぇ
Map jyi じぃ
Map jyo じょ
Map jyu じゅ
Map -rest=k kk っ
Map ka か
Map ke け
Map ki き
Map ko こ
Map ku く
Map kya きゃ
Map kye きぇ
Map kyi きぃ
Map kyo きょ
Map kyu きゅ
Map -rest=m mm っ
Map ma ま
Map me め
Map mi み
Map mo も
Map mu む
Map mya みゃ
Map mye みぇ
Map myi みぃ
Map myo みょ
Map myu みゅ
Map n' ん
Map na な
Map ne ね
Map ni に
Map nn ん
Map no の
Map nu ぬ
Map nya にゃ
Map nye にぇ
Map nyi にぃ
Map nyo にょ
Map nyu にゅ
Map o お
Map -rest=p pp っ
Map pa ぱ
Map pe ぺ
Map pi ぴ
Map po ぽ
Map pu ぷ
Map pya ぴゃ
Map pye ぴぇ
Map pyi ぴぃ
Map pyo ぴょ
Map pyu ぴゅ
Map -rest=r rr っ
Map ra ら
Map re れ
Map ri り
Map ro ろ
Map ru る
Map rya りゃ
Map rye りぇ
Map ryi りぃ
Map ryo りょ
Map ryu りゅ
Map -rest=s ss っ
Map sa さ
Map se せ
Map sha しゃ
Map she しぇ
Map shi し
Map sho しょ
Map shu しゅ
Map si し
Map so そ
Map su す
Map sya しゃ
Map sye しぇ
Map syi しぃ
Map syo しょ
Map syu しゅ
Map -rest=t tt っ
Map ta た
Map te て
Map tha てぁ
Map the てぇ
Map thi てぃ
Map tho てょ
Map thu てゅ
Map ti ち
Map to と
Map tsu つ
Map tu つ
Map tya ちゃ
Map tye ちぇ
Map tyi ちぃ
Map tyo ちょ
Map tyu ちゅ
Map u う
Map -rest=v vv っ
Map va う゛ぁ
Map ve う゛ぇ
Map vi う゛ぃ
Map vo う゛ぉ
Map vu う゛
Map -rest=w ww っ
Map wa わ
Map we うぇ
Map wi うぃ
Map wo を
Map wu う
Map -rest=x xx っ
Map xa ぁ
Map xe ぇ
Map xi ぃ
Map xka か
Map xke け
Map xo ぉ
Map xtsu っ
Map xtu っ
Map xu ぅ
Map xwa ゎ
Map xwe ゑ
Map xwi ゐ
Map xya ゃ
Map xyo ょ
Map xyu ゅ
Map -rest=y yy っ
Map ya や
Map ye いぇ
Map yo よ
Map yu ゆ
Map -rest=z zz っ
Map z, ‥
Map z- ～
Map z. …
Map z/ ・
Map z[ 『
Map z] 』
Map za ざ
Map ze ぜ
Map zh ←
Map zi じ
Map zj ↓
Map zk ↑
Map zl →
Map zo ぞ
Map zu ず
Map zya じゃ
Map zye じぇ
Map zyi じぃ
Map zyo じょ
Map zyu じゅ
Map - ー
Map : ：
Map ; ；
Map ! ！
Map ? ？
Map [ 「
Map ] 」
Map . 。
Map , 、

TableEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

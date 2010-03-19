" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


call eskk#table#define_macro()
TableBegin rom_to_kata

Map a ア
Map -rest=b bb ッ
Map ba バ
Map be ベ
Map bi ビ
Map bo ボ
Map bu ブ
Map bya ビャ
Map bye ビェ
Map byi ビィ
Map byo ビョ
Map byu ビュ
Map -rest=c cc ッ
Map cha チャ
Map che チェ
Map chi チ
Map cho チョ
Map chu チュ
Map cya チャ
Map cye チェ
Map cyi チィ
Map cyo チョ
Map cyu チュ
Map -rest=d dd ッ
Map da ダ
Map de デ
Map dha デャ
Map dhe デェ
Map dhi ディ
Map dho デョ
Map dhu デュ
Map di ヂ
Map do ド
Map du ヅ
Map dya ヂャ
Map dye ヂェ
Map dyi ヂィ
Map dyo ヂョ
Map dyu ヂュ
Map e エ
Map -rest=f ff ッ
Map fa ファ
Map fe フェ
Map fi フィ
Map fo フォ
Map fu フ
Map fya フャ
Map fye フェ
Map fyi フィ
Map fyo フョ
Map fyu フュ
Map -rest=g gg ッ
Map ga ガ
Map ge ゲ
Map gi ギ
Map go ゴ
Map gu グ
Map gya ギャ
Map gye ギェ
Map gyi ギィ
Map gyo ギョ
Map gyu ギュ
Map -rest=h hh ッ
Map ha ハ
Map he ヘ
Map hi ヒ
Map ho ホ
Map hu フ
Map hya ヒャ
Map hye ヒェ
Map hyi ヒィ
Map hyo ヒョ
Map hyu ヒュ
Map i イ
Map -rest=j jj ッ
Map ja ジャ
Map je ジェ
Map ji ジ
Map jo ジョ
Map ju ジュ
Map jya ジャ
Map jye ジェ
Map jyi ジィ
Map jyo ジョ
Map jyu ジュ
Map -rest=k kk ッ
Map ka カ
Map ke ケ
Map ki キ
Map ko コ
Map ku ク
Map kya キャ
Map kye キェ
Map kyi キィ
Map kyo キョ
Map kyu キュ
Map -rest=m mm ッ
Map ma マ
Map me メ
Map mi ミ
Map mo モ
Map mu ム
Map mya ミャ
Map mye ミェ
Map myi ミィ
Map myo ミョ
Map myu ミュ
Map n ン
Map n' ン
Map na ナ
Map ne ネ
Map ni ニ
Map nn ン
Map no ノ
Map nu ヌ
Map nya ニャ
Map nye ニェ
Map nyi ニィ
Map nyo ニョ
Map nyu ニュ
Map o オ
Map -rest=p pp ッ
Map pa パ
Map pe ペ
Map pi ピ
Map po ポ
Map pu プ
Map pya ピャ
Map pye ピェ
Map pyi ピィ
Map pyo ピョ
Map pyu ピュ
Map -rest=r rr ッ
Map ra ラ
Map re レ
Map ri リ
Map ro ロ
Map ru ル
Map rya リャ
Map rye リェ
Map ryi リィ
Map ryo リョ
Map ryu リュ
Map -rest=s ss ッ
Map sa サ
Map se セ
Map sha シャ
Map she シェ
Map shi シ
Map sho ショ
Map shu シュ
Map si シ
Map so ソ
Map su ス
Map sya シャ
Map sye シェ
Map syi シィ
Map syo ショ
Map syu シュ
Map -rest=t tt ッ
Map ta タ
Map te テ
Map tha テァ
Map the テェ
Map thi ティ
Map tho テョ
Map thu テュ
Map ti チ
Map to ト
Map tsu ツ
Map tu ツ
Map tya チャ
Map tye チェ
Map tyi チィ
Map tyo チョ
Map tyu チュ
Map u ウ
Map -rest=v vv ッ
Map va ヴァ
Map ve ヴェ
Map vi ヴィ
Map vo ヴォ
Map vu ヴ
Map -rest=w ww ッ
Map wa ワ
Map we ウェ
Map wi ウィ
Map wo ヲ
Map wu ウ
Map -rest=x xx ッ
Map xa ァ
Map xe ェ
Map xi ィ
Map xka ヵ
Map xke ヶ
Map xo ォ
Map xtsu ッ
Map xtu ッ
Map xu ゥ
Map xwa ヮ
Map xwe ヱ
Map xwi ヰ
Map xya ャ
Map xyo ョ
Map xyu ュ
Map -rest=y yy ッ
Map ya ヤ
Map ye イェ
Map yo ヨ
Map yu ユ
Map -rest=z zz ッ
Map z, ‥
Map z- ～
Map z. …
Map z/ ・
Map z[ 『
Map z] 』
Map za ザ
Map ze ゼ
Map zh ←
Map zi ジ
Map zj ↓
Map zk ↑
Map zl →
Map zo ゾ
Map zu ズ
Map zya ジャ
Map zye ジェ
Map zyi ジィ
Map zyo ジョ
Map zyu ジュ
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
call eskk#table#undefine_macro()



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

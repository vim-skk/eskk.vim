" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! eskk#table#rom_to_kata#get_definition()
    return g:eskk#table#rom_to_kata#definition
endfunc


call eskk#table#define_macro()

EskkTable rom_to_kata

EskkTableMap a ア
EskkTableMap -rest=b bb ッ
EskkTableMap ba バ
EskkTableMap be ベ
EskkTableMap bi ビ
EskkTableMap bo ボ
EskkTableMap bu ブ
EskkTableMap bya ビャ
EskkTableMap bye ビェ
EskkTableMap byi ビィ
EskkTableMap byo ビョ
EskkTableMap byu ビュ
EskkTableMap -rest=c cc ッ
EskkTableMap cha チャ
EskkTableMap che チェ
EskkTableMap chi チ
EskkTableMap cho チョ
EskkTableMap chu チュ
EskkTableMap cya チャ
EskkTableMap cye チェ
EskkTableMap cyi チィ
EskkTableMap cyo チョ
EskkTableMap cyu チュ
EskkTableMap -rest=d dd ッ
EskkTableMap da ダ
EskkTableMap de デ
EskkTableMap dha デャ
EskkTableMap dhe デェ
EskkTableMap dhi ディ
EskkTableMap dho デョ
EskkTableMap dhu デュ
EskkTableMap di ヂ
EskkTableMap do ド
EskkTableMap du ヅ
EskkTableMap dya ヂャ
EskkTableMap dye ヂェ
EskkTableMap dyi ヂィ
EskkTableMap dyo ヂョ
EskkTableMap dyu ヂュ
EskkTableMap e エ
EskkTableMap -rest=f ff ッ
EskkTableMap fa ファ
EskkTableMap fe フェ
EskkTableMap fi フィ
EskkTableMap fo フォ
EskkTableMap fu フ
EskkTableMap fya フャ
EskkTableMap fye フェ
EskkTableMap fyi フィ
EskkTableMap fyo フョ
EskkTableMap fyu フュ
EskkTableMap -rest=g gg ッ
EskkTableMap ga ガ
EskkTableMap ge ゲ
EskkTableMap gi ギ
EskkTableMap go ゴ
EskkTableMap gu グ
EskkTableMap gya ギャ
EskkTableMap gye ギェ
EskkTableMap gyi ギィ
EskkTableMap gyo ギョ
EskkTableMap gyu ギュ
EskkTableMap ha ハ
EskkTableMap he ヘ
EskkTableMap hi ヒ
EskkTableMap ho ホ
EskkTableMap hu フ
EskkTableMap hya ヒャ
EskkTableMap hye ヒェ
EskkTableMap hyi ヒィ
EskkTableMap hyo ヒョ
EskkTableMap hyu ヒュ
EskkTableMap i イ
EskkTableMap -rest=j jj ッ
EskkTableMap ja ジャ
EskkTableMap je ジェ
EskkTableMap ji ジ
EskkTableMap jo ジョ
EskkTableMap ju ジュ
EskkTableMap jya ジャ
EskkTableMap jye ジェ
EskkTableMap jyi ジィ
EskkTableMap jyo ジョ
EskkTableMap jyu ジュ
EskkTableMap -rest=k kk ッ
EskkTableMap ka カ
EskkTableMap ke ケ
EskkTableMap ki キ
EskkTableMap ko コ
EskkTableMap ku ク
EskkTableMap kya キャ
EskkTableMap kye キェ
EskkTableMap kyi キィ
EskkTableMap kyo キョ
EskkTableMap kyu キュ
EskkTableMap ma マ
EskkTableMap me メ
EskkTableMap mi ミ
EskkTableMap mo モ
EskkTableMap mu ム
EskkTableMap mya ミャ
EskkTableMap mye ミェ
EskkTableMap myi ミィ
EskkTableMap myo ミョ
EskkTableMap myu ミュ
EskkTableMap n ン
EskkTableMap n' ン
EskkTableMap na ナ
EskkTableMap ne ネ
EskkTableMap ni ニ
EskkTableMap nn ン
EskkTableMap no ノ
EskkTableMap nu ヌ
EskkTableMap nya ニャ
EskkTableMap nye ニェ
EskkTableMap nyi ニィ
EskkTableMap nyo ニョ
EskkTableMap nyu ニュ
EskkTableMap o オ
EskkTableMap -rest=p pp ッ
EskkTableMap pa パ
EskkTableMap pe ペ
EskkTableMap pi ピ
EskkTableMap po ポ
EskkTableMap pu プ
EskkTableMap pya ピャ
EskkTableMap pye ピェ
EskkTableMap pyi ピィ
EskkTableMap pyo ピョ
EskkTableMap pyu ピュ
EskkTableMap -rest=r rr ッ
EskkTableMap ra ラ
EskkTableMap re レ
EskkTableMap ri リ
EskkTableMap ro ロ
EskkTableMap ru ル
EskkTableMap rya リャ
EskkTableMap rye リェ
EskkTableMap ryi リィ
EskkTableMap ryo リョ
EskkTableMap ryu リュ
EskkTableMap -rest=s ss ッ
EskkTableMap sa サ
EskkTableMap se セ
EskkTableMap sha シャ
EskkTableMap she シェ
EskkTableMap shi シ
EskkTableMap sho ショ
EskkTableMap shu シュ
EskkTableMap si シ
EskkTableMap so ソ
EskkTableMap su ス
EskkTableMap sya シャ
EskkTableMap sye シェ
EskkTableMap syi シィ
EskkTableMap syo ショ
EskkTableMap syu シュ
EskkTableMap -rest=t tt ッ
EskkTableMap ta タ
EskkTableMap te テ
EskkTableMap tha テァ
EskkTableMap the テェ
EskkTableMap thi ティ
EskkTableMap tho テョ
EskkTableMap thu テュ
EskkTableMap ti チ
EskkTableMap to ト
EskkTableMap tsu ツ
EskkTableMap tu ツ
EskkTableMap tya チャ
EskkTableMap tye チェ
EskkTableMap tyi チィ
EskkTableMap tyo チョ
EskkTableMap tyu チュ
EskkTableMap u ウ
EskkTableMap -rest=v vv ッ
EskkTableMap va ヴァ
EskkTableMap ve ヴェ
EskkTableMap vi ヴィ
EskkTableMap vo ヴォ
EskkTableMap vu ヴ
EskkTableMap -rest=w ww ッ
EskkTableMap wa ワ
EskkTableMap we ウェ
EskkTableMap wi ウィ
EskkTableMap wo ヲ
EskkTableMap wu ウ
EskkTableMap -rest=x xx ッ
EskkTableMap xa ァ
EskkTableMap xe ェ
EskkTableMap xi ィ
EskkTableMap xka ヵ
EskkTableMap xke ヶ
EskkTableMap xo ォ
EskkTableMap xtsu ッ
EskkTableMap xtu ッ
EskkTableMap xu ゥ
EskkTableMap xwa ヮ
EskkTableMap xwe ヱ
EskkTableMap xwi ヰ
EskkTableMap xya ャ
EskkTableMap xyo ョ
EskkTableMap xyu ュ
EskkTableMap -rest=y yy ッ
EskkTableMap ya ヤ
EskkTableMap ye イェ
EskkTableMap yo ヨ
EskkTableMap yu ユ
EskkTableMap -rest=z zz ッ
EskkTableMap z, ‥
EskkTableMap z- ～
EskkTableMap z. …
EskkTableMap z/ ・
EskkTableMap z[ 『
EskkTableMap z] 』
EskkTableMap za ザ
EskkTableMap ze ゼ
EskkTableMap zh ←
EskkTableMap zi ジ
EskkTableMap zj ↓
EskkTableMap zk ↑
EskkTableMap zl →
EskkTableMap zo ゾ
EskkTableMap zu ズ
EskkTableMap zya ジャ
EskkTableMap zye ジェ
EskkTableMap zyi ジィ
EskkTableMap zyo ジョ
EskkTableMap zyu ジュ
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

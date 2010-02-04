" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! skk7#table#rom_to_kata#get_definition()
    return g:skk7#table#rom_to_kata#definition
endfunc


call skk7#table#define_macro()

Skk7Table rom_to_kata

Skk7TableMap a ア
Skk7TableMap -rest=b bb ッ
Skk7TableMap ba バ
Skk7TableMap be ベ
Skk7TableMap bi ビ
Skk7TableMap bo ボ
Skk7TableMap bu ブ
Skk7TableMap bya ビャ
Skk7TableMap bye ビェ
Skk7TableMap byi ビィ
Skk7TableMap byo ビョ
Skk7TableMap byu ビュ
Skk7TableMap -rest=c cc ッ
Skk7TableMap cha チャ
Skk7TableMap che チェ
Skk7TableMap chi チ
Skk7TableMap cho チョ
Skk7TableMap chu チュ
Skk7TableMap cya チャ
Skk7TableMap cye チェ
Skk7TableMap cyi チィ
Skk7TableMap cyo チョ
Skk7TableMap cyu チュ
Skk7TableMap -rest=d dd ッ
Skk7TableMap da ダ
Skk7TableMap de デ
Skk7TableMap dha デャ
Skk7TableMap dhe デェ
Skk7TableMap dhi ディ
Skk7TableMap dho デョ
Skk7TableMap dhu デュ
Skk7TableMap di ヂ
Skk7TableMap do ド
Skk7TableMap du ヅ
Skk7TableMap dya ヂャ
Skk7TableMap dye ヂェ
Skk7TableMap dyi ヂィ
Skk7TableMap dyo ヂョ
Skk7TableMap dyu ヂュ
Skk7TableMap e エ
Skk7TableMap -rest=f ff ッ
Skk7TableMap fa ファ
Skk7TableMap fe フェ
Skk7TableMap fi フィ
Skk7TableMap fo フォ
Skk7TableMap fu フ
Skk7TableMap fya フャ
Skk7TableMap fye フェ
Skk7TableMap fyi フィ
Skk7TableMap fyo フョ
Skk7TableMap fyu フュ
Skk7TableMap -rest=g gg ッ
Skk7TableMap ga ガ
Skk7TableMap ge ゲ
Skk7TableMap gi ギ
Skk7TableMap go ゴ
Skk7TableMap gu グ
Skk7TableMap gya ギャ
Skk7TableMap gye ギェ
Skk7TableMap gyi ギィ
Skk7TableMap gyo ギョ
Skk7TableMap gyu ギュ
Skk7TableMap ha ハ
Skk7TableMap he ヘ
Skk7TableMap hi ヒ
Skk7TableMap ho ホ
Skk7TableMap hu フ
Skk7TableMap hya ヒャ
Skk7TableMap hye ヒェ
Skk7TableMap hyi ヒィ
Skk7TableMap hyo ヒョ
Skk7TableMap hyu ヒュ
Skk7TableMap i イ
Skk7TableMap -rest=j jj ッ
Skk7TableMap ja ジャ
Skk7TableMap je ジェ
Skk7TableMap ji ジ
Skk7TableMap jo ジョ
Skk7TableMap ju ジュ
Skk7TableMap jya ジャ
Skk7TableMap jye ジェ
Skk7TableMap jyi ジィ
Skk7TableMap jyo ジョ
Skk7TableMap jyu ジュ
Skk7TableMap -rest=k kk ッ
Skk7TableMap ka カ
Skk7TableMap ke ケ
Skk7TableMap ki キ
Skk7TableMap ko コ
Skk7TableMap ku ク
Skk7TableMap kya キャ
Skk7TableMap kye キェ
Skk7TableMap kyi キィ
Skk7TableMap kyo キョ
Skk7TableMap kyu キュ
Skk7TableMap ma マ
Skk7TableMap me メ
Skk7TableMap mi ミ
Skk7TableMap mo モ
Skk7TableMap mu ム
Skk7TableMap mya ミャ
Skk7TableMap mye ミェ
Skk7TableMap myi ミィ
Skk7TableMap myo ミョ
Skk7TableMap myu ミュ
Skk7TableMap n ン
Skk7TableMap n' ン
Skk7TableMap na ナ
Skk7TableMap ne ネ
Skk7TableMap ni ニ
Skk7TableMap nn ン
Skk7TableMap no ノ
Skk7TableMap nu ヌ
Skk7TableMap nya ニャ
Skk7TableMap nye ニェ
Skk7TableMap nyi ニィ
Skk7TableMap nyo ニョ
Skk7TableMap nyu ニュ
Skk7TableMap o オ
Skk7TableMap -rest=p pp ッ
Skk7TableMap pa パ
Skk7TableMap pe ペ
Skk7TableMap pi ピ
Skk7TableMap po ポ
Skk7TableMap pu プ
Skk7TableMap pya ピャ
Skk7TableMap pye ピェ
Skk7TableMap pyi ピィ
Skk7TableMap pyo ピョ
Skk7TableMap pyu ピュ
Skk7TableMap -rest=r rr ッ
Skk7TableMap ra ラ
Skk7TableMap re レ
Skk7TableMap ri リ
Skk7TableMap ro ロ
Skk7TableMap ru ル
Skk7TableMap rya リャ
Skk7TableMap rye リェ
Skk7TableMap ryi リィ
Skk7TableMap ryo リョ
Skk7TableMap ryu リュ
Skk7TableMap -rest=s ss ッ
Skk7TableMap sa サ
Skk7TableMap se セ
Skk7TableMap sha シャ
Skk7TableMap she シェ
Skk7TableMap shi シ
Skk7TableMap sho ショ
Skk7TableMap shu シュ
Skk7TableMap si シ
Skk7TableMap so ソ
Skk7TableMap su ス
Skk7TableMap sya シャ
Skk7TableMap sye シェ
Skk7TableMap syi シィ
Skk7TableMap syo ショ
Skk7TableMap syu シュ
Skk7TableMap -rest=t tt ッ
Skk7TableMap ta タ
Skk7TableMap te テ
Skk7TableMap tha テァ
Skk7TableMap the テェ
Skk7TableMap thi ティ
Skk7TableMap tho テョ
Skk7TableMap thu テュ
Skk7TableMap ti チ
Skk7TableMap to ト
Skk7TableMap tsu ツ
Skk7TableMap tu ツ
Skk7TableMap tya チャ
Skk7TableMap tye チェ
Skk7TableMap tyi チィ
Skk7TableMap tyo チョ
Skk7TableMap tyu チュ
Skk7TableMap u ウ
Skk7TableMap -rest=v vv ッ
Skk7TableMap va ヴァ
Skk7TableMap ve ヴェ
Skk7TableMap vi ヴィ
Skk7TableMap vo ヴォ
Skk7TableMap vu ヴ
Skk7TableMap -rest=w ww ッ
Skk7TableMap wa ワ
Skk7TableMap we ウェ
Skk7TableMap wi ウィ
Skk7TableMap wo ヲ
Skk7TableMap wu ウ
Skk7TableMap -rest=x xx ッ
Skk7TableMap xa ァ
Skk7TableMap xe ェ
Skk7TableMap xi ィ
Skk7TableMap xka ヵ
Skk7TableMap xke ヶ
Skk7TableMap xo ォ
Skk7TableMap xtsu ッ
Skk7TableMap xtu ッ
Skk7TableMap xu ゥ
Skk7TableMap xwa ヮ
Skk7TableMap xwe ヱ
Skk7TableMap xwi ヰ
Skk7TableMap xya ャ
Skk7TableMap xyo ョ
Skk7TableMap xyu ュ
Skk7TableMap -rest=y yy ッ
Skk7TableMap ya ヤ
Skk7TableMap ye イェ
Skk7TableMap yo ヨ
Skk7TableMap yu ユ
Skk7TableMap -rest=z zz ッ
Skk7TableMap z, ‥
Skk7TableMap z- ～
Skk7TableMap z. …
Skk7TableMap z/ ・
Skk7TableMap z[ 『
Skk7TableMap z] 』
Skk7TableMap za ザ
Skk7TableMap ze ゼ
Skk7TableMap zh ←
Skk7TableMap zi ジ
Skk7TableMap zj ↓
Skk7TableMap zk ↑
Skk7TableMap zl →
Skk7TableMap zo ゾ
Skk7TableMap zu ズ
Skk7TableMap zya ジャ
Skk7TableMap zye ジェ
Skk7TableMap zyi ジィ
Skk7TableMap zyo ジョ
Skk7TableMap zyu ジュ
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

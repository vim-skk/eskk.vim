" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call skk7#test#is(skk7#util#mb_strlen('あいうえお'), 5)
    call skk7#test#is(skk7#util#mb_strlen(''), 0)
    call skk7#test#is(skk7#util#mb_strlen('あ'), 1)
    call skk7#test#is(skk7#util#mb_strlen('あa'), 2)
    call skk7#test#is(skk7#util#mb_strlen('aあ'), 2)
    call skk7#test#is(skk7#util#mb_strlen('aあb'), 3)

    call skk7#test#is(skk7#util#mb_chop('あいうえお'), 'あいうえ')
    call skk7#test#is(skk7#util#mb_chop(''), '')
endfunc


Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}


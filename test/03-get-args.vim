" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call skk7#test#is(
    \   skk7#util#get_args([1, 2], 1, 2, 3, 4),
    \   [1,2,3,4]
    \)
    call skk7#test#is(
    \   skk7#util#get_args([1, 2], 1, 3),
    \   [1,2]
    \)
    call skk7#test#is(
    \   skk7#util#get_args([1, 2], 1),
    \   [1]
    \)
    call skk7#test#is(
    \   skk7#util#get_args([[1], [2]], [1]),
    \   [[1]]
    \)
endfunc

Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}


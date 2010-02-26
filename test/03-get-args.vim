" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call simpletap#is(
    \   eskk#util#get_args([1, 2], 1, 2, 3, 4),
    \   [1,2,3,4]
    \)
    call simpletap#is(
    \   eskk#util#get_args([1, 2], 1, 3),
    \   [1,2]
    \)
    call simpletap#is(
    \   eskk#util#get_args([1, 2], 1),
    \   [1]
    \)
    call simpletap#is(
    \   eskk#util#get_args([[1], [2]], [1]),
    \   [[1]]
    \)
endfunc

TestBegin
call s:run()
TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}


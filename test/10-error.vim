" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! s:run()
    call skk7#test#raise_ok(
    \   "throw skk7#error#internal_error('skk7:')",
    \   '^skk7: internal error$'
    \)
    call skk7#test#raise_ok(
    \   "throw skk7#error#internal_error('skk7: foo:')",
    \   '^skk7: foo: internal error$'
    \)
    call skk7#test#raise_ok(
    \   "throw skk7#error#out_of_idx('skk7:')",
    \   '^skk7: out of index$'
    \)
    call skk7#test#raise_ok(
    \   "throw skk7#error#out_of_idx('skk7: foo:')",
    \   '^skk7: foo: out of index$'
    \)
endfunc


Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}



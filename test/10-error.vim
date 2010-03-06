" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! s:run()
    call simpletap#throws_ok(
    \   "throw eskk#error#internal_error('eskk:')",
    \   '^eskk: internal error$'
    \)
    call simpletap#throws_ok(
    \   "throw eskk#error#internal_error('eskk: foo:')",
    \   '^eskk: foo: internal error$'
    \)
    call simpletap#throws_ok(
    \   "throw eskk#error#out_of_idx('eskk:')",
    \   '^eskk: out of index$'
    \)
    call simpletap#throws_ok(
    \   "throw eskk#error#out_of_idx('eskk: foo:')",
    \   '^eskk: foo: out of index$'
    \)
endfunc


call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

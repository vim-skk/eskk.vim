" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:run()
    call simpletap#throws_ok(
    \   "throw eskk#internal_error(['eskk'])",
    \   '^eskk: internal error at autoload/eskk\.vim$'
    \)
    call simpletap#throws_ok(
    \   "throw eskk#internal_error(['eskk', 'foo'])",
    \   '^eskk: internal error at autoload/eskk/foo\.vim$'
    \)
endfunction


call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

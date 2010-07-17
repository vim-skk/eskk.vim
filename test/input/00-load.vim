" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    call eskk#enable()
    OK eskk#is_enabled()
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

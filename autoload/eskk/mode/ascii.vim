" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Variables {{{

let eskk#mode#ascii#handle_all_keys = 1

" }}}

" Functions {{{

" Filter functions

func! eskk#mode#ascii#filter_main(char, from, ...) "{{{
    return a:char
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Variables {{{

let skk7#mode#ascii#handle_all_keys = 1

" }}}

" Functions {{{

" Filter functions

func! skk7#mode#ascii#filter_main(char, from, ...) "{{{
    return a:char
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

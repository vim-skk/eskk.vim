" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Functions {{{

" This function will be called from autoload/skk7.vim.
func! skk7#mode#ascii#initialize() "{{{
endfunc "}}}



" Filter functions

func! skk7#mode#ascii#filter_main(char, ...) "{{{
    return a:char
endfunc "}}}



" Callbacks

func! skk7#mode#ascii#cb_now_working(char, ...) "{{{
    return 1
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

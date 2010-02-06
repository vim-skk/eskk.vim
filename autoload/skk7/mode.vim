" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Scope Variables {{{
let s:debug_errmsg = []
" }}}
" Global Variables {{{
if !exists('g:mode_debug')
    let g:mode_debug = 0
endif
" }}}

" Functions {{{

func! skk7#mode#cb_no_filter() "{{{
    let fmt = "skk7: mode: no filter function '%s'."
    call skk7#util#warnf(fmt, skk7#current_filter())
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

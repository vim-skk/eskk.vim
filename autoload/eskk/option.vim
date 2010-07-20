" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if exists('s:loaded') && s:loaded
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Functions {{{

let s:options = {
\   'debug': {'value': 0},
\   'debug_wait_ms': {'value': 0},
\
\   'dictionary': {'value': {}},
\}

function! eskk#option#load() "{{{
endfunction "}}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

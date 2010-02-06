" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Variables {{{

let skk7#mode#hira#handle_all_keys = 1

" }}}

" Functions {{{

" Each mode must have 'load()' function
" to check if its mode exists.
func! skk7#mode#hira#load() "{{{
endfunc "}}}

" This function will be called from autoload/skk7.vim.
func! skk7#mode#ascii#initialize() "{{{
endfunc "}}}

func! skk7#mode#ascii#enable(again) "{{{
    if !a:again
        return skk7#dispatch_key('', skk7#from_mode('ascii'))
    else
        call skk7#mode#ascii#initialize()
        return ''
    endif
endfunc "}}}



" Filter functions

func! skk7#mode#ascii#filter_main(char, from, ...) "{{{
    return a:char
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

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


" Functions {{{

func! skk7#table#define_macro()
    command! -nargs=+ Skk7Map call s:skk7_map(<f-args>)
endfunc

func! s:skk7_map(...)
    " TODO Parse arguments.
endfunc

func! skk7#table#map(modes, options, remap_p, lhs, rhs)
    " TODO
endfunc

func! skk7#table#unmap(modes, options, lhs)
    " TODO
endfunc


" TODO
" Current implementation is smart but heavy.
" Make table like this?
" 's': {
"   'a': {'kana': 'さ'},
"
"   .
"   .
"   .
"
"   'y': {'a': {'kana': 'しゃ'}}
" }
" But this uses a lot of memory.
"
func! skk7#table#has_candidates(definition, str)
    let regex = '^' . a:str
    return !empty(filter(keys(a:definition), 'v:val =~# regex'))
endfunc

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See s:initialize_once() for Variables.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Functions {{{
func! eskk#error#internal_error(from, ...) "{{{
    if a:0 == 0
        return join([a:from, 'internal error'], ' ')
    else
        return join([a:from, 'internal error:', a:1], ' ')
    endif
endfunc "}}}

func! eskk#error#out_of_idx(from, ...) "{{{
    if a:0 == 0
        return join([a:from, 'out of index'], ' ')
    else
        return join([a:from, 'out of index:', a:1], ' ')
    endif
endfunc "}}}
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

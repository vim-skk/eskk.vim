" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See s:initialize_once() for Variables.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Functions {{{
func! s:make_error(what, from, ...) "{{{
    if a:0 == 0
        return join([a:from, a:what], ' ')
    else
        return join([a:from, a:what . ':', a:1], ' ')
    endif
endfunc "}}}


func! eskk#error#internal_error(...) "{{{
    return call('s:make_error', ['internal error'] + a:000)
endfunc "}}}

func! eskk#error#out_of_idx(from, ...) "{{{
    return call('s:make_error', ['out of index'] + a:000)
endfunc "}}}

func! eskk#error#not_implemented(from, ...) "{{{
    return call('s:make_error', ['not implemented'] + a:000)
endfunc "}}}
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

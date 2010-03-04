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


func! eskk#error#internal_error(from, ...) "{{{
    return call('s:make_error', ['internal error', a:from] + a:000)
endfunc "}}}

func! eskk#error#out_of_idx(from, ...) "{{{
    return call('s:make_error', ['out of index', a:from] + a:000)
endfunc "}}}

func! eskk#error#not_implemented(from, ...) "{{{
    return call('s:make_error', ['not implemented', a:from] + a:000)
endfunc "}}}

func! eskk#error#never_reached(from, ...) "{{{
    return call('s:make_error', ['this block will be never reached', a:from] + a:000)
endfunc "}}}

func! eskk#error#map_parse_error(from, ...) "{{{
    return call('s:make_error', [':map parse error', a:from] + a:000)
endfunc "}}}

" This is only used from eskk#util#assert().
func! eskk#error#assertion_failure(from, ...) "{{{
    return call('s:make_error', ['assertion failed', a:from] + a:000)
endfunc "}}}
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

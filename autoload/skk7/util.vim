" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Functions {{{

func! skk7#util#warn(msg) "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunc "}}}

func! skk7#util#warnf(msg, ...) "{{{
    call skk7#util#warn(call('printf', [a:msg] + a:000))
endfunc

func! skk7#util#log(...) "{{{
    if g:skk7_debug
        return call('skk7#debug#log', a:000)
    endif
endfunc "}}}

func! skk7#util#logf(...) "{{{
    if g:skk7_debug
        return call('skk7#debug#logf', a:000)
    endif
endfunc "}}}

func! skk7#util#internal_error(...) "{{{
    if a:0 == 0
        call skk7#util#warn('skk7: util: sorry, internal error.')
    else
        call skk7#util#warn('skk7: util: sorry, internal error: ' . a:1)
    endif
endfunc "}}}

func! skk7#util#mb_strlen(str) "{{{
    return strlen(substitute(copy(a:str), '.', 'x', 'g'))
endfunc "}}}

" }}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

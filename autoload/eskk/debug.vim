" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! eskk#debug#log(msg) "{{{
    redraw

    if exists('g:eskk_debug_file')
        call writefile([a:msg], expand(g:eskk_debug_file))
    else
        call eskk#util#warn(a:msg)
    endif

    if g:eskk_debug_wait_ms !=# 0
        execute printf('sleep %dm', g:eskk_debug_wait_ms)
    endif
endfunction "}}}

function! eskk#debug#logf(msg, ...) "{{{
    call eskk#debug#log(call('printf', [a:msg] + a:000))
endfunction "}}}

" :EskkDebugList {{{
command! -nargs=? EskkDebugList
\   call eskk#debug#list(<f-args>)
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

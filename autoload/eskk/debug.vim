" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:debug_msg_list = []

func! eskk#debug#log(msg) "{{{
    redraw
    call add(s:debug_msg_list, a:msg)
    call eskk#util#warn(a:msg)
    if g:eskk_debug_wait_ms !=# 0
        execute printf('sleep %dm', g:eskk_debug_wait_ms)
    endif
endfunc "}}}

func! eskk#debug#logf(msg, ...) "{{{
    call eskk#debug#log(call('printf', [a:msg] + a:000))
endfunc "}}}

func! eskk#debug#list(...) "{{{
    let cmd = a:0 != 0 ? a:1 : 'echo'
    for msg in s:debug_msg_list
        execute cmd string(msg)
    endfor
endfunc "}}}

" :EskkDebugList {{{
command! -nargs=? EskkDebugList
\   call eskk#debug#list(<f-args>)
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

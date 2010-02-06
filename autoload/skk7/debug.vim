" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:debug_msg_list = []

func! skk7#debug#log(msg) "{{{
    redraw
    call add(s:debug_msg_list, a:msg)
    call skk7#util#warn(a:msg)
    if g:skk7_debug_wait_ms !=# 0
        execute printf('sleep %dm', g:skk7_debug_wait_ms)
    endif
endfunc "}}}

func! skk7#debug#logf(msg, ...) "{{{
    call skk7#debug#log(call('printf', [a:msg] + a:000))
endfunc "}}}

func! skk7#debug#list(...) "{{{
    let cmd = a:0 != 0 ? a:1 : 'echo'
    for msg in s:debug_msg_list
        execute cmd string(msg)
    endfor
endfunc "}}}

" :Skk7DebugList {{{
command! -nargs=? Skk7DebugList
\   call skk7#debug#list(<f-args>)
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

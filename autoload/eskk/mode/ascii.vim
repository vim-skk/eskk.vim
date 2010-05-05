" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Callback
function! eskk#mode#ascii#cb_handle_key(stash) "{{{
    let c = a:stash.char
    return c =~# '^[a-zA-Z0-9]$'
    \   || c =~# '^[\-^\\!"#$%&''()=~|]$'
    \   || c =~# '^[@\[;:\],./`{+*}<>?_]$'
endfunction "}}}


function! eskk#mode#ascii#hook_fn_do_lmap() "{{{
    lmap <buffer> <C-j> <Plug>(eskk:mode:ascii:to-hira)
endfunction "}}}


" Filter function
function! eskk#mode#ascii#filter(stash) "{{{
    return eskk#default_filter(a:stash)
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

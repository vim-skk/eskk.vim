" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Callback
function! eskk#mode#ascii#cb_handle_key(key_info, ...) "{{{
    let c = a:key_info.char
    return c =~# '^[a-zA-Z0-9]$'
    \   || c =~# '^[\-^\\!"#$%&''()=~|]$'
    \   || c =~# '^[@\[;:\],./`{+*}<>?_]$'
endfunction "}}}

" Filter function
function! eskk#mode#ascii#filter(key_info, opt, ...) "{{{
    let a:opt.return = a:key_info.char
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

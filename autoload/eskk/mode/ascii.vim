" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables {{{
let s:rom_to_ascii  = {}
let s:rom_to_zenei  = eskk#table#new('rom_to_zenei')
let s:current_table = s:rom_to_ascii
" }}}


" Callback
function! eskk#mode#ascii#cb_handle_key(stash) "{{{
    let c = a:stash.char
    return c =~# '^[a-zA-Z0-9]$'
    \   || c =~# '^[\-^\\!"#$%&''()=~|]$'
    \   || c =~# '^[@\[;:\],./`{+*}<>?_]$'
endfunction "}}}


function! eskk#mode#ascii#hook_fn_do_lmap_ascii() "{{{
    lmap <buffer> <C-j> <Plug>(eskk:mode:ascii:to-hira)
endfunction "}}}
function! eskk#mode#ascii#hook_fn_do_lmap_zenei() "{{{
    lmap <buffer> <C-j> <Plug>(eskk:mode:zenei:to-hira)
endfunction "}}}
function! eskk#mode#ascii#set_rom_to_ascii_table() "{{{
    let s:current_table = s:rom_to_ascii
endfunction "}}}
function! eskk#mode#ascii#set_rom_to_zenei_table() "{{{
    let s:current_table = s:rom_to_zenei
endfunction "}}}


" Filter function
function! eskk#mode#ascii#filter(stash) "{{{
    if s:current_table is s:rom_to_ascii
        call eskk#default_filter(a:stash)
    else
        let c = a:stash.char
        if s:current_table.has_map(c)
            let a:stash.option.return = s:current_table.get_map_to(c)
        else
            call eskk#default_filter(a:stash)
        endif
    endif
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

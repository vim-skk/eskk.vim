" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'doc/eskk.txt'.

" Load Once {{{
if exists('g:loaded_eskk') && g:loaded_eskk
    finish
endif
let g:loaded_eskk = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Mappings {{{

noremap! <expr> <Plug>(eskk:enable)     eskk#enable()
lnoremap <expr> <Plug>(eskk:enable)     eskk#enable()

noremap! <expr> <Plug>(eskk:disable)    eskk#disable()
lnoremap <expr> <Plug>(eskk:disable)    eskk#disable()

noremap! <expr> <Plug>(eskk:toggle)     eskk#toggle()
lnoremap <expr> <Plug>(eskk:toggle)     eskk#toggle()

nnoremap        <Plug>(eskk:save-dictionary) :<C-u>EskkUpdateDictionary<CR>


" Global variables
if !exists('g:eskk#no_default_mappings')
    let g:eskk#no_default_mappings = 0
endif
if !exists('g:eskk#dont_map_default_if_already_mapped')
    let g:eskk#dont_map_default_if_already_mapped = 1
endif


if !g:eskk#no_default_mappings
    function! s:hasmapto(rhs, mode)
        let map_default_even_if_already_mapped = !g:eskk#dont_map_default_if_already_mapped
        return
        \   map_default_even_if_already_mapped
        \   || !hasmapto(a:rhs, a:mode)
    endfunction

    if s:hasmapto('<Plug>(eskk:toggle)', 'i')
        silent! imap <unique> <C-j>   <Plug>(eskk:toggle)
    endif
    if s:hasmapto('<Plug>(eskk:toggle)', 'c')
        silent! cmap <unique> <C-j>   <Plug>(eskk:toggle)
    endif
    if s:hasmapto('<Plug>(eskk:toggle)', 'l')
        silent! lmap <unique> <C-j>   <Plug>(eskk:toggle)
    endif

    delfunc s:hasmapto
endif

" }}}

" Commands {{{
call eskk#commands#define()
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.


runtime! plugin/eskk.vim

" Load Once {{{
if exists('g:loaded_eskk_builtin_mode') && g:loaded_eskk_builtin_mode
    finish
endif
let g:loaded_eskk_builtin_mode = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Register builtin-modes. {{{

" 'ascii' mode {{{
if !exists('g:eskk_mode_ascii_no_default_mappings')
    let g:eskk_mode_ascii_no_default_mappings = 0
endif

lnoremap <expr> <Plug>(eskk:mode:ascii:to-hira) [eskk#set_mode('hira'), ''][1]
noremap! <expr> <Plug>(eskk:mode:ascii:to-hira) [eskk#set_mode('hira'), ''][1]


call eskk#register_mode('ascii')
let s:dict = eskk#get_mode_structure('ascii')

if !g:eskk_mode_ascii_no_default_mappings
    call add(s:dict.hook_fn, 'eskk#mode#ascii#hook_fn_do_lmap')
endif

unlet s:dict
" }}}

" 'hira' mode {{{
if !exists('g:eskk_mode_hira_no_default_mappings')
    let g:eskk_mode_hira_no_default_mappings = 0
endif

lnoremap <expr> <Plug>(eskk:mode:hira:to-kata) [eskk#set_mode('kata'), ''][1]
noremap! <expr> <Plug>(eskk:mode:hira:to-kata) [eskk#set_mode('kata'), ''][1]

lnoremap <expr> <Plug>(eskk:mode:hira:to-ascii) [eskk#set_mode('ascii'), ''][1]
noremap! <expr> <Plug>(eskk:mode:hira:to-ascii) [eskk#set_mode('ascii'), ''][1]

lnoremap <expr> <Plug>(eskk:mode:hira:to-zenei) [eskk#set_mode('zenei'), ''][1]
noremap! <expr> <Plug>(eskk:mode:hira:to-zenei) [eskk#set_mode('zenei'), ''][1]


call eskk#register_mode('hira')
let s:dict = eskk#get_mode_structure('hira')

if !g:eskk_mode_hira_no_default_mappings
    call add(s:dict.hook_fn, 'eskk#mode#hira#hook_fn_do_lmap')
endif

unlet s:dict
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

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

function! s:dict.filter(...)
    return call('eskk#mode#ascii#filter', a:000)
endfunction
function! s:dict.cb_handle_key(...)
    return call('eskk#mode#ascii#cb_handle_key', a:000)
endfunction


if !g:eskk_mode_ascii_no_default_mappings
    call eskk#register_event('enter-mode-ascii', 'eskk#mode#ascii#hook_fn_do_lmap_ascii', [])
endif
call eskk#register_event('enter-mode-ascii', 'eskk#mode#ascii#set_rom_to_ascii_table', [])

unlet s:dict
call eskk#validate_mode_structure('ascii')
" }}}

" 'zenei' mode {{{
if !exists('g:eskk_mode_zenei_no_default_mappings')
    let g:eskk_mode_zenei_no_default_mappings = 0
endif

lnoremap <expr> <Plug>(eskk:mode:zenei:to-hira) [eskk#set_mode('hira'), ''][1]
noremap! <expr> <Plug>(eskk:mode:zenei:to-hira) [eskk#set_mode('hira'), ''][1]


call eskk#register_mode('zenei')
let s:dict = eskk#get_mode_structure('zenei')

function! s:dict.filter(...)
    return call('eskk#mode#ascii#filter', a:000)
endfunction
function! s:dict.cb_handle_key(...)
    return call('eskk#mode#ascii#cb_handle_key', a:000)
endfunction


if !g:eskk_mode_zenei_no_default_mappings
    call eskk#register_event('enter-mode-zenei', 'eskk#mode#ascii#hook_fn_do_lmap_zenei', [])
endif
call eskk#register_event('enter-mode-zenei', 'eskk#mode#ascii#set_rom_to_zenei_table', [])

unlet s:dict
call eskk#validate_mode_structure('zenei')
" }}}

" 'hira' mode {{{
if !exists('g:eskk_mode_hira_no_default_mappings')
    let g:eskk_mode_hira_no_default_mappings = 0
endif

lnoremap <expr> <Plug>(eskk:mode:hira:convert/switch-to-kata) eskk#call_via_filter('eskk#mode#hira#do_q_key', [])
noremap! <expr> <Plug>(eskk:mode:hira:convert/switch-to-kata) eskk#call_via_filter('eskk#mode#hira#do_q_key', [])

lnoremap <expr> <Plug>(eskk:mode:hira:to-ascii) [eskk#set_mode('ascii'), ''][1]
noremap! <expr> <Plug>(eskk:mode:hira:to-ascii) [eskk#set_mode('ascii'), ''][1]

lnoremap <expr> <Plug>(eskk:mode:hira:to-zenei) [eskk#set_mode('zenei'), ''][1]
noremap! <expr> <Plug>(eskk:mode:hira:to-zenei) [eskk#set_mode('zenei'), ''][1]


call eskk#register_mode('hira')
let s:dict = eskk#get_mode_structure('hira')

function! s:dict.filter(...)
    return call('eskk#mode#hira#filter', a:000)
endfunction
function! s:dict.cb_handle_key(...)
    return call('eskk#mode#hira#cb_handle_key', a:000)
endfunction


if !g:eskk_mode_hira_no_default_mappings
    call eskk#register_event('enter-mode-hira', 'eskk#mode#hira#hook_fn_do_lmap_hira', [])
endif
call eskk#register_event('enter-mode-hira', 'eskk#mode#hira#set_rom_to_hira_table', [])

unlet s:dict
call eskk#validate_mode_structure('hira')
" }}}

" 'kata' mode {{{
if !exists('g:eskk_mode_kata_no_default_mappings')
    let g:eskk_mode_kata_no_default_mappings = 0
endif


call eskk#register_mode('kata')
let s:dict = eskk#get_mode_structure('kata')

function! s:dict.filter(...)
    return call('eskk#mode#hira#filter', a:000)
endfunction
function! s:dict.cb_handle_key(...)
    return call('eskk#mode#hira#cb_handle_key', a:000)
endfunction


if !g:eskk_mode_kata_no_default_mappings
    call eskk#register_event('enter-mode-kata', 'eskk#mode#hira#hook_fn_do_lmap_kata', [])
endif
call eskk#register_event('enter-mode-kata', 'eskk#mode#hira#set_rom_to_kata_table', [])

unlet s:dict
call eskk#validate_mode_structure('kata')
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

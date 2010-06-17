" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.


runtime! plugin/eskk.vim

" g:eskk_disable {{{
if g:eskk_disable
    finish
endif
" }}}
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
call eskk#register_mode('ascii')
let s:dict = eskk#get_mode_structure('ascii')

function! s:dict.filter(...)
    return call('eskk#mode#builtin#sym_filter', a:000)
endfunction


call eskk#register_event('enter-mode-ascii', 'eskk#mode#builtin#set_table', ['rom_to_ascii'])

unlet s:dict
call eskk#validate_mode_structure('ascii')
" }}}

" 'zenei' mode {{{
call eskk#register_mode('zenei')
let s:dict = eskk#get_mode_structure('zenei')

function! s:dict.filter(...)
    return call('eskk#mode#builtin#sym_filter', a:000)
endfunction


call eskk#register_event('enter-mode-zenei', 'eskk#mode#builtin#set_table', ['rom_to_zenei'])

unlet s:dict
call eskk#validate_mode_structure('zenei')
" }}}

" 'hira' mode {{{
call eskk#register_mode('hira')
let s:dict = eskk#get_mode_structure('hira')

function! s:dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000)
endfunction


call eskk#register_event('enter-mode-hira', 'eskk#mode#builtin#set_table', ['rom_to_hira'])

unlet s:dict
call eskk#validate_mode_structure('hira')
" }}}

" 'kata' mode {{{
call eskk#register_mode('kata')
let s:dict = eskk#get_mode_structure('kata')

function! s:dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000)
endfunction


call eskk#register_event('enter-mode-kata', 'eskk#mode#builtin#set_table', ['rom_to_kata'])

unlet s:dict
call eskk#validate_mode_structure('kata')
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

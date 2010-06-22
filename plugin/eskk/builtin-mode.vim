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
let dict = eskk#get_mode_structure('ascii')

function! dict.filter(...)
    return call('eskk#mode#builtin#sym_filter', a:000)
endfunction

call eskk#validate_mode_structure('ascii')


call eskk#register_event('enter-mode-ascii', 'eskk#mode#builtin#set_table', ['rom_to_ascii'])
" }}}

" 'zenei' mode {{{
call eskk#register_mode('zenei')
let dict = eskk#get_mode_structure('zenei')

function! dict.filter(...)
    return call('eskk#mode#builtin#sym_filter', a:000)
endfunction

call eskk#validate_mode_structure('zenei')


call eskk#register_event('enter-mode-zenei', 'eskk#mode#builtin#set_table', ['rom_to_zenei'])
" }}}

" 'hira' mode {{{
call eskk#register_mode('hira')
let dict = eskk#get_mode_structure('hira')

function! dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000)
endfunction

call eskk#validate_mode_structure('hira')


call eskk#register_event('enter-mode-hira', 'eskk#mode#builtin#set_table', ['rom_to_hira'])
" }}}

" 'kata' mode {{{
call eskk#register_mode('kata')
let dict = eskk#get_mode_structure('kata')

function! dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000)
endfunction

call eskk#validate_mode_structure('kata')


call eskk#register_event('enter-mode-kata', 'eskk#mode#builtin#set_table', ['rom_to_kata'])
" }}}

" 'hankata' mode {{{
call eskk#register_mode('hankata')
let dict = eskk#get_mode_structure('hankata')

function! dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000)
endfunction

call eskk#validate_mode_structure('hankata')


call eskk#register_event('enter-mode-hankata', 'eskk#mode#builtin#set_table', ['rom_to_hankata'])
" }}}

unlet dict

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Load Once {{{
if exists('g:loaded_eskk_mode_ascii') && g:loaded_eskk_mode_ascii
    finish
endif
let g:loaded_eskk_mode_ascii = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


call eskk#register_mode('ascii')

" Global variables {{{
if !exists('g:eskk_mode_ascii_no_default_mappings')
    let g:eskk_mode_ascii_no_default_mappings = 0
endif
" }}}

" Mappings {{{
if g:eskk_mode_ascii_no_default_mappings
    call eskk#map('<C-j>', '<Plug>(eskk-mode-to-hira)', 'ascii')
endif
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

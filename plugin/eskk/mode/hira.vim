" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.


runtime! plugin/eskk.vim

" Load Once {{{
if exists('g:loaded_eskk_mode_hira') && g:loaded_eskk_mode_hira
    finish
endif
let g:loaded_eskk_mode_hira = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


call eskk#register_mode('hira')

" Global variables {{{
if !exists('g:eskk_mode_hira_no_default_mappings')
    let g:eskk_mode_hira_no_default_mappings = 0
endif
" }}}
" Mappings {{{
if g:eskk_mode_hira_no_default_mappings
    call eskk#map('q', '<Plug>(eskk-mode-to-kata)', 'hira')
    call eskk#map('l', '<Plug>(eskk-mode-to-ascii)', 'hira')
    call eskk#map('L', '<Plug>(eskk-mode-to-zenei)', 'hira')
endif
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
